# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
require 'rubygems'
require 'zip/zipfilesystem'
require 'csv'
require "nokogiri"
class Admin::BatchController < ApplicationController
  include Admin::BatchHelper
  require_role ["admin", "supervisor", "manager", "TL", "partner", "client", "facility"]
  layout 'standard'
  in_place_edit_with_validation_for :batch, :priority


  # RAILS3.1 TODO
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #  :redirect_to => { :action => :list }

  def index
    conditions = unless params[:to_find].blank?
      frame_batch_criteria
    else
      "status != '#{BatchStatus::OUTPUT_READY}'"
    end
    @batches = Batch.select("batches.batchid as batchid \
                    , batches.status as status \
                    , batches.arrival_time as arrival_time \
                    , batches.target_time as target_time \
                    , batches.correspondence as correspondence \
                    , batches.comment as comment \
                    , batches.date as date \
                    , batches.id as id \
                    , facilities.name as facility_name \
                    , clients.name as facility_client_name \
                    , sum(jobs.estimated_eob) as tot_estimated_eobs").\
      where(conditions). \
      joins("LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id \
                LEFT OUTER JOIN clients ON clients.id = facilities.client_id \
                LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id"). \
      group("batches.id"). \
      paginate(:page => params[:page]) unless conditions.blank?
    
    # For AJAX requests, render the partial and disable the layout
    # render :partial => "batches_list", :layout => false if request.xml_http_request?

  end

  

  def batch_load
    #system('rake doc:app')
    load_batch = system("/opt/ruby-enterprise/bin/rake input:pema")
    if(load_batch == true)
      flash[:notice] = "Batch Loaded Successfully"
    else
      flash[:notice] = "Batch Not Loaded"
    end
    redirect_to :action => "allocate"
  end

  def allocate
    flash[:notice] = nil
    conditions = unless (params[:first_to_find].blank? && params[:second_to_find].blank?)
      btch_criteria_v2
    else
      "status in ('#{BatchStatus::NEW}','#{BatchStatus::PROCESSING}','#{BatchStatus::COMPLETED}')
      and jobs.is_excluded = 0"
    end
    
    @batches = Batch.select("batches.batchid as batchid \
                    , batches.status as status \
                    , batches.arrival_time as arrival_time \
                    , batches.target_time as target_time \
                    , batches.completion_time as completion_time \
                    , batches.comment as comment \
                    , batches.date as date \
                    , batches.id as id \
                    , batches.expected_completion_time as expected_completion_time \
                    , batches.tat_comment as tat_comment \
                    , facilities.name as facility_name \
                    , SUM(CASE WHEN (check_informations.payment_method = 'CHK' or \
                      check_informations.payment_method = 'OTH') THEN \
                      ((IFNULL(insurance_payment_eobs.total_amount_paid_for_claim,0)) - (IFNULL(insurance_payment_eobs.over_payment_recovery, 0))) +
                      CASE WHEN LOCATE('interest_in_service_line: false',facilities.details) THEN IFNULL(insurance_payment_eobs.claim_interest,0) \
                           WHEN LOCATE('interest_in_service_line: true',facilities.details) THEN 0 END + \
                      IFNULL(insurance_payment_eobs.late_filing_charge,0) + \
                      IFNULL(patient_pay_eobs.stub_amount,0) ELSE 0 END) as tot_amount_so_far \
                    , SUM(CASE WHEN jobs.job_status = 'REJECTED' THEN 1 ELSE 0 END) AS job_status_rejected \
                    , SUM(CASE WHEN jobs.job_status = 'NEW' THEN 1 ELSE 0 END) AS job_status_new \
                    , count(insurance_payment_eobs.id) + count(patient_pay_eobs.id) as tot_completed_eobs").\
      where(conditions). \
      joins("LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id \
                    LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id \
                    LEFT OUTER JOIN check_informations ON check_informations.job_id = jobs.id \
                    LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id \
                    LEFT OUTER JOIN patient_pay_eobs ON patient_pay_eobs.check_information_id = check_informations.id"). \
      group("batches.id"). \
      paginate(:page => params[:page], :per_page => 10) unless conditions.blank?

    batches_with_estimated_eob_count = Batch.select("batches.id as id, sum(jobs.estimated_eob) as tot_estimated_eobs ").\
      where(conditions). \
      joins("LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id
      INNER JOIN facilities ON facilities.id = batches.facility_id"). \
      group("batches.id"). \
      paginate(:page => params[:page], :per_page => 10) unless conditions.blank?
    
    @batches_with_estimated_eob_count = {}
    batches_with_estimated_eob_count.each do |batch|
      @batches_with_estimated_eob_count[batch.id] = batch
    end
  end

  def non_compliant
    conditions = "batches.status != '#{BatchStatus::COMPLETED}' and batches.expected_completion_time > batches.target_time"
    joins = "left outer join facilities on facility_id = facilities.id "
    conditions = frame_batch_criteria(conditions) unless params[:to_find].blank?
    
    batches = Batch.find(:all, :conditions => conditions,
      :joins => joins, :order => 'date DESC')
    
    unless batches.blank?
      @batch_pages, @batches = paginate_collection batches , 
        :per_page => 30 ,:page => params[:page]
    else
      unless params[:to_find].blank?
        flash[:notice] = " No record found for <i>#{params[:criteria]} #{params[:compare]} \"#{params[:to_find]}\"</i>"
      else
        flash[:notice] = "No non-compliant batches found. Redirecting to Payer wise Job Allocation view."
        redirect_to :action => "payer_list"
      end 
    end
  end
  
  def comments
    @editable_field = params[:editable_field]
    @redirect_window = params[:redirect_window]
    @batch = Batch.find(params[:id])
  end

  def show
    flash[:notice] = nil
    @batch = Batch.find(params[:id])
  end

  def new
    @batch = Batch.new
    @facilities =  Facility.find(:all).map{ |facility| facility.name}
    @payers = Payer.find(:all).map do |payer|
      payer.payer
    end
    @batch_status = batch_status_details
  end

  def create
    @payers = Payer.find(:all).map do |payer|
      payer.payer
    end
    @facilities = Facility.find(:all)
    @batch = Batch.new(params[:batch])
    facility = params[:form][:facility_name] unless params[:form].nil?
    payer = params[:form1][:payer_payer] unless params[:form1].nil?
    unless facility.nil?
      @batch.facility = Facility.find_by_name(facility)
      @batch.target_time = @batch.arrival_time + @batch.facility.tat.to_i.hours
      @batch.contracted_time = @batch.arrival_time + @batch.facility.client.contracted_tat.hours
    end
    unless payer.nil?
      @batch.payer = Payer.find_by_payer(payer)
    end
    @batch.status = BatchStatus::NEW

    if @batch.save
      flash[:notice] = 'Batch was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @facilities =  Facility.find(:all).map{ |facility| facility.name}
    @batch_status = batch_status_details
    @batch = Batch.find(params[:id])
    @job_count = Job.count(:conditions => "job_status in ('#{JobStatus::PROCESSING}', '#{JobStatus::NEW}', '#{JobStatus::ADDITIONAL_JOB_REQUESTED}') and batch_id = #{params[:id]} and is_excluded = 0")
  end

  def update
    @batch = Batch.find(params[:id])
    if @batch.update_attributes(params[:batch])
      @batch.facility = Facility.find_by_name(params[:facility_name])
      @batch.payer = Payer.find_by_payer(params[:form1][:payer_payer]) unless @batch.payer.nil?
      @batch.target_time = @batch.arrival_time + @batch.facility.tat.to_i.hours if @batch.facility.tat
      previous_status = @batch.status
      @batch.status = params[:batch_status]
      # If the batch is completed, add the batch completion time.
      if @batch.status == BatchStatus::COMPLETED || @batch.status == BatchStatus::OUTPUT_READY
        @batch.completion_time = Time.now
      elsif @batch.status == BatchStatus::NEW || @batch.status == BatchStatus::PROCESSING
        # Reseting the completion time to null in case batch status is changed from
        # BatchStatus::COMPLETED/BatchStatus::OUTPUT_READY to 
        # BatchStatus::NEW/BatchStatus::PROCESSING
        @batch.completion_time = nil
      end
      if previous_status == BatchStatus::NEW && @batch.status == BatchStatus::PROCESSING &&
          @batch.processing_start_time.blank?
        @batch.processing_start_time = Time.now
      end
      if previous_status == BatchStatus::PROCESSING && @batch.status == BatchStatus::COMPLETED
        @batch.processing_end_time = Time.now
      end
      @batch.save
      JobActivityLog.create_activity({:allocated_user_id => @current_user.id,
          :activity => 'Batch Changed', :start_time => Time.now,
          :object_name => 'batches', :object_id => @batch.id, :field_name => 'status',
          :old_value => previous_status, :new_value => @batch.status })
      flash[:notice] = 'Batch was successfully updated.'
      action = (params[:from] == 'work_list') ? 'work_list' : 'index'
      redirect_to :action => action
    else
      @facilities =  Facility.find(:all).map{ |facility| facility.name}
      @batch_status = batch_status_details
      render :action => 'edit'
    end
    @batch.save
  end

  def destroy
    Batch.destroy params[:id]
    redirect_to :action => 'index'
  end

  def delete_batches    
    batches = params[:batches_to_delete]
    
    deleted_batches_count = 0
    batches.delete_if do |key, value|
      value == "0"
    end
    deleted_entity_records = []
    deleted_batches = Batch.where(:id => batches.keys, :status.upcase => BatchStatus::NEW).destroy_all
    deleted_batches_count = deleted_batches.length
    
    deleted_batches.each do |batch|
      parameters = { :entity => 'batches', :entity_id => batch.id,
        :client_id => batch.client_id, :facility_id => batch.facility_id }
      deleted_entity_records << DeletedEntity.create_records(parameters)
    end
    if deleted_entity_records.present?
      DeletedEntity.import(deleted_entity_records)
    end
    
    if deleted_batches_count > 0
      flash[:notice] = "Deleted #{deleted_batches_count} batch(es)."
    else
      flash[:notice] = "Batch is under processing or completed already."
    end
    redirect_to :action => 'index'
  end

  def add_job
    unless params[:id].nil?
      @batch = Batch.find(params[:id])
      @jobs = Job.select(" batches.id AS batch_id \
                  , batches.batchid AS batchid \
                  , jobs.id AS id \
                  , jobs.estimated_eob AS estimated_eob \
                  , check_informations.check_number AS check_no \
                  , check_informations.id AS check_id \
                  , payers.id AS payer_id \
                  , (CASE WHEN micr_payers.payer IS NOT NULL
                    THEN micr_payers.payer
                    ELSE
                    CASE WHEN payers.payer IS NOT NULL
                    THEN payers.payer
                    ELSE 'No Payer'
                    END
                    END) AS payer_of_check \
                  , (CASE WHEN COUNT(insurance_payment_eobs.id) != 0
                    THEN COUNT(insurance_payment_eobs.id)
                    ELSE COUNT(patient_pay_eobs.id)
                    END) AS completed_eobs \
                  , micr_line_informations.aba_routing_number as aba_routing_number \
                  , micr_line_informations.payer_account_number as payer_account_number").
        where("jobs.batch_id = #{params[:id]} and jobs.parent_job_id is null").
        joins("INNER JOIN batches ON batches.id = jobs.batch_id \
               LEFT OUTER JOIN check_informations ON check_informations.job_id = jobs.id \
               LEFT OUTER JOIN payers ON payers.id = check_informations.payer_id \
               LEFT OUTER JOIN micr_line_informations ON micr_line_informations.id = check_informations.micr_line_information_id \
               LEFT OUTER JOIN payers micr_payers ON micr_payers.id = micr_line_informations.payer_id \
               LEFT JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id \
               LEFT OUTER JOIN patient_pay_eobs ON patient_pay_eobs.check_information_id = check_informations.id").
        group("jobs.id")
    else
      flash[:notice] = "Job administration screen cannot be accessed directly."
      redirect_to :controller => '/admin/batch', :action => 'index'
    end
  end

  def delete_jobs
    jobs = params[:jobs_to_delete]
    batch = Batch.find(params[:batch])
    jobs.delete_if do |key, value|
      value == "0"
    end
    deleted_entity_records = []
    job_ids = jobs.keys
    deleted_jobs = Job.where(:id => job_ids).destroy_all
    ClientImagesToJob.where(:job_id => job_ids).destroy_all

    deleted_jobs.each do |job|
      parameters = { :entity => 'jobs', :entity_id => job.id,
        :client_id => batch.client_id, :facility_id => batch.facility_id }
      deleted_entity_records << DeletedEntity.create_records(parameters)
    end
    if deleted_entity_records.present?
      DeletedEntity.import(deleted_entity_records)
      Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
    end
    
    deleted_jobs_count = deleted_jobs.length
    if deleted_jobs_count > 0
      flash[:notice] = "Deleted #{deleted_jobs_count} Job(s)."
    else
      flash[:notice] = "Please select atleast one Job to delete."
    end

    redirect_to :action => 'add_job', :id => batch

  end

  def create_job
    job = Job.new(params[:job])
    batch = Batch.find(params[:batch])
    job.batch = batch
    begin
      job.payer_id = Payer.find_by_payer(params[:job1][:payer]).id

      job.job_status = JobStatus::NEW
      job.processor_status = ProcessorStatus::NEW
      job.qa_status = QaStatus::NEW
      # If no check number is specified get the check number of the last created job.
      # Less pain when allocating large jobs with many tiffs.
      if params[:job][:check_number] == ""
        last_job = Job.find(:first, :order=> 'id desc')
        job.check_number = last_job.check_number unless last_job.nil?
      end
      multiplier = 10
      job.estimated_eob = params[:job][:estimated_eob]
      if job.save
        Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
        flash[:notice] = 'Job was successfully created'
      else
        flash[:notice] = 'Failed creating job'
      end
      redirect_to :action => 'add_job', :id => batch
    rescue
      flash[:notice] = 'Please select Payer'
      redirect_to :action => 'add_job', :id => batch
    end
  end

  #This is for creating or updating tat_comment or updating expected_completion_time.
  #This is invoking from Batch Allocation UI, Allocated Batches UI,
  #Batch Status UI and Completed Batches UI and Batches Without TAT Comment UI
  # for tat_comment. This method will update batches table and user_activity_logs
  # table.
  def update_tat_comments
    batch = Batch.find(params[:id])
    description = params[:batch][:tat_comment].strip if params[:edited_field] == 'tat_comment'
    if params[:edited_field] == 'tat_comment' && !description.blank?
      if batch.tat_comment.blank?
        activity = 'TAT Comment Created'
      elsif batch.tat_comment != description
        activity = 'TAT Comment Edited'
      end
      UserActivityLog.create_activity_log(current_user, activity, batch, description)
      batch.tat_comment = description
    else
      batch.expected_completion_time = params[:batch][:expected_completion_time]
    end    
    batch.save

    if params[:edited_field] == 'tat_comment'
      if params[:redirect_window] == 'batches_without_tat_comment'
        redirect_to :action => 'batches_without_tat_comment'
      else
        process_redirect
      end
    elsif params['back_page']==nil
      redirect_to :action => 'allocate'
    else
      redirect_to :action =>'non_compliant'
    end
  end
  
  def process_redirect
    if params[:redirect_window] == 'unprocessed_batches'
      redirect_to :controller => '/hlsc', :action => 'unprocessed_batches'
    elsif params[:redirect_window] == 'allocate'
      redirect_to :action => 'allocate'
    elsif params[:redirect_window] == 'status_wise_batch_list'
      redirect_to :action => 'status_wise_batch_list'
    elsif params[:redirect_window] == 'batches_completed'
      redirect_to :action => 'batches_completed'
    end
  end

  #This is for deleting tat_comment from Batch Allocation UI, Allocated Batches UI,
  #Batch Status UI and Completed Batches UI
  def delete_batch_tat_comment
    batch = Batch.find(params[:id])
    unless batch.blank?
      batch.tat_comment = nil
      batch.save
      UserActivityLog.create_activity_log(current_user, 'TAT Comment Deleted', batch)      
      flash[:notice] = "TAT Comment deleted successfully."
    else
      flash[:notice] = "Failed deleting TAT Comment."
    end
    process_redirect
  end
  
  def payer_list
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    search_field.strip! unless search_field.nil?
    if search_field.blank?
      payer_job_count = Job.payer_job_count
    else
      count = Batch.count(:all,:conditions=>"batchid=#{search_field.to_i}")
      if count > 0
        search_field1 = Batch.find_by_batchid(search_field).id
        payer_job_count = Job.find(:all, :conditions => "batch_id = batches.id and 
          batches.status != '#{BatchStatus::COMPLETED}' and jobs.batch_id=#{search_field1} ",
          :joins => "LEFT JOIN batches on batch_id = batches.id",
          :group => "jobs.payer_id",
          :select => "sum(jobs.estimated_eob) eobs, count(*) count, jobs.payer_id payer_id")
      else
        flash[:notice] = "No record found for Batch ID= \"#{search_field}\"."
        payer_job_count = Job.payer_job_count
      end
    end

    #other_payers - array of payers with ETC as null.
    #etc_payers - array of payers which have ETC defined.
    other_payers = []
    etc_payers = []
    payer_job_count.each do |p|
      payer = Payer.find(p.payer_id)
      p['payer'] = payer
      job_with_min_eobs = payer.least_time
      process_jobs_with_min_eobs(p, job_with_min_eobs)
      p['etc'] == nil ? other_payers << p : etc_payers << p
    end

    #sort payers by ETC
    payers = etc_payers.sort_by do |payer|
      [payer.tat, payer.etc]
    end
    #Add up other payers without ETC assigned @ the end.
    payers = payers + other_payers
    @payer_pages, @payers = paginate_collection payers , :per_page => 30 ,
      :page => params[:page]
  end
  
  def process_jobs_with_min_eobs(payer_job_object, job_with_min_eobs)
    unless job_with_min_eobs.nil?
      payer_job_object['etc'] = job_with_min_eobs.batch.expected_time
      payer_job_object['tat'] = job_with_min_eobs.batch.contract_time(@user.role)
    else
      payer_job_object['etc'] = nil
      payer_job_object['tat'] = nil
    end      
    payer_job_object
  end

  def payer_grouplist
    payer_job_count=Job.find_by_sql("select sum(jobs.estimated_eob) eobs, count(*)
       count,jobs.payer_id payer_id from payers,batches,jobs where jobs.payer_id = payers.id 
       and payers.payer_group_id!=0  and batches.id=jobs.batch_id  and 
       batches.status != '#{BatchStatus::COMPLETED}' group by payers.payer_group_id")
    
    #other_payers - array of payers with ETC as null.
    #etc_payers - array of payers which have ETC defined.
    other_payers = []
    etc_payers = []
    payer_job_count.each do |p|
      payergpid = Payer.find_by_id(p.payer_id).payer_group_id
      if payergpid!=0
        payer1=Payergroup.find_by_id( payergpid).payergroupname
        payer3 = Payer.find_by_id(p.payer_id)
        payer2 = TeamLeaderQueue.find_by_payer_group_id( payergpid)
        
        if payer2.blank?
          p['tlusername'] = 'TL Not Allocated'
        else
          p['tlusername'] = payer2.tlusername
        end

        # puts  payer_job_count
        p['id'] =payergpid
        p['payergroupname'] = payer1
        job_with_min_eobs = payer3.least_time

        process_jobs_with_min_eobs(p, job_with_min_eobs)
        p['etc'] == nil ? other_payers << p : etc_payers << p
      end

      #sort payers by ETC
      payers =  etc_payers.sort_by do |payer|
        [payer.tat, payer.etc]
      end
      #Add up other payers without ETC assigned @ the end.
      payers = payers + other_payers
      @payer_pages, @payers = paginate_collection payers , :per_page => 20 ,
        :page => params[:page]
    end
  end

  def jobfind
    payers1 = []
    payers3 = []
    id = params[:id]
    @pgid =  params[:id]
    @id1 = Payer.find_by_payer_group_id(:all,params[:id])
    
    @id1.each do |p|
      @a = Payer.find_by_payid(p.supply_payid).id
      payer_job_count =Job.find(:all,
        :conditions => "batch_id = batches.id and batches.status != '#{BatchStatus::COMPLETED}'
                       and jobs.payer_id = #{@a}",
        :joins => "LEFT JOIN batches on batch_id = batches.id",
        :group => "jobs.payer_id",
        :select => "sum(jobs.estimated_eob) eobs, count(*) count, jobs.payer_id payer_id")

      #other_payers - array of payers with ETC as null.
      #etc_payers - array of payers which have ETC defined.
      other_payers = []
      etc_payers = []
      payer_job_count.each do |p|
        payer1=Payer.find(p.payer_id)
        # puts  payer_job_count
        p['payid']=p.payer_id
        p['payer'] =payer1
        job_with_min_eobs = payer1.least_time

        process_jobs_with_min_eobs(p, job_with_min_eobs)
        p['etc'] == nil ? other_payers << p : etc_payers << p
      end
      #sort payers by ETC
      payers =  etc_payers.sort_by do |payer|
        [payer.tat, payer.etc]
      end

      #Add up other payers without ETC assigned @ the end.
      payers = payers + other_payers
      payers1<<payers
    end
    @payer_pages, @payers = paginate_collection payers1 , :per_page => 30,
      :page => params[:page]
  end

  def batchlist
    conditions = " batches.status = '#{BatchStatus::PROCESSING}' and jobs.job_status
                  in ('#{JobStatus::COMPLETED}', '#{JobStatus::INCOMPLETED}') "
    conditions = frame_batch_criteria(conditions) unless params[:to_find].blank?
    @batches = Batch.select("batches.id AS id, batches.batchid AS batch_name,
          batches.date as date, batches.eob as eob, batches.arrival_time AS arrival_time,
          facilities.name as facility_name, facilities.sitecode AS facility_sitecode,
          batches.expected_completion_time as expected_completion_time,
          SUM(IF(jobs.job_status = '#{JobStatus::INCOMPLETED}', 1, 0)) AS incompleted_jobs_count,
          SUM(IF(jobs.job_status = '#{JobStatus::COMPLETED}', 1, 0)) AS completed_jobs_count").\
      where(conditions). \
      joins("LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id
                 LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id"). \
      group("batches.id"). \
      order("arrival_time desc"). \
      paginate(:page => params[:page]) unless conditions.blank?

  end

  #----------------------------------------------------
  # Description  : Status wise listing of batches mainly intended for clients. So batch listing is restricted based on user roles.
  #                Batches also will get filtered based on filter options from UI
  # Input        : None.
  # Output       : Batch list for either default view or based on filter options.
  #----------------------------------------------------
  def status_wise_batch_list
    conditions = " batches.status IN ('#{BatchStatus::OUTPUT_READY}', '#{BatchStatus::COMPLETED}','#{BatchStatus::NEW}', '#{BatchStatus::PROCESSING}','#{BatchStatus::OUTPUT_GENERATED}')"
    joins = "LEFT OUTER JOIN facilities ON batches.facility_id = facilities.id"
    process_batch_queries(joins, conditions)
    
    conditions = frame_batch_criteria(conditions) unless params[:to_find].blank?
    order = frame_order_criteria unless params[:to_find].blank?
    @batches = Batch.where(conditions).joins(joins).order(order).paginate(:page => params[:page], :per_page => 20)

  end
  
  def process_batch_queries(joins, conditions)
    if @current_user.has_role?(:partner)
      joins << " INNER JOIN clients ON facilities.client_id = clients.id INNER JOIN partners ON clients.partner_id = partners.id INNER JOIN partners_users ON partners.id = partners_users.partner_id "
      conditions << " AND partners_users.user_id = #{@current_user.id.to_s} "
    elsif @current_user.has_role?(:client)
      joins << " INNER JOIN clients ON facilities.client_id = clients.id INNER JOIN clients_users ON clients.id = clients_users.client_id"
      conditions << " AND clients_users.user_id = #{@current_user.id.to_s} "
    elsif @current_user.has_role?(:facility)
      joins << " INNER JOIN facilities_users ON facilities.id = facilities_users.facility_id "
      conditions << " AND facilities_users.user_id = #{@current_user.id.to_s} "
    end
  end

  #----------------------------------------------------
  # Description  : Status wise listing of completed batches mainly intended for clients. So batch listing is restricted based on user roles.
  #                Batches also will get filtered based on filter options from UI
  # Input        : None.
  # Output       : Completed Batch list for either default view or based on filter options.
  #----------------------------------------------------
  def batches_completed
    conditions = " batches.status IN ('#{BatchStatus::OUTPUT_READY}','#{BatchStatus::COMPLETED}')"
    joins = "INNER JOIN facilities ON batches.facility_id = facilities.id "
    process_batch_queries(joins, conditions)
    
    conditions = frame_batch_criteria(conditions) unless params[:to_find].blank?
    @batches = Batch.where(conditions).joins(joins).order("date desc").paginate(:page => params[:page], :per_page => 20)
  end

  #----------------------------------------------------
  # Description  : Export functionality of completed batches
  # Input        : None.
  # Output       : Completed Batch list for either default view or based on filter options.
  #----------------------------------------------------
  def export_batches
    @search_field = params[:search_field]
    @compare = params[:compare]
    @criteria = params[:criteria]

    joins = ""
    conditions = " batches.status IN ('#{BatchStatus::OUTPUT_READY}','#{BatchStatus::COMPLETED}')"
    if @current_user.has_role?(:partner)
      joins = "INNER JOIN facilities f ON batches.facility_id = f.id INNER JOIN clients c ON f.client_id = c.id "
      joins << "INNER JOIN partners p ON c.partner_id = p.id INNER JOIN partners_users pr ON p.id = pr.partner_id "
      conditions << " AND pr.user_id = #{@current_user.id.to_s} "
    elsif @current_user.has_role?(:client)
      joins = "INNER JOIN facilities f ON batches.facility_id = f.id INNER JOIN clients c ON f.client_id = c.id "
      joins << "INNER JOIN clients_users cr ON c.id = cr.client_id"
      conditions << " AND cr.user_id = #{@current_user.id.to_s} "
    elsif @current_user.has_role?(:facility)
      joins = " INNER JOIN facilities f ON batches.facility_id = f.id INNER JOIN facilities_users fr ON f.id = fr.facility_id "
      conditions << " AND fr.user_id = #{@current_user.id.to_s} "
    end

    unless @search_field.blank?
      case @criteria
      when 'Batch Date'
        begin
          date = Date.strptime(@search_field,"%m/%d/%y")
        rescue ArgumentError
          flash[:notice] = "Invalid date format"
        end
        batches = Batch.find(:all,
          :conditions => conditions + " AND date #{@compare} '#{date}'", :order => "date DESC", :joins => joins)
      when 'Batch ID'
        batches = Batch.find(:all,
          :conditions => conditions + " AND batchid #{@compare} '#{@search_field.to_s}'", :joins => joins)
      when 'Facility Name'
        if @current_user.has_role?(:partner) || @current_user.has_role?(:client) || @current_user.has_role?(:facility)
          batches = Batch.find(:all,
            :conditions =>  conditions + " AND f.name LIKE '%#{@search_field}%'", :order => "date DESC", :joins => joins)
        else
          batches = Batch.find(:all,
            :conditions =>  conditions + " AND facilities.name LIKE '%#{@search_field}%'", :include=>[:facility ], :order => "date DESC", :joins => joins)
        end
        flash[:notice] = "String search, #{@compare} ignored."
      end
    else
      batches = Batch.find(:all, :conditions => conditions, :order => "date desc", :joins => joins)
    end
    unless batches.blank?
      csv_string = CSV.generate do |csv|
        csv << ["Batch Date", "Batch ID", "Facility Name", "Arrival Time (EST)", "Completion Time (EST)", "Completed EOBs"]
        batches.each do |report|
          csv << [(report.date unless report.date.blank?),
            report.batchid,
            report.facility.name,
            (report.arrival_time.strftime('%m/%d/%y %H:%M') unless report.arrival_time.blank?),
            (report.completion_time.strftime('%m/%d/%y %H:%M') unless report.completion_time.blank?),
            report.get_completed_eobs
          ]
        end
      end
      send_data csv_string, :type => "text/csv",
        :filename=>"Batch_report.csv",
        :disposition => 'attachment'
    else
      flash[:notice] = "No matching report found."
      redirect_to :action => "batches_completed"
    end
  end

  def incompletedjobs
    @batchid = params[:id]
    @jobs = Job.where("batch_id =#{@batchid} and job_status  = '#{JobStatus::INCOMPLETED}'").paginate(:per_page => 30 ,:page => params[:page])
  end

  #----------------------------------------------------
  # Description  : Updates the batches comment for selected batches. Called from Batch Status Report page by user of role - Supervisor
  # Input        : No arguements for method, but post method gives in collection of form elements like checkboxes and textarea controls
  # Output       : None.
  #----------------------------------------------------
  def update_client_comment
    batch_ids = params[:batch_to_delete]
    batch_comments = params[:batch_comment]

    batch_ids.delete_if do |key,value|
      value == "0"
    end

    if batch_ids.blank?
      flash[:notice]="Please select atleast one batch to update comments"
      redirect_to :controller =>'batch',:action => 'status_wise_batch_list'
    else
      batch_ids.keys.each do |id|
        comment = batch_comments.fetch(id).to_s
        batch = Batch.find(id)
        batch.update_attributes(:comment => (comment.blank? ? "" : comment))
      end
      redirect_to :controller =>'batch',:action => 'status_wise_batch_list'
    end
  end

  def status_change

    batchids = params[:batch_to_delete]
    batchids.delete_if { |k,v| v == "0" }

    if batchids.blank?
      flash[:notice] = "Select a batch to change status"
    else
      batchcount = Job.count(:all,:conditions=>["job_status not in ('#{JobStatus::COMPLETED}','#{JobStatus::INCOMPLETED}') and batch_id in (?)",batchids.keys])

      if batchcount > 0
        flash[:notice] = "Unable to change status due to unprocessed #{batchcount} jobs"
      else
        Batch.where("id in (?)",batchids.keys).each do |batch|
          batch.update_attributes(:status => "#{BatchStatus::OUTPUT_READY}")
        end
        flash[:notice] = "Batch status changed successfully"
      end
    end
    redirect_to :controller =>'batch', :action => 'batchlist'
  end
  
  def output_batch
    @batches=Batch.find(:all,:conditions=>" batches.status in 
            ('#{BatchStatus::OUTPUT_READY}', '#{BatchStatus::COMPLETED}')")
    @batch_pages, @batches = paginate_collection @batches, :per_page => 30 ,:page => params[:page]
  end
  
  def process_batch_archive (batchids)
    batchids.keys.each do |id|
      batch = Batch.find(id)
      batch.status = BatchStatus::ARCHIVED
      batch.save
    end
  end

  
  def process_generation_of_aggregate_ops_log(batchids)
    unless batchids.blank?
      ids = batchids.keys
      batch_array = []
      ids.each do |id|
        batch_array << Batch.select('date').where("id = '#{id}'")[0]
      end
      date_array = []
      batch_array.each do |arr|
        date_array << arr.date
      end
      if date_array.uniq.length == 1
        redirect_to :action => "generate_aggregate_operation_log", :id => ids.first, :ids => ids, :date_from => params[:date_from], :date_to => params[:date_to]
      else
        flash[:notice] = "Please select batches with same batch date"
        redirect_to :controller =>'batch',:action => 'batch_payer_report_835', :date_from => params[:date_from], :date_to => params[:date_to]
      end
    end

  end
  
  def process_generation_of_images(batchids)
    if batchids.keys.length == 1
      id = batchids.keys.first
      unless id.blank?
        generate_images(id)
      else
        flash[:notice] = "Please select 1 batch to generate images"
        redirect_to :controller =>'batch',:action => 'batch_payer_report_835', :date_from => params[:date_from], :date_to => params[:date_to]
      end
    else
      flash[:notice] = "Please select 1 batch to generate images"
      redirect_to :controller =>'batch',:action => 'batch_payer_report_835', :date_from => params[:date_from], :date_to => params[:date_to]
    end
  end

  def batch_archive
    batchids = params[:batch_to_delete].select {|key,value| value == "1"}
    next_gen_output = 0
    @batches = []
    if (batchids.blank? )
      flash[:notice]="Please select one batch"
      redirect_to :action => 'batch_payer_report_835', :date_from => params[:date_from], :date_to => params[:date_to]
    elsif params[:option1]=="Archive"
      process_batch_archive(batchids)
      flash[:notice]="Batch Archived"
      redirect_to :action => 'batch_payer_report_835', :date_from => params[:date_from], :date_to => params[:date_to]
      # Generates the output using the configurable output module, This calls the method 'generate_output' which triggers the rake task to generate the output, Only one batch can be selected to generate the output
    elsif params[:option1] == "Generate Output"
      ids = batchids.keys
      redirect_to :action => "generate_output_files", :id => ids.first, :ids => ids, :date_from => params[:date_from], :date_to => params[:date_to]
    elsif params[:option1] == "Generate Aggregate Ops Log"
      process_generation_of_aggregate_ops_log(batchids)
    elsif params[:option1] == "Generate Images"
      process_generation_of_images(batchids)
    end
  end

  def generate_images(batch_id)
    batch = Batch.find(:first, :conditions => ["id = ?", batch_id],
      :include => [{:jobs => :images_for_jobs}, :images_for_jobs])
    start_time = Time.now
    unless batch.blank?
      begin
        directory_path = "#{Rails.root}/multipage_image/#{batch.batchid}"
        logger.info "Copying images to #{directory_path}"
        system "rm -R #{directory_path}"
        system "mkdir -p #{directory_path}"

        if batch.facility.incoming_image_type == true
          # For milti tiff images
          batch.jobs.each do |job|
            unless job.is_excluded == true
              image_paths = []
              image_records = job.images_for_jobs
              count_of_images = image_records.length
              directory_1, directory_2 = nil, nil
              image_name = job.initial_image_name
	      
              image_records.each do |image|
                
                id_in_string = image.id.to_s
                id_in_string = id_in_string.rjust(8, '0')
                directory_1 = id_in_string.slice(0..3) # this indicates the dir name under /unzipped_files
                directory_2 = id_in_string.slice(4..7) # this indicates the second level dir name under /unzipped_files/<directory_1>
                image_paths << "#{Rails.root}/private/unzipped_files/#{directory_1}/#{directory_2}/#{image.filename}"
              end
              system("cd #{directory_path}; tiffcp #{image_paths.join(' ')} #{directory_path}/#{image_name}")
              # Making all the file names that end with .tif or .tiff or .TIF or .TIFF into .tif
              system "find #{directory_path} -type f ! -name '*.tif' ! -name '*.tiff' ! -name '*.TIF' ! -name '*.TIFF' | xargs -I{} mv {} {}.tif"
            end
          end
        else
          # For single tiff images

          batch.jobs.each do |job|
            unless job.is_excluded == true
              job.images_for_jobs.each do |image|
                id_in_string = image.id.to_s
                id_in_string = id_in_string.rjust(8, '0')
                directory_1 = id_in_string.slice(0..3) # this indicates the dir name under /unzipped_files
                directory_2 = id_in_string.slice(4..7) # this indicates the second level dir name under /unzipped_files/<directory_1>
                system "cp #{Rails.root}/private/unzipped_files/#{directory_1}/#{directory_2}/#{image.filename} #{directory_path}"
                # Making all the file names that end with .tif or .tiff or .TIF or .TIFF into .tif
                system "find #{directory_path} -type f ! -name '*.tif' ! -name '*.tiff' ! -name '*.TIF' ! -name '*.TIFF' | xargs -I{} mv {} {}.tif"
              end
            end
          end
        end
        JobActivityLog.create_activity({:allocated_user_id => @current_user.id,
            :activity => 'Image Generated', :start_time => start_time,
            :end_time => Time.now, :object_name => 'batches', :object_id => batch.id }, true)
        flash[:notice] =  "Images are copied to  #{directory_path}"
      rescue Exception => exception
        logger.error "Exception caught while generating images => " + exception.message
        logger.error exception.backtrace.join("\n")
      end      
    else
      flash[:notice] = "Please select 1 batch to generate images"
    end
    redirect_to :controller =>'batch',:action => 'batch_payer_report_835', :date_from => params[:date_from], :date_to => params[:date_to]
  end

  # The method 'generate_output' triggers the raks task to generate the output
  def generate_output
    logger.info "============== starting generate_output"
    batch = Batch.find(params[:id])
    client = batch.client
    if batch.qualified_for_output_generation?
      # todo:  && batch.qualified_for_supplimental_output_generation?
      batches_for_output = batch.batch_bundle.to_a
      batch_ids = batches_for_output.collect {|batch_for_output| batch_for_output.id}
      Batch.where(:id=>batch_ids).update_all(:output_835_start_time => Time.now, :updated_at => Time.now)
      batches_for_supplemental_output = batch.batch_bundle_for_supplemental_output
      batch_ids_for_supplemental_output = batches_for_supplemental_output.collect {|batch_for_suppl_output| batch_for_suppl_output.id}
      cgf = CheckGroupFile.new(batches_for_output.first.facility, current_user)
      logger.info "============== after CheckGroupFile.new"
      cgf.send :process_batch_ids, batch_ids, batch_ids_for_supplemental_output
      logger.info "============== after process_batch_ids"
      if client.supplemental_outputs.present? && client.supplemental_outputs.include?("Operation Log")
        puts "Operation Log is configured at client level, please uncheck that if you want facility level"
      else
        puts "Generating Operation Log at Facility Level...."
        OperationLog::Generator.new(batch_ids,ack_latest_count).generate
      end
      logger.info "============== after OperationLog::Generator"
      OtherOutput::Automator.new(batch.id, batch_ids).process
      #OtherOutput::Generator.new(batch.id).generate
      @message = "Output generated successfully"
    else
      @message = "Batch #{batch.batchid} is not ready for output generation,
                  please check the status of this batch and other batches that fall into the same group for output generation"
    end
  rescue Exception => e
    str = "Output generation failed with errors, please contact revremitsupport@revenuemed.com. "
    @message = str + e.message
  end
  
  #this method generates the 835 output files using delayed job
  def generate_output_files
    not_qualified_batches = []
    params[:ids].each do |id|
      batch = Batch.find(id)
      batch_group = batch.batch_group('Output').to_a
      batch_ids = batch_group.collect(&:id)
      is_output_qualified = !batch_group.detect { |batch| batch.incomplete? }
      if is_output_qualified
        Batch.mark_output_generating batch_ids
        Batch.delay(:queue => 'generating_output').start_generating_output(batch_ids, batch_group, id, request.referer, current_user)
      else
        not_qualified_batches << batch.batchid
      end
    end unless params[:ids].blank?
    if not_qualified_batches.blank?
      @message = "Batches are successfully assigned to delayed job for generating output"
    else
      @message = "Batch #{not_qualified_batches.to_sentence} is not ready for output generation, please check the status"
    end
    
    render :action=>:generate_output, :date_from => params[:date_from], :date_to => params[:date_to]
  end

  #this method generates the aggregate operation log at client level
  def generate_aggregate_operation_log
    begin
      params[:ids].each do |id|
        batch = Batch.find(id)
        client = batch.client
        batch_group = batch.batch_group_client_level 'Operation Log'
        if batch_group
          batch_ids = batch_group.collect(&:id)
          is_qualified_for_oplog = !batch_group.detect { |batch| batch.incomplete? }
          if is_qualified_for_oplog
            ack_latest_count = OutputActivityLog.get_latest_number
            if client.supplemental_outputs.present? && client.supplemental_outputs.include?("Operation Log")
              puts "Generating Operation Log at Client Level...."
              OperationLog::Generator.new(batch_ids,ack_latest_count).generate
              @message = "Client Level Operation log  generated successfully"
            else
              puts "Operation Log is not configured at client level"
              @message = "Operation Log is not configured at client level"
            end
          else
            puts "Batch #{batch.batchid} is not ready for operation log generation"
            @message = "Batch #{batch.batchid} is not ready for operation log generation"
          end
        else
          puts "Client Level Configuration for generationg operation log not found...........\n Please configure it and try again"
          @message = "Client Level Configuration for generationg operation log not found...........\n Please configure it and try again"
        end
      end unless params[:ids].blank?
    rescue => e
      puts "Operation Log Generation failed with following errors"
      puts e.message
      puts e.backtrace
    end
    render :action=>:generate_output, :date_from => params[:date_from], :date_to => params[:date_to]
  end

  
  def batch_payer_report_835
    @date_from = params[:date_from]
    @date_to = params[:date_to]

    if(!@date_from.blank? && !@date_to.blank?)
      date_from = Date.strptime(@date_from, "%m/%d/%Y").to_s
      date_to = Date.strptime(@date_to, "%m/%d/%Y").to_s
      conditions = unless (params[:first_to_find].blank? && params[:second_to_find].blank?)
        btch_criteria_v2
      else
        conditions = ["batches.date >= ? and  batches.date <= ? and batches.status
          in ('#{BatchStatus::OUTPUT_READY}', '#{BatchStatus::COMPLETED}', '#{BatchStatus::OUTPUT_GENERATED}', '#{BatchStatus::OUTPUT_EXCEPTION}', '#{BatchStatus::OUTPUT_GENERATING}')", date_from,date_to]
      end
      @batches = Batch.includes([:facility]).joins("LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id LEFT JOIN batch_output_statuses on batch_output_statuses.batch_status = batches.status").where(conditions).group("batches.id").order("batch_output_statuses.id ,batches.target_time asc").paginate(:page => params[:page])
    elsif(@date_from.blank? && !@date_to.blank?)
      flash[:notice] = "From Date Mandatory"
    elsif(!@date_from.blank? && @date_to.blank?)
      flash[:notice] = "To Date Mandatory"
    else
      flash[:notice] = "Dates are Mandatory"
    end
  end
  
  #This is for listing batches with status as BatchStatus::ARCHIVED
  def archive_batch
    conditions = " batches.status='#{BatchStatus::ARCHIVED}'"
    @batches = Batch.where(conditions).select("batches.id AS id,
        batches.batchid AS batch_name, batches.date AS date, facilities.name AS facility_name,
        facilities.sitecode AS facility_sitecode, batches.arrival_time AS arrival_time,
        batches.expected_completion_time AS expected_completion_time,
        batches.status AS status").joins("LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id").
      group("batches.id").paginate(:page => params[:page])
  end

  

  # Unused feature in production. The operations need to ask for a ravamped version of this.
  # This feature is not used in production now. Confirmed from business.
  # Please see more details in https://track.revenuemed.com/issues/22903
  def reasoncode_csv
    reason_codes = ReasonCode.find(:all)
    file_name = "reasoncode_" + Date.today.to_s
    csv_string = CSV.generate do |csv|
      csv << ["Payer", "Reasoncode","Reasoncode Description","Client Code","HIPAA Code","ANSI codes"]
      reason_codes.each do | reason_code|
        reason_code.reason_codes_clients_facilities_set_names.each do | rccfsn|
          reasoncode = rccfsn.reason_code
          set_name = reasoncode.reason_code_set_name
          payers = set_name.payers if set_name
          payer = payers.first if payers
          if payer
            payer_name = payer.name
          else
            payer_name = 'UNKNOWN'
          end
          hipaa_code = rccfsn.hipaa_code
          client_code = rccfsn.client_code
          ansi_codes = rccfsn.ansi_codes
          csv << [payer_name,reasoncode.reason_code,reasoncode.reason_code_description,client_code,hipaa_code,ansi_codes]
        end
      end
    end
    send_data csv_string, :type => "text/csv",
      :filename=>file_name + ".csv",
      :disposition => 'attachment'
  end

  
  def batches_without_tat_comment
    condtons = "batches.target_time < batches.output_835_generated_time and batches.tat_comment is null"
    condtons = frame_batch_criteria(condtons) unless params[:to_find].blank?

    @batches_without_tat_comment = Batch.select("batches.batchid as batchid \
                    , batches.status as status \
                    , batches.arrival_time as arrival_time \
                    , batches.contracted_time as contracted_time \
                    , batches.target_time as target_time \
                    , batches.completion_time as completion_time \
                    , batches.comment as comment \
                    , batches.date as date \
                    , batches.id as id \                    
                    , batches.expected_completion_time as expected_completion_time \
                    , facilities.sitecode as facility_sitecode \
                    , facilities.name as facility_name \
                    , facilities.tat as facility_tat \
                    , count(if(jobs.job_status = '#{JobStatus::NEW}', 1, 0)) as allocated \
                    , count(if(jobs.processor_status = '#{ProcessorStatus::NEW}' or \
                        jobs.processor_status = '#{ProcessorStatus::ALLOCATED}' or \
                        jobs.processor_status = '#{ProcessorStatus::ADDITIONAL_JOB_REQUESTED}', 1, 0)) as processor_allocated \
                    , sum(jobs.estimated_eob) as tot_estimated_eobs \
                    , count(insurance_payment_eobs.id) + count(patient_pay_eobs.id) as tot_completed_eobs \
                    , batches.tat_comment as tat_comment\
                    , batches.output_835_generated_time as output_835_generated_time").\
      where(condtons). \
      joins("LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id \
                    LEFT OUTER JOIN clients ON clients.id = facilities.client_id \
                    LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id \
                    LEFT OUTER JOIN check_informations ON check_informations.job_id = jobs.id \
                    LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id \
                    LEFT OUTER JOIN patient_pay_eobs ON patient_pay_eobs.check_information_id = check_informations.id"). \
      group("batches.id"). \
      order("arrival_time desc"). \
      paginate(:page => params[:page]) unless condtons.blank?
  end

  def auto_complete_for_batch_tat_comment
    tat_comment = params[:batch][:tat_comment]
    auto_complete_for_tat_comment(tat_comment)
  end

  def auto_complete_for_tat_comment(tat_comment)
    begin
      @tat_comments = FacilityLookupField.where("facility_lookup_fields.lookup_type = 'TAT Comment' and
         facility_lookup_fields.name like '#{tat_comment}%'")
    rescue
      @tat_comments = nil
    end
    render :partial => 'auto_complete_for_tat_comment'
  end

  def work_list
    @field_options = ['', 'Date', 'Batch ID', 'Site Name', 'Site Number',
      'Status', 'Allocation Type', 'RMS Provider ID']
    @label_for_button = 'Enable Ocr job Auto Allocation'
    conditions = "((status = '#{BatchStatus::NEW}' or status = '#{BatchStatus::PROCESSING}' or status = '#{BatchStatus::COMPLETED}') and jobs.is_excluded = 0)"
    if !params[:to_find].blank? && !params[:criteria].blank?
      conditions = frame_batch_criteria(conditions)
    end
    unless conditions.blank?
      @batches = Batch.work_list_collection(conditions).paginate(:page => params[:page], :per_page => 30)
      batches_with_estimated_eob_count = Batch.work_list_estimated_eob_count_collection(conditions).
        paginate(:page => params[:page], :per_page => 30)
      batches_with_image_count = Batch.work_list_image_count_collection(conditions).
        paginate(:page => params[:page], :per_page => 30)
    end
    if @batches.length > 0
      first_batch = @batches.first
      if first_batch.facility_name == "REVENUE MANAGEMENT SOLUTIONS LLC"
        @is_rms = true
      else
        @is_rms = false
      end
      if first_batch.ocr_job_auto_allocation_enabled == true
        @label_for_button = 'Disable Ocr job Auto Allocation'
      else
        @label_for_button = 'Enable Ocr job Auto Allocation'
      end

      @batches_with_estimated_eob_count = Batch.build_hash_of_batch_attribute(batches_with_estimated_eob_count, 'tot_estimated_eobs')
      @batches_with_image_count = Batch.build_hash_of_batch_attribute(batches_with_image_count, 'batch_image_count')
    end
    render :layout => "standard_inline_edit"
  end

  def export_work_list
    conditions = "((status = '#{BatchStatus::NEW}' or status = '#{BatchStatus::PROCESSING}' or status = '#{BatchStatus::COMPLETED}') and jobs.is_excluded = 0)"
    if !params[:to_find].blank? && !params[:criteria].blank?
      conditions = frame_batch_criteria(conditions)
    end
    unless conditions.blank?
      batches = Batch.work_list_collection(conditions).all
      batches_with_estimated_eob_count = Batch.work_list_estimated_eob_count_collection(conditions).all
      batches_with_image_count = Batch.work_list_image_count_collection(conditions).all
      hash_of_batches_with_estimated_eob_count = Batch.build_hash_of_batch_attribute(batches_with_estimated_eob_count, 'tot_estimated_eobs')
      hash_of_batches_with_image_count = Batch.build_hash_of_batch_attribute(batches_with_image_count, 'batch_image_count')
    end
    csv = CSV.generate do |row|
      row << ['Batch Date', 'Batch ID', 'Type', 'Site Name', 'Site Code',
        'Arrival Time', 'Facility TAT', 'Number of checks', 'Number of images', 'Production Completion Time', 'Exp Completion Time',
        'Estimated EOBs', 'Completed EOBs', 'Status', 'TAT Comment', 'Priority', 'Allocation Type']
      
      if !batches.blank?
        batches.each do |batch|
          type = batch.batch_type
          batch_date = format_datetime(batch.date,'%m/%d/%y') || '-'
          facility_tat = format_datetime(batch.batch_facility_tat(batch.facility_tat)) || '-'
          completion_time = format_datetime(batch.completion_time) || '-'
          expected_completion_time = format_datetime(batch.expected_completion_time) || '-'
          row << [batch_date, batch.batchid, type, batch.facility_name,
            batch.facility_sitecode, format_datetime(batch.arrival_time),
            facility_tat, batch.checks_count, (hash_of_batches_with_image_count[batch.id] || '-'),
            completion_time, expected_completion_time,
            hash_of_batches_with_estimated_eob_count[batch.id].to_f.round || '-',
            batch.total_completed_eobs, batch.status, batch.tat_comment, batch.priority, batch.allocation_type]
        end
      end
    end
    send_data csv, :type=> 'text/csv', :filename => 'Work_List.csv'
  end

  # Updates the allocation_type and status of the chosen batches
  # Provides the fash notice for the user after updation
  # Input :
  # params[:batches_to_select] : batches chosen from the UI
  # params[:submit_param] : Contains the action chosen by user to submit the form
  def update_allocation_type_and_batch_status
    batches_to_select = params[:batches_to_select]
    all_batch_ids = params[:batches_to_select].keys
    first_batch_id = all_batch_ids[0]
    batch = Batch.select("ocr_job_auto_allocation_enabled").
      where("id = #{first_batch_id}")
    
    batches_to_select.delete_if do |key, value|
      value == "0"
    end
    batch_ids = batches_to_select.keys
    case params[:submit_param]
    when 'Enable Ocr job Auto Allocation'
      if batch[0].ocr_job_auto_allocation_enabled == true
        notice = 'Ocr job Auto Allocation Already Enabled'
      else
        Batch.enable_ocr_job_allocation(all_batch_ids)
        notice = "Enabled ocr job allocation for batches"
      end
    when 'Disable Ocr job Auto Allocation'
      if batch[0].ocr_job_auto_allocation_enabled == false
        notice = 'Ocr job Auto Allocation Already Disabled'
      else
        Batch.disable_ocr_job_allocation(all_batch_ids)
        notice = "Disabled ocr job allocation for batches"
      end
    end
    
    if !batch_ids.blank?
      case params[:submit_param]
      when 'Facility Wise Auto Allocation'
        Batch.add_to_facility_wise_allocation_queue(batch_ids)
        processors = IdleProcessor.select("user_id")
        processor_ids = processors.map(&:user_id)
        IdleProcessor.delete_all
        JobAllocator::allocate_facility_wise(processor_ids, true)
        notice = "Added batches to facility wise auto allocation queue"
      when 'Payer Wise Auto Allocation'
        Batch.add_to_payer_wise_allocation_queue(batch_ids)
        notice = "Added batches to payer wise auto allocation queue"
      when 'Remove From Auto Allocation'
        Batch.remove_from_allocation_queue(batch_ids)
        #Processor name and status got cleared when a batch removed from Auto Allocation(#23711)
        #reset_jobs_and_processors(batch_ids)
        notice = "Removed batches from auto allocation queue"
      when 'Make Output Ready'
        job_activities = []
        batch_ids.each do |batch_id|
          job_activities << JobActivityLog.create_activity({:allocated_user_id => @current_user.id,
              :activity => 'Batch Changed', :start_time => Time.now,
              :object_name => 'batches', :object_id => batch_id, :field_name => 'status',
              :old_value => BatchStatus::COMPLETED, :new_value => BatchStatus::OUTPUT_READY }, false)
        end
        JobActivityLog.import job_activities if !job_activities.blank?
        updated_batch_count = Batch.change_status_to_output_ready(batch_ids)
        notice = "Changed the status of #{updated_batch_count} batches to Output Ready."
      end
    else
      if !params[:submit_param].include?("Ocr job Auto Allocation")
        notice = "Please select atleast one batch."
      end
    end
    flash[:notice] = notice
    redirect_to :action => "work_list"
  end
  
  def reset_jobs_and_processors(batch_ids)
    jobs = Job.where(:batch_id => batch_ids)
    reset_attr = {:processor_id => nil, :processor_status => ProcessorStatus::NEW}
    jobs.each do |job|
      processor = job.processor
      job.update_attributes(reset_attr)
      Batch.where(:id => batch_ids).update_all(:associated_entity_updated_at => Time.now)
      unless processor.nil?
        processor.toggle!(:allocation_status) if processor.count_of_jobs_processing == 0
      end
    end unless jobs.blank?
  end

  private

  def insert_meta_data(zone_value,page,dpi,field_name,field_value,account_state,record_pointer,confidence)
    record_pointer.update_attribute("#{field_name}","#{field_value}")
    field_ocr_output = field_name+"_ocr_output"
    field_data_origin = field_name+"_data_origin"
    field_number_page = field_name+"_page"
    field_number_coordinates = field_name+"_coordinates"
    field_number_state = field_name+"_state"
    field_number_confidence = field_name+"_confidence"
    record_pointer.details[field_ocr_output.to_sym] = field_value if field_value
    record_pointer.details[field_data_origin.to_sym] = find_the_data_origin_of(account_state.to_s,field_value,confidence)
    record_pointer.details[field_number_page.to_sym] = page
    record_pointer.details[field_number_coordinates.to_sym] = find_the_cordinates_of(zone_value,dpi.to_i)
    record_pointer.details[field_number_state.to_sym] = account_state.to_s
    record_pointer.details[field_number_confidence.to_sym] = confidence.to_i
  end

  def insert_meta_data_existing_value(zone_value,page,dpi,field_name,field_value,account_state,record_pointer,confidence)
    field_ocr_output=field_name+"_ocr_output"
    field_data_origin=field_name+"_data_origin"
    field_number_page=field_name+"_page"
    field_number_coordinates=field_name+"_coordinates"
    field_number_state = field_name+"_state"
    field_number_confidence = field_name+"_confidence"
    record_pointer.details[field_ocr_output.to_sym] = field_value if field_value
    record_pointer.details[field_data_origin.to_sym] = find_the_data_origin_of(account_state.to_s,field_value,confidence)
    record_pointer.details[field_number_page.to_sym] = page
    record_pointer.details[field_number_coordinates.to_sym] = find_the_cordinates_of(zone_value,dpi.to_i)
    record_pointer.details[field_number_state.to_sym] = account_state.to_s
    record_pointer.details[field_number_confidence.to_sym] = confidence.to_i
  end

  def find_the_data_origin_of(value,text,confidence)
    flag = text.to_s.include?("?") unless text.nil? #chances of ? with 100% confidence
    if (value == "Ok" and flag == false and confidence.to_i > 50)
      return 1
    elsif (value == "Reject" or (value == "Ok" and flag == true) or (confidence.to_i < 50))
      return 2
    elsif (value == "Empty" and flag == true)
      return 2
    elsif value == "Empty"
      return 3
    end
  end

  def find_the_cordinates_of(zone_values,dpi)
    split_zone_values = zone_values.split(" ")
    zone_array = []
    for zone in split_zone_values
      zone = zone.to_i
      a = (zone / 10) * 0.039370079 * dpi
      zone_array << a
    end
    return zone_array
  end

  def insert_data(patient_1)
    account_state = account_numbers[pcount].attributes["state"]
    pat_first_name, pat_second_name = patient_1.split(',')
    @eob.patient_first_name = pat_first_name
    @eob.patient_last_name =  pat_second_name
    @eob.details[:patient_first_name_ocr_output] = pat_first_name if pat_first_name

    @eob.details[:patient_first_name_data_origin] = find_the_data_origin_of(account_state.to_s,patient_account_no)

    page = patient.xpath('./sources/image').attr('name').split("_").last
    @eob.details[:patient_first_name_page] = page
    dpi = patient.xpath('./sources/image').attr('XResolution')
    @zone_value = patient.xpath('./zone').inner_text
    @eob.details[:patient_first_name_coordinates] = find_the_cordinates_of(@zone_value,dpi.to_i)
    @eob.details[:patient_last_name_ocr_output] = pat_second_name if pat_second_name
    @eob.details[:patient_last_name_data_origin] = @eob.details[:patient_first_name_data_origin]
    @eob.details[:patient_last_name_page] = page
    @eob.details[:patient_last_name_coordinates] = find_the_cordinates_of(@zone_value,dpi.to_i)
    @eob.save!
  end

end
