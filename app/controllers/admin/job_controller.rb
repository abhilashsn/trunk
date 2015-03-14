# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
require 'rubygems'
require 'csv'
class Admin::JobController < ApplicationController
  #  require 'rmagick'
  require_role ["admin", "supervisor", "TL"]
  layout 'standard', :except => [:incomplete]
  before_filter :prepare, :only => [:edit_micr, :update_micr]
  in_place_edit_for :job, :payer_group
  respond_to :html, :json
  def index
    list
    render :action => 'list'
  end

  # RAILS3.1 TODO
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [:destroy, :create, :update],
  #  :redirect_to => {:controller => 'batch', :action => :list}

  def list
    @jobs = Job.paginate(:all ,:order => 'batch_id desc, job_status', :page => params[:page], :per_page => 30)
  end

  def show
    @job = Job.find(params[:id])
  end

  def new
    @batch = Batch.find(params[:id])
    @job = Job.new
    @statuses = Status.find(:all).map do |status|
      status.value
    end
    session[:batch] = @batch.id
  end

  def create
    @job = Job.new(params[:job])
    batch = Batch.find(session[:batch])
    @job.batch = batch
    @job.job_status = JobStatus::NEW
    if @job.save
      Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
      flash[:notice] = 'Job was successfully created.'
      redirect_to :controller => 'batch', :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @job = Job.find(params[:id])
  end

  def split
    @job = Job.find(params[:id])
    @from = params[:from]
  end

  def split_update
    job = Job.find(params[:id])
    new_job = Job.new
    new_job.check_number = job.check_number
    batch = job.batch
    new_job.batch = batch
    new_job.payer = job.payer
    new_job.save
    if new_job.update_attributes(params[:new_job])
      Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
      flash[:notice] = 'Job was successfully updated.'
    else
      flash[:notice] = 'Job update failed.'
    end
    redirect_to :controller => "/admin/batch", :action => "add_job", :id => new_job.batch, :from => params[:from], :payer => params[:payer]
  end

  def update
    @job = Job.find(params[:id])
    batch = @job.batch
    respond_to do |format|
      if @job.update_attributes(params[:job])
        Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
        format.html { redirect_to(:controller => 'batch', :action => 'add_job', :id => batch, :notice => 'User was successfully updated.') }
        format.json { render json: :back }
      else
        format.html { render :action => "edit" }
        format.json { render json: :back }
      end
    end
  end

  def edit_payer
    @job = Job.find(params[:id])
  end

  #Method to show the MICR and Payer details for editing.
  def edit_micr
    @eob_count = @check_information.get_eob_count
    payer = @check_information.get_payer
    @payer_name = payer.payer if !payer.blank?
  end

  # Method to update the MICR Data for Correspondence as well as for Payment checks.
  # 1.If Check Number equals to Zero, then the user (admin/supervisor) should be
  # able to delete the MICR and Payer details from the corresponding check.
  # 2.If check Number is not equal to Zero, then the user should not be able to
  # delete the MICR / Payer name. But MICR edit should be possible.
  # 3.No provision to create new MICR record from this view.
  def update_micr
    if params[:option1] == "Save"
      if valid_corr_check_number? || !@is_micr_configured
        @check_information.micr_line_information_id = nil
        @check_information.payer_id = nil
        redirect_to :action => 'edit_micr', :id => params[:id]
      elsif !valid_corr_check_number? && @is_micr_configured
        unless @micr_line_info.blank?
          if params[:micr_line_information] && !params[:micr_line_information][:aba_routing_number].blank? &&
              !params[:micr_line_information][:payer_account_number].blank?
            @aba_routing_number_frm_ui = params[:micr_line_information][:aba_routing_number].strip
            @payer_account_number_frm_ui = params[:micr_line_information][:payer_account_number].strip
            if !@aba_routing_number_frm_ui.blank? && !@payer_account_number_frm_ui.blank?
              if hyphen_absent?
                change_micr_reference
              else
              
                update_micr_record
              end
            end
          else
            flash[:notice] = "Required MICR data"
            redirect_to :action => 'edit_micr', :id => params[:id]
          end
        else
          flash[:notice] = "No MICR found for this check"
          redirect_to :action => 'edit_micr', :id => params[:id]
        end
      end
      Batch.where(:id => @job.batch_id).update_all(:associated_entity_updated_at => Time.now)
      @check_information.save
      @job.save
    end
  end

  #  This method will update the existing micr record with aba_routing_number
  #  and payer_account_number from UI.
  def update_micr_record
    @micr_exists = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(@aba_routing_number_frm_ui, @payer_account_number_frm_ui)
    if @micr_exists
      @check_information.micr_line_information = @micr_exists
      @check_information.payer_id = @micr_exists.payer_id
      unless @micr_exists.payer_id.blank?
        save_payer_group
      end
      reason_codes_jobs = @job.reason_codes_jobs
      reason_codes_jobs.destroy_all unless reason_codes_jobs.blank?
      redirect_to :action => 'edit_micr', :id => params[:id]
    else
      @micr_line_info.update_attributes(:aba_routing_number => @aba_routing_number_frm_ui,
        :payer_account_number => @payer_account_number_frm_ui)
      redirect_to :action => 'edit_micr', :id => params[:id]
    end
  end

  #  This method will change the existing micr reference of a check.

  def change_micr_reference
    @micr_exists = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(@aba_routing_number_frm_ui, @payer_account_number_frm_ui)
    if @micr_exists
      @check_information.micr_line_information = @micr_exists
      @check_information.payer_id = @micr_exists.payer_id
      unless @micr_exists.payer_id.blank?
        save_payer_group
      end
      reason_codes_jobs = @job.reason_codes_jobs
      reason_codes_jobs.destroy_all unless reason_codes_jobs.blank?
      redirect_to :action => 'edit_micr', :id => params[:id]
    else
      flash[:notice] = "MICR not found."
      redirect_to :action => 'edit_micr', :id => params[:id]
    end
  end

  def save_payer_group
    payer = Payer.find_by_id("#{@micr_exists.payer_id}")
    if payer
      @job.payer_group = format_payer_type(payer.payer_type)
    end
  end

  def destroy
    Job.destroy params[:id]
    redirect_to :controller => 'batch', :action => 'add_job'
  end

  
  def allocate
    if (params[:back_page].blank?)
      @request_source_path = request.referer
    else
      @request_source_path = params[:back_page]
    end
    if params[:id].nil?
      @batch = Batch.find(session[:batch])
    else
      @batch = Batch.find(params[:id])
      session[:batch] = @batch.id
    end
    payer_condition = ""
    search_field = params[:to_find]
    criteria = params[:criteria].to_s

    unless params[:sort].blank?
      sort_by = (params[:sort].class == String ? params[:sort] : params[:sort].keys[0])
      @sort = sort_by
    end
    
    unless params[:payer].nil?
      payer = Payer.find(params[:payer])
      payer_condition = "payer_id = #{payer.id}" unless payer.nil? 
    end

    select_attributes = "jobs.id AS id, jobs.batch_id AS batch_id, jobs.estimated_eob AS estimated_eob,
      jobs.job_status AS job_status, jobs.incomplete_count AS incomplete_eob_count,
      jobs.incomplete_tiff AS incomplete_tiff, jobs.processor_status AS processor_status,
      jobs.qa_status AS qa_status, jobs.pages_from AS pages_from,
      jobs.pages_to AS pages_to, jobs.parent_job_id AS parent_job_id,
      jobs.payer_group,
      jobs.is_ocr AS is_ocr_flag,
      jobs.split_parent_job_id as split_parent_job_id,
      jobs.is_correspondence as is_correspondence,
      micr_line_informations.is_ocr as is_micr_ocr_flag,
      CASE WHEN jobs.parent_job_id IS NULL
      THEN check_informations.check_number
      ELSE jobs.check_number
       END AS check_number,
      facilities.details AS facility_details_column, batches.batchid AS batchid,
      CASE WHEN parent_job_id IS NULL
      THEN check_informations.check_amount
      ELSE NULL
      END AS check_amount_value, check_informations.details AS check_details_column,
      check_informations.id AS check_id, payers.id AS payer_id,
      (CASE WHEN payers.payer IS NOT NULL
      THEN payers.payer
      ELSE
      CASE WHEN micr_payers.payer IS NOT NULL
      THEN micr_payers.payer
      ELSE 'No Payer'
      END
      END) AS name_payer,  ins1.details AS eob_details_column,
      (CASE WHEN jobs.parent_job_id IS NOT NULL
      THEN COUNT(ins1.id) + COUNT(patient_pay_eobs.id)
      ELSE
           COUNT(ins2.id) + COUNT(patient_pay_eobs.id)
      END)  AS completed_eobs,
      (CASE WHEN jobs.parent_job_id IS NOT NULL
       THEN SUM(((IFNULL(ins1.total_amount_paid_for_claim,0)) - (IFNULL(ins1.over_payment_recovery, 0))) +
       IFNULL(ins1.claim_interest,0) +
       IFNULL(ins1.late_filing_charge,0) + IFNULL(patient_pay_eobs.stub_amount,0) )
       ELSE
       SUM(((IFNULL(ins2.total_amount_paid_for_claim, 0)) - (IFNULL(ins2.over_payment_recovery, 0))) +
       IFNULL(ins2.claim_interest, 0) +
       IFNULL(ins2.late_filing_charge,0) + IFNULL(patient_pay_eobs.stub_amount,0) )
       END) AS amount_so_far,
      (CASE WHEN jobs.parent_job_id IS NOT NULL
      THEN
      IFNULL(ins1.claim_interest,0)
      ELSE
      IFNULL(ins2.claim_interest,0)
      END) AS total_interest_amount,users.name AS processor_name, users.id AS processor_id, qa_users.name AS qa_name, qa_users.id AS qa_id  "
    join_tables = "INNER JOIN batches ON batches.id = jobs.batch_id
INNER JOIN facilities ON facilities.id = batches.facility_id
LEFT JOIN check_informations ON CASE WHEN parent_job_id IS NULL THEN jobs.id ELSE parent_job_id END =check_informations.job_id
LEFT JOIN insurance_payment_eobs ins1 ON jobs.id =ins1.sub_job_id AND jobs.batch_id = #{@batch.id} AND jobs.parent_job_id IS NOT NULL
LEFT JOIN insurance_payment_eobs ins2 ON ins2.check_information_id = check_informations.id AND jobs.batch_id = #{@batch.id} AND jobs.parent_job_id IS NULL
LEFT OUTER JOIN patient_pay_eobs ON patient_pay_eobs.check_information_id = check_informations.id
LEFT OUTER JOIN payers ON payers.id = check_informations.payer_id
LEFT OUTER JOIN micr_line_informations ON micr_line_informations.id = check_informations.micr_line_information_id
LEFT OUTER JOIN payers micr_payers ON micr_payers.id = micr_line_informations.payer_id
LEFT OUTER JOIN users ON users.id = jobs.processor_id LEFT OUTER JOIN users qa_users ON qa_users.id = jobs.qa_id "

    if params[:tab] == "ocr_jobs"
      tab_specific_condition = "(jobs.is_ocr = 1 and micr_line_informations.is_ocr = 1 and jobs.is_excluded = 0)"
    elsif params[:tab] == "excluded_jobs"
      tab_specific_condition = "(jobs.is_excluded = 1)"
    else
      tab_specific_condition = "((jobs.is_ocr = 0 or jobs.is_ocr IS NULL or (jobs.is_ocr = 1 and micr_line_informations.is_ocr != 1) ) and jobs.is_excluded = 0)"
    end

    if search_field.blank?
      conditions = ["jobs.batch_id = ? #{payer_condition} and jobs.job_status != ? and #{tab_specific_condition}", @batch.id, JobStatus::EXCLUDED]
    else
      conditions =  filter_jobs(payer_condition, tab_specific_condition)
    end
    
    if !sort_by.blank?
      unless sort_by.match('_reverse') == nil
        sort_by = sort_by.chomp('_reverse')
        order_by = " DESC"
      else
        order_by = " ASC"
      end
      order = frame_order(sort_by) + order_by
    elsif search_field.blank?
      order = "CASE WHEN jobs.parent_job_id IS NOT NULL THEN jobs.parent_job_id ELSE jobs.id END, substring(jobs.check_number,1,locate('_',jobs.check_number)-1),jobs.id"
    else
      order = "payers.payer"
    end
    if (!search_field.blank? && (criteria == "Amount So Far" || criteria == "Balance" ||criteria == "Completed EOBs" || criteria == "Job ID" ))
      @jobs = Job.select(select_attributes).joins(join_tables).where(conditions).
        group("jobs.id").having(having_condition).order(order).
        paginate(:page => params[:page], :per_page => 60)
    else
      @jobs = Job.select(select_attributes).joins(join_tables).where(conditions).
        group("jobs.id").order(order).paginate(:page => params[:page], :per_page => 60)
    end
    @parents_of_splitted_jobs = Job.where(:id => @jobs.map(&:parent_job_id).uniq.compact)
    child_jobs_having_status_as_not_new = Job.select("parent_job_id").where("parent_job_id IS NOT NULL AND job_status != 'NEW'")
    if !child_jobs_having_status_as_not_new.blank?
      @parent_job_ids_having_status_of_child_jobs_as_not_new = child_jobs_having_status_as_not_new.map(&:parent_job_id)
      @parent_job_ids_having_status_of_child_jobs_as_not_new = @parent_job_ids_having_status_of_child_jobs_as_not_new.uniq
    end
    
    if @jobs.blank?
      flash[:notice] = "Your search '#{params[:criteria]} #{params[:compare]} #{search_field}' did not return any results. Try another search!"
      render :layout => "standard_inline_edit"
    else
      @client_name = @batch.facility.client.name
      render :layout => "standard_inline_edit"
    end    

  end
  
  def allocate_users
    @batches = Batch.paginate(:all,:page => params[:page],:per_page => 30)
    @jobs = Job.paginate(:all,:order => 'batch_id desc,job_status',:page => params[:page],:per_page => 30)
  end

  def allocate_deallocate
    session[:current_page1] = params[:page]
    batch = Batch.find(session[:batch])
    count =0
    all_jobs = params[:jobs_to_allocate]
    user = params[:user]
    all_jobs.delete_if do |key, value|
      value == "0"
    end
    @jobs = []
    all_jobs.keys.each do |id|
      @jobs << Job.find_by_id(id)
    end
        
    headers = ["check_number", "estimated_eob", "processor_name", "processor_status",
      "qa_name", "qa_status", "job_status", "payer_group", "incomplete_tiff", "name_payer",
      "pages_from", "pages_to", "check_amount_value", "amount_so_far", "balance"]
    header_for_descending_order = []
    headers.each { |header| header_for_descending_order << header + '_reverse'}
    headers << header_for_descending_order
    headers = headers.flatten

    if @jobs.empty?
      flash[:notice] = 'Select atleast one Job'
      if params[:from] == 'payer'
        redirect_to :action => 'allocate_payer_jobs', :payer => params[:payer], :back_page => params[:back_page]
      elsif params[:from] == 'user'
        redirect_to :action => 'user_jobs', :payer => params[:payer], :user => params[:jobs_of_user], :back_page => params[:back_page]
      else
        redirect_to :action => 'allocate', :page=>params[:page],
          :back_page => params[:back_page], :tab => params[:tab]
      end
    elsif params[:option1] == 'Manual Split'
      redirect_to :action => 'manual_split_job', :jobs => @jobs, 
        :job_split_count => params[:job_split_count],
        :criteria => params[:criteria], :compare => params[:compare],
        :to_find => params[:to_find], :tab => params[:tab], :back_page => params[:back_page]
    elsif params[:option1] == "Create New Job"
      redirect_to :action => "create_new_job", :jobs => @jobs,
        :payer => params[:payer], :tab => params[:tab], :back_page => params[:back_page]
    elsif params[:option1] == 'Auto Split'
      redirect_to :action => 'auto_split_job', :jobs => @jobs,
        :job_split_count => params[:job_split_count], :tab => params[:tab], :back_page => params[:back_page]
    elsif params[:option1] == 'Allocate QA'
      redirect_to :action => 'add_qa', :jobs => @jobs, :payer => params[:payer],
        :from => params[:from], :jobs_of_user => params[:jobs_of_user], :tab => params[:tab], :back_page => params[:back_page]
    elsif params[:option1] == 'Allocate Processor'
      processor_statuses = @jobs.map(&:processor_status)

      if processor_statuses.include?(ProcessorStatus::COMPLETED) || processor_statuses.include?(ProcessorStatus::INCOMPLETED)
        flash[:notice] = 'Processor Completed/ Incompleted job/s cannot allocate again.'
        redirect_to :action => 'allocate', :id => @jobs[0].batch_id,
          :page => params[:page], :tab => params[:tab], :back_page => params[:back_page]
      elsif processor_statuses.include?(ProcessorStatus::ALLOCATED) || processor_statuses.include?(ProcessorStatus::ADDITIONAL_JOB_REQUESTED)
        flash[:notice] = 'Processor job status should be NEW for allocating a job. Please deallocate the user and then try allocating it.'
        redirect_to :action => 'allocate', :id => @jobs[0].batch_id,
          :page => params[:page], :tab => params[:tab], :back_page => params[:back_page]
      else
        redirect_to :action => 'add_processor', :jobs => @jobs, :payer => params[:payer],
          :from => params[:from], :tab => params[:tab], :back_page => params[:back_page]
      end
      
    elsif params[:option1] == 'Deallocate Processor'
      redirect_to :action => 'deallocate_processor', :jobs => @jobs,
        :payer => params[:payer], :from => params[:from], :tab => params[:tab], :back_page => params[:back_page]
    elsif params[:option1] == 'Deallocate QA'
      redirect_to :action => 'deallocate_qa', :jobs => @jobs, :payer => params[:payer],
        :from => params[:from], :jobs_of_user => params[:jobs_of_user], :tab => params[:tab], :back_page => params[:back_page]
    elsif params[:option1] == 'Excluded Job'
      redirect_to :action => 'change_jobs_to_excluded', :jobs => @jobs, :payer => params[:payer],
        :from => params[:from], :jobs_of_user => params[:jobs_of_user], 
        :tab => params[:tab], :batch_id => @jobs[0].batch_id, :back_page => params[:back_page]
    elsif params[:option1] == 'Non Excluded Job'
      redirect_to :action => 'change_jobs_to_non_excluded', :jobs => @jobs, :payer => params[:payer],
        :from => params[:from], :jobs_of_user => params[:jobs_of_user], 
        :tab => params[:tab], :batch_id => @jobs[0].batch_id, :back_page => params[:back_page]
    elsif params[:option1] == 'Delete'
      redirect_to :action => 'delete_jobs', :jobs => @jobs, :payer => params[:payer],
        :from => params[:from], :jobs_of_user => params[:jobs_of_user],
        :tab => params[:tab], :batch_id => @jobs[0].batch_id, :back_page => params[:back_page]
    end
  end

  def add_processor
    @jobs = params[:jobs]
    if (current_user.has_role?("admin") or current_user.has_role?("supervisor"))
      @users = User.select("users.*, \
              (CASE WHEN users.last_activity_at IS NULL THEN '2012-01-01' ELSE last_activity_at END) AS last_activity_at, \
               COUNT(jobs.id) AS jobs_processing, \
               shifts.name AS shift_name").
        joins("INNER JOIN roles_users ON roles_users.user_id = users.id
               INNER JOIN roles ON roles.id = roles_users.role_id
               INNER JOIN shifts ON shifts.id = users.shift_id
               LEFT OUTER JOIN jobs ON jobs.processor_id = users.id AND jobs.processor_status = '#{ProcessorStatus::ALLOCATED}'").
        where("roles.name = 'processor' AND login_status = #{ONLINE} AND auto_allocation_enabled = true").
        group("users.id").
        order("jobs_processing ASC, last_activity_at DESC, users.login ASC")
    end    
  end

  def add_qa
    @jobs = params[:jobs]
    @users = User.find(:all, :conditions => "roles.name = 'qa' and login_status = #{ONLINE}",
      :include => [{:roles_users => :role}])
  end

  def assign
    user = User.find(params[:user])
    @jobs = Job.find(params[:jobs])
    job_id_array = params[:jobs]
    @jobs.each do |job|
      if user.has_role?("processor")
        job.processor_status = ProcessorStatus::ALLOCATED
        job.job_status = JobStatus::PROCESSING
        job.processor_id = user.id
        job.processor_flag_time = Time.now
        job.save
        user.allocation_status = BUSY
        user.save
      elsif user.has_role?("qa")
        job.qa_status = QaStatus::ALLOCATED
        job.job_status = JobStatus::PROCESSING
        job.qa_id = user.id
        job.qa_flag_time = Time.now
        job.comment_for_qa = params[:qa][:comment]        
        job.save
      end
    end
    batch = @jobs[0].batch
    unless job_id_array.blank?
      job_id_array.each do |job_id|
        if user.has_role?("processor")
          assign_job_activity(job_id, user.id, session[:user_id], nil, nil)
        elsif user.has_role?("qa")
          assign_job_activity(job_id, nil, session[:user_id], user.id, nil)
        end
      end
    end
    if user.has_role?("qa")
      batch.set_qa_status
    end
    batch.update_status
    # TODO: EOB processing rate is hardcoded here
    # Give an option for the supervisor to edit it
    batch.expected_completion_time = batch.expected_time
    batch.save
    if params[:from] == 'payer'
      redirect_to :action => 'allocate_payer_jobs', :payer => params[:payer]
    elsif params[:from] == 'user'
      redirect_to :action => 'user_jobs', :payer => params[:payer], :user => params[:jobs_of_user]
    else
      redirect_to :action => 'allocate', :page=>  session[:current_page1],
        :back_page => params[:back_page], :tab => params[:tab]
    end
  end

  def set_payer_group_in_job_allocation_view

    @check_information = CheckInformation.find_by_id(params[:check_id])
    @eob_count = @check_information.get_eob_count
    if @eob_count != 0
      flash[:notice] = "Please delete exiting eobs to change payer group"
      redirect_to :action => 'allocate', :back_page => params[:back_page]
    else
      @payer_group = params[:value]
      Job.update(params[:job_id], :payer_group => params[:value])
      Job.update_all({:payer_group => params[:value], :updated_at => Time.now}, {:parent_job_id => params[:job_id]})
      render :layout => false, :inline => '<%= @payer_group %>'
    end
  end

  def set_is_correspondence
    @check_information = CheckInformation.find_by_id(params[:check_id])
    @eob_count = @check_information.get_eob_count
    if @eob_count != 0
      flash[:notice] = "Please delete existing eobs to change COR"
      redirect_to :action => 'allocate', :back_page => params[:back_page]
    else
      @is_correspondence = params[:value]
      value = (params[:value] == 'true') ? true : false
      Job.update(params[:job_id], :is_correspondence => value)
      Job.update_all({:is_correspondence => value, :updated_at => Time.now}, {:parent_job_id => params[:job_id]})
      render :layout => false, :inline => '<%= @is_correspondence %>'
    end
  end


  def filter
    @job_batchid = params[:jobs]
    @to_search_for = params[:job][:to_find]
    @compare = params[:job][:compare]
    case @criteria_to_search = params[:job][:criteria]
    when 'Check Number'
      if @compare == '='
        @jobs = Job.find(:all, :conditions => "check_number = '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      elsif @compare == '>='
        @jobs = Job.find(:all, :conditions => "check_number >= '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      else
        @jobs = Job.find(:all, :conditions => "check_number <= '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      end
    when 'Count'
      if @compare == '='
        @jobs = Job.find(:all, :conditions => "count = '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      elsif @compare == '>='
        @jobs = Job.find(:all, :conditions => "count >= '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      else
        @jobs = Job.find(:all, :conditions => "count <= '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      end
    when 'Processor'
      @jobs = Job.find(:all, :conditions => "users.name like '%#{@to_search_for}%' " +
          "and batch_id = '#{@job_batchid}'",
        :joins => "left join users on processor_id = users.id")
    when 'QA'
      @jobs = Job.find(:all, :conditions => "users.name like '%#{@to_search_for}%' " +
          "and batch_id = '#{@job_batchid}'",
        :joins => "left join users on qa_id = users.id")
    when 'Status'
      @jobs = Job.find(:all, :conditions => "status like '%#{@to_search_for}%' " +
          "and batch_id = '#{@job_batchid}'")
    when 'Tiff Number'
      if @compare == '='
        @jobs = Job.find(:all, :conditions => "tiff_number = '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      elsif @compare == '>='
        @jobs = Job.find(:all, :conditions => "tiff_number >= '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      else
        @jobs = Job.find(:all, :conditions => "tiff_number <= '#{@to_search_for}' " +
            "and batch_id = '#{@job_batchid}'")
      end
    end

    if @jobs.size == 0
      flash[:notice] = "Search for #{@to_search_for} did not return any results. Try another keyword!"
      redirect_to :action => 'allocate', :back_page => params[:back_page]
    end
  end

  def deallocate_processor
    @jobs = Job.find(params[:jobs])
    processors = []
    job_activities = []
    @jobs.each do |job|
      job_activities << JobActivityLog.create_activity({:job_id => job.id, :processor_id => job.processor_id,
          :allocated_user_id => @current_user.id, :activity => 'Processor De-Allocated',
          :start_time => Time.now, :object_name => 'jobs', :object_id => job.id,
          :field_name => 'check_number', :old_value => job.check_number }, false)
      processors << job.processor
      job.processor = nil
      job.count = 0
      job.processor_status = ProcessorStatus::NEW
      if job.qa_status == QaStatus::NEW
        job.job_status = JobStatus::NEW
      end

      job.save
    end
    JobActivityLog.import job_activities if !job_activities.blank?
    batch = @jobs[0].batch
    # TODO: EOB processing rate is hardcoded here
    # Give an option for the supervisor to edit it
    unless batch.expected_completion_time.blank?
      batch.expected_completion_time = Time.now
      batch.save
    end
       
    batch.update_status
    processors.each do |processor|
      if !processor.blank? && processor.count_of_jobs_processing == 0
        processor.allocation_status = IDLE
        processor.save
      end
    end
   
    if params[:from] == 'payer'
      redirect_to :action => 'allocate_payer_jobs', :payer => params[:payer]
    else
      redirect_to :action => 'allocate', :page=> session[:current_page1],
        :back_page => params[:back_page], :tab => params[:tab]
    end
  end

  def deallocate_qa
    job_activities = []
    @jobs = Job.find(params[:jobs])
    @jobs.each do |job|
      job_activities << JobActivityLog.create_activity({:job_id => job.id, :qa_id => job.qa_id,
          :allocated_user_id => @current_user.id, :activity => 'QA De-Allocated',
          :start_time => Time.now, :object_name => 'jobs', :object_id => job.id,
          :field_name => 'check_number', :old_value => job.check_number }, false)
      job.qa = nil
      job.qa_status = QaStatus::NEW
      if job.processor_status == ProcessorStatus::NEW
        job.job_status = JobStatus::NEW
      end
      if (job.processor_status == ProcessorStatus::COMPLETED and job.qa_status == QaStatus::NEW)
        job.job_status = JobStatus::COMPLETED
      elsif (job.processor_status == ProcessorStatus::INCOMPLETED and job.qa_status == QaStatus::NEW)
        job.job_status = JobStatus::INCOMPLETED
      end
      job.save
      job.batch.set_qa_status
    end
    JobActivityLog.import job_activities if !job_activities.blank?
    batch = @jobs[0].batch
    # TODO: EOB processing rate is hardcoded here
    # Give an option for the supervisor to edit it
    unless batch.expected_completion_time.blank?
      batch.expected_completion_time = Time.now
      batch.save
    end
    batch.update_status

    if params[:from] == 'payer'
      redirect_to :action => 'allocate_payer_jobs', :payer => params[:payer]
    elsif params[:from] == 'user'
      redirect_to :action => 'user_jobs', :payer => params[:payer], :user => params[:jobs_of_user]
    else
      redirect_to :action => 'allocate', :page=>  session[:current_page1],
        :back_page => params[:back_page], :tab => params[:tab]
    end
  end

  #Allocate jobs for a particular payer, same as job allocation but for a particular payer
  def allocate_payer_jobs
    # Commented some statements as a part of Rails 3.. Need to remove these commented lines in the next iteration..
    @user = session[:user]
    @payer = Payer.find(params[:payer])
    @jobs = Job.where("jobs.payer_id = #{@payer.id} and batches.status != '#{BatchStatus::COMPLETED}'").includes(:batch).paginate(:page => params[:page], :per_page => 50)
  end

  #Display jobs of particular user
  def user_jobs
    @selected_user = User.find(params[:user])
    jobs = filter_user_jobs(params[:user], params[:hours])
    @job_pages, @jobs = paginate_collection jobs, :per_page => 50, :page => params[:page]
  end

  def filter_user_jobs(user, hrs)
    @user_selected = User.find(user)
    time_interval = Time.now - hrs.to_i.hours
    jobs = Job.find(:all, :conditions => ["processor_id = ? and processor_status != '#{ProcessorStatus::NEW}' and processor_flag_time >= ?", @user_selected.id, time_interval])
  end

  def qa_jobs
    @selected_user = User.find(params[:user])
    jobs = filter_qa_jobs(params[:user], params[:hours])
    @job_pages, @jobs = paginate_collection jobs, :per_page => 50, :page => params[:page]
  end

  def filter_qa_jobs(user, hrs)
    @user_selected = User.find(user)
    time_interval = Time.now - hrs.to_i.hours
    jobs = Job.find(:all, :conditions => ["qa_id = ? and qa_status != '#{QaStatus::NEW}' and qa_flag_time >= ?", @user_selected.id, time_interval])
  end


  def qa_completed
    time_interval = Time.now - 7.days
    jobs = Job.find(:all, :conditions => ["work_queue = 0 and qa_status = '#{QaStatus::COMPLETED}' and sqa_status = 'New' and qa_flag_time >=?", time_interval], :order => "qa_flag_time")

    @job_pages, @jobs = paginate_collection jobs, :per_page => 30, :page => params[:page]
    @count=Job.count(:conditions => "work_queue = 1 and sqa_status != 'Complete'")

  end

  def work_list

    if params[:option1] == 'Add to Work Queue'
      all_jobs = params[:jobs_to_allocate]
      all_jobs.delete_if do |key, value|
        value == "0"
      end
      all_jobs.keys.each do |id|
        @jobs = Job.find_by_id(id)

        @jobs.work_queue = 1
        @jobs.work_queue_flagtime = Time.now
        @jobs.save
      end

      if all_jobs.keys.size > 0
        flash[:notice] = 'Job(s) successfully added to Work Queue'
      else
        flash[:notice] = 'Select atleast one'
      end

      redirect_to :action => 'qa_completed'

    elsif  params[:option1] == 'Remove from Work Queue'
      all_jobs = params[:jobs_to_allocate]
      all_jobs.delete_if do |key, value|
        value == "0"
      end
      @jobs = []
      all_jobs.keys.each do |id|
        @jobs = Job.find_by_id(id)

        if all_jobs.keys.size > 0
          flash[:notice] = 'Job(s) successfully removed from Work Queue'
        else
          flash[:notice] = 'Select atleast one'
        end
      end
      redirect_to :action => 'qa_completed'
    end
  end

  def work_queue
    jobs = Job.find(:all, :conditions => ["work_queue = 1 and sqa_status != 'Complete'"], :order => "work_queue_flagtime")

    @job_pages, @jobs = paginate_collection jobs, :per_page => 30, :page => params[:page]
  end

  def remove
    all_jobs = params[:jobs_to_allocate]
    all_jobs.delete_if do |key, value|
      value == "0"
    end
    all_jobs.keys.each do |id|
      @jobs = Job.find_by_id(id)

      unless @jobs.sqa_status == 'Processing'
        @jobs.work_queue = 0
        @jobs.save
        @flag = 1
      else
        @flag = 0
      end

    end
    if all_jobs.keys.size > 0

      if @flag == 1
        flash[:notice] = 'Job(s) successfully removed from Work Queue'
      else
        flash[:notice] = 'Cannot Remove Processing Job(s)'
      end

    else
      flash[:notice] = 'Select atleast one'
    end
    redirect_to :action => 'work_queue'
  end

  def manual_split_job
    flash[:notice] = nil
    @job_id = params[:jobs]
    if @job_id.length > 1
      flash[:notice] = "Please Select only one Job at a time."
      redirect_to :back
    else
      job = Job.find(@job_id)
      image_type = Batch.find(job[0].batch_id).facility.image_type
      @job_split_count = params[:job_split_count].to_i
      
      if image_type == 1
        @total_no_of_images = job[0].pages_to.to_i
      else
        @total_no_of_images = ClientImagesToJob.count(:all,
          :conditions => ["job_id =?", @job_id])
      end
      
      @no_of_jobs_with_exact_no_of_images = @total_no_of_images / @job_split_count
      @no_of_jobs_with_not_exact_no_of_images = @total_no_of_images % @job_split_count
      
      processors = User.get_online_user_names_for_role('processor')    
      @processors = ["--"].concat(processors)
    
      qas = User.get_online_user_names_for_role('qa') 
      @qas = ["--"].concat(qas)
    end
  end

  def processor_allocated_jobs
    @jobs = Job.where("processor_status = '#{ProcessorStatus::ALLOCATED}' OR processor_status = '#{ProcessorStatus::ADDITIONAL_JOB_REQUESTED}'").includes([:batch, :processor]).order("batches.target_time").paginate(:page => params[:page])
  end

  def create_sub_jobs
    if params[:job_split_range].blank?
      flash[:notice] = "Please Select atleast one from Job Range"
      redirect_to :back
    else
      @sub_jobs = params[:job_split_range][:id]
      @job_id = params[:jobid]
      image_type = Job.find(@job_id[0]).batch.facility.image_type
      processor_username = params[:processor]
      qa_username = params[:qa]
      if (Job.create_splited_job(@job_id, @sub_jobs, processor_username, qa_username, image_type, current_user.id))
        redirect_to :action => 'allocate',:page =>  session[:current_page1],
          :criteria => params[:criteria], :compare => params[:compare],
          :to_find => params[:to_find], :tab => params[:tab], :back_page => params[:back_page]
      end
    end
  end

  def deallocate_auto_allocate_jobs
    users = params[:users_to_deallocate]
    users.delete_if do |key, value|
      value == "0"
    end
    users.keys.each do |id|
      job = Job.find(id)
      processor = job.processor
      job.processor_id = nil
      job.processor_status = ProcessorStatus::NEW
      job.job_status = JobStatus::NEW
      job.save
      Batch.where(:id => job.batch_id).update_all(:associated_entity_updated_at => Time.now)
      processor.toggle!(:allocation_status) if processor.count_of_jobs_processing == 0
    end
    if users.size != 0
      flash[:notice] = "Updated #{users.size} Job."
    else
      flash[:notice] = "Please select atleast one Job to deallocate"
    end
    redirect_to :action => 'processor_allocated_jobs'
  end

  def auto_split_job
    job_id = params[:jobs]
    if job_id.length > 1
      flash[:notice] = "Please Select only one Job at a time."
      redirect_to :back
    else
      job_split_count = params[:job_split_count]
      image_type = Job.find(job_id[0]).batch.facility.image_type
      Job.do_auto_split_job(job_id, job_split_count, image_type)
      redirect_to :action => 'allocate', :page =>  session[:current_page1],
        :tab => params[:tab], :back_page => params[:back_page]
    end
  end    

  def create_new_job  
    @jobs = params[:jobs]
    if is_job_valid?
      @job_information = Job.find(@jobs.first.to_s)
      @client_name = @job_information.batch.facility.client.name
      @temp_job = TempJob.new
      get_images
      @image_count = @images.count - 1
      @image_names = @images.map{|i| i.image_file_name}
      @new_jobs = Job.where(:split_parent_job_id => @job_information.id).includes(:check_informations)
      render :layout => "job_split"
    else
      redirect_to :back
    end
  end

  def list_images
    job_id = params[:job_id]
    @job_information ||= Job.find(job_id)
    get_images
    render :partial => 'list_images'
  end

  def reorder_images
    sorted_image_ids = params[:image_ids].gsub("[", '').gsub("]", '').split(',') if params[:image_ids].present?
    sorted_image_ids.each_with_index do |item, i|
      client_images_to_job = ClientImagesToJob.where(:images_for_job_id => item.to_s).
        includes(:job, :images_for_job).first
      @job_information ||= client_images_to_job.job
      @images ||= @job_information.images_for_jobs
      client_images_to_job.images_for_job.update_attributes(:image_number => i+1)
    end

    render :partial => 'list_images', locals: { images: @images.sort{|a,b| a.image_number <=> b.image_number} }
  end
  
  def create_jobs
    temp_jobs = TempJob.find_all_by_job_id(params[:job_id])
    Job.transaction do
      temp_jobs.each do |temp_job|
        @temp_job = temp_job
        @new_job = prepare_job_and_associations
        reassociate_images_and_save_child_and_parent_job
      end
    end
    redirect_to_prev_page
  end


  # Updates check number and amount of a job, called from Create New Job UI
  def update_check
    job = Job.find(params[:id])
    check = job.check_information
    batch = job.batch
    respond_to do |format|
      if check.update_attributes(params[:check_information])
        Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
        format.json { render json: :back }
      else
        format.json { render :json => check.errors.full_messages, :status => :unprocessable_entity}
      end
    end
  end


  def delete_jobs
    jobs = params[:jobs_to_delete] || params[:jobs]
    proceed = job_id_collection_valid?(jobs)
    if proceed
      jobs = jobs.keys if !params[:jobs_to_delete].blank?
      jobs.each do |id|
        job_to_delete = Job.find(id)
        if is_eligible_for_delete(job_to_delete)
          Job.transaction do
            success = transfer_images_to_parent(job_to_delete)
            success &&= CheckInformation.delete(job_to_delete.check_informations)
            if success && Job.delete(id)
              flash[:notice] = "Job(s) deleted successfully"
            else
              flash[:notice] = "Failed to delete job(s)"
            end
          end
        else
          break
        end
      end
    end
    redirect_to :back
  end

  # updates the jobs table when admin/supervisor incompletes job
  def update_incomplete_jobs
    job_ids = params[:ids]
    selected_batch = Job.find(job_ids[0]).batch
    job_ids.each do |job_id|
      Job.find(job_id).update_attributes(:processor_comments => params[:job][:processor_comments],:rejected_comment => params[:job][:processor_comments],
        :job_status => "#{JobStatus::INCOMPLETED}", :processor_status => "#{ProcessorStatus::INCOMPLETED}")
    end
    selected_batch.expected_completion_time = Time.now if selected_batch.expected_completion_time.blank?
    previous_batch_status = selected_batch.status
    selected_batch.status = BatchStatus::PROCESSING
    if previous_batch_status == BatchStatus::NEW && selected_batch.status == BatchStatus::PROCESSING &&
        selected_batch.processing_start_time.blank?
      selected_batch.processing_start_time = Time.now
    end
    selected_batch.save
  end
  
  def unattended_jobs
    order = "batches.priority asc, clients.tat asc"
    conditions = ["processor_status = ? &&
                   u1.login_status = ? ", ProcessorStatus::ALLOCATED, 0]
    @jobs = Job.select("jobs.id as id \
                    , jobs.parent_job_id as parent_job_id \
                    , batches.id as batch_id \
                    , batches.batchid as batchid \
                    , batches.date as batch_date\
                    , batches.priority as priority\
                    , batches.facility_id as facility\
                    , facilities.tat as facility_tat\
                    , check_informations.check_number as check_number\
                    , check_informations.check_amount as check_amt\
                    , check_informations.payer_id as payer\
                    , jobs.job_status as job_status\
                    , jobs.pages_from as pages_from\
                    , jobs.pages_to as pages_to\
                    , jobs.estimated_eob as estimated_eob\
                    , shifts.name as shift_name\
                    , facilities.details as details\
                    , u1.name as processor_name\
                    , u2.name as qa_name" ).
      where(conditions).
      joins("LEFT OUTER JOIN batches ON jobs.batch_id = batches.id \
                    LEFT OUTER JOIN facilities ON facilities.id = batches.facility_id \
                    LEFT OUTER JOIN clients ON clients.id = facilities.client_id \
                    LEFT OUTER JOIN users u1 ON jobs.processor_id = u1.id \
                    LEFT OUTER JOIN users u2 ON jobs.qa_id = u2.id \
                    LEFT OUTER JOIN shifts ON u1.shift_id = shifts.id \
                    LEFT OUTER JOIN check_informations ON check_informations.job_id = jobs.id").
      
      order(order).
      paginate(:page => params[:page], :per_page => 30)
  end

  def change_jobs_to_excluded
    @jobs = Job.find(params[:jobs])
    batch = Batch.find(params[:batch_id])
    
    @jobs.each do |job|
      job.is_excluded = true
      unless job.processor_id.blank?
        job.processor_status = ProcessorStatus::NEW
        job.processor_id = nil
      end
      
      unless job.qa_id.blank?
        job.qa_id = nil
        job.qa_status = QaStatus::NEW
      end
      job.job_status = JobStatus::NEW
      job.save
      
      child_jobs = Job.where(["parent_job_id =?",job.id])
      child_jobs.each do |child_job|
        child_job.is_excluded = true
        unless child_job.processor_id.blank?
          child_job.processor_status = ProcessorStatus::NEW
          child_job.processor_id = nil
        end

        unless child_job.qa_id.blank?
          child_job.qa_id = nil
          child_job.qa_status = QaStatus::NEW
        end

        child_job.job_status = JobStatus::NEW
        child_job.save
      end
    end
    Batch.where(:id => @jobs.first.batch_id).update_all(:associated_entity_updated_at => Time.now)
    batch.update_status
     
    if params[:from] == 'payer'
      redirect_to :action => 'allocate_payer_jobs', :payer => params[:payer]
    elsif params[:from] == 'user'
      redirect_to :action => 'user_jobs', :payer => params[:payer], :user => params[:jobs_of_user]
    else
      redirect_to :action => 'allocate', :page=> session[:current_page1],
        :back_page => params[:back_page], :tab => params[:tab], :batch_id => batch.id
    end
  end

  def change_jobs_to_non_excluded
    @jobs = Job.find(params[:jobs])
    batch = Batch.find(params[:batch_id])
    job_ids = @jobs.map(&:id).join(',')
    batch_ids = @jobs.map(&:batch_id).join(',')
    Job.where("id IN (#{job_ids}) OR parent_job_id IN (#{job_ids})").update_all(:is_excluded => false, :updated_at => Time.now)
    Batch.where(:id => batch_ids).update_all(:associated_entity_updated_at => Time.now)
    batch.update_status
    
    if params[:from] == 'payer'
      redirect_to :action => 'allocate_payer_jobs', :payer => params[:payer]
    elsif params[:from] == 'user'
      redirect_to :action => 'user_jobs', :payer => params[:payer], :user => params[:jobs_of_user]
    else
      redirect_to :action => 'allocate', :page=> session[:current_page1],
        :back_page => params[:back_page], :tab => params[:tab], :batch_id => batch.id
    end
  end

  def additional_job_request_queue
    @jobs = Job.select("batches.batchid, batches.date AS batch_date, batches.priority, \
       batches.target_time AS batch_tat, jobs.id AS id, jobs.processor_comments, \
       jobs.pages_to, jobs.check_number, jobs.job_status, users.login AS processor_login, \
       jobs.count AS processed_eobs, jobs.pages_from, jobs.pages_to").
      joins("INNER JOIN batches ON batches.id = jobs.batch_id
      LEFT OUTER JOIN users ON users.id = jobs.processor_id").
      where("jobs.job_status = '#{JobStatus::ADDITIONAL_JOB_REQUESTED}'").
      group("jobs.id").order("batches.priority, batches.target_time").
      paginate(:page => params[:page], :per_page => 15)
    @job_image_names_with_eobs = {}
    if @jobs.length > 0
      job_ids = @jobs.map(&:id)
      @job_image_names_with_eobs = get_jobs_with_processed_eobs_and_images(job_ids)
    end
  end

  def get_jobs_with_processed_eobs_and_images(job_ids)
    image_page_number_from_eobs, job_image_names_with_eobs = {}, {}
    if job_ids.length > 0
      jobs_with_processed_eobs_and_images = Job.select("jobs.id AS id, images_for_jobs.image_file_name, images_for_jobs.image_number,
       insurance_payment_eobs.image_page_no, insurance_payment_eobs.image_page_to_number").
        joins("
      INNER JOIN check_informations ON check_informations.job_id = jobs.id
      INNER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id
      INNER JOIN client_images_to_jobs ON client_images_to_jobs.job_id = jobs.id
      INNER JOIN images_for_jobs ON images_for_jobs.id = client_images_to_jobs.images_for_job_id").
        where(:id => job_ids)
      if jobs_with_processed_eobs_and_images.length > 0
        image_page_number_from_eobs, job_image_names_and_image_page_numbers = get_image_page_number_and_name_from_eobs_jobs(jobs_with_processed_eobs_and_images)
        job_image_names_with_eobs = get_job_image_names_with_eobs(image_page_number_from_eobs, job_image_names_and_image_page_numbers)
      end
    end
    job_image_names_with_eobs
  end

  def get_image_page_number_and_name_from_eobs_jobs(jobs_with_processed_eobs_and_images)
    job_image_names_and_image_page_numbers, image_page_number_from_eobs = {}, {}
    if jobs_with_processed_eobs_and_images.length > 0
      jobs_with_processed_eobs_and_images.each do |job|
        job_image_names_and_image_page_numbers[job.id] = [] if job_image_names_and_image_page_numbers[job.id].blank?
        job_image_names_and_image_page_numbers[job.id] << [job.image_file_name, job.image_number]
        image_page_number_from_eobs[job.id] = [] if image_page_number_from_eobs[job.id].blank?
        image_page_number_from_eobs[job.id] << job.image_page_no << job.image_page_to_number
      end
    end
    return image_page_number_from_eobs, job_image_names_and_image_page_numbers
  end

  def get_job_image_names_with_eobs(image_page_number_from_eobs, job_image_names_and_image_page_numbers)
    job_image_names_with_eobs = {}
    job_image_names_and_image_page_numbers.each do |job_id, image_names_and_image_page_numbers|
      image_names_and_image_page_numbers.each do |image_name_and_image_page_number|
        image_name = image_name_and_image_page_number[0]
        image_page_number = image_name_and_image_page_number[1]
        image_page_number_from_eobs[job_id] = image_page_number_from_eobs[job_id].uniq
        if image_page_number_from_eobs[job_id].include?(image_page_number)
          job_image_names_with_eobs[job_id] = [] if job_image_names_with_eobs[job_id].blank?
          job_image_names_with_eobs[job_id] << image_name
        end
      end
    end
    if job_image_names_with_eobs.present?
      job_image_names_with_eobs.each do |job_id, image_name_array|
        image_name_array = image_name_array.uniq.join(',')
        job_image_names_with_eobs[job_id] = image_name_array
      end
    end
  end

  def remove_jobs_from_additional_job_request_queue
    if params[:job_ids_to_remove].present?
      job_ids = params[:job_ids_to_remove]
      jobs = Job.where(:id => job_ids)
      processor_ids = jobs.map(&:processor_id)
      online_user_ids, offline_user_ids, offline_user_logins = User.get_online_and_not_idle_and_idle_users(processor_ids)
      set_jobs_to_online_users(job_ids, online_user_ids)
      make_jobs_free_from_offline_users(job_ids, offline_user_logins, offline_user_ids)
    end
    redirect_to :action => 'additional_job_request_queue', :page => params[:page]
  end
  
  private

  def set_jobs_to_online_users(job_ids, online_user_ids)
    if online_user_ids.present?
      Job.where(:id => job_ids, :processor_id => online_user_ids).update_all(:job_status => JobStatus::PROCESSING,
        :processor_status => ProcessorStatus::ALLOCATED, :updated_at => Time.now)
    end
  end

  def make_jobs_free_from_offline_users(job_ids, offline_user_logins, offline_user_ids)
    if offline_user_logins.present? && offline_user_ids.present?
      offline_user_logins = offline_user_logins.join(', ')
      flash[:notice] = "The following users are offline or idle. Please do manual allocation for the jobs associated with them : #{offline_user_logins}"
      Job.where(:id => job_ids, :processor_id => offline_user_ids).update_all(:job_status => JobStatus::NEW,
        :processor_status => ProcessorStatus::NEW, :processor_id => nil, :updated_at => Time.now)
    end
  end

  # Builds the job, check and micr_line objects
  # from the temporary job object supplied
  # returns ready to be saved job object with associated check and micr_line objects
  def prepare_job_and_associations
    temp_job = @temp_job
    payer_group = '--'
    @original_job = Job.includes(:images_for_jobs).find(temp_job.job_id)
    @micr_record, payer_group = get_micr_and_payer_group if @original_job.micr_applicable?

    job = prepare_job
    job.payer_group = payer_group
    job.is_correspondence = @original_job.is_correspondence

    check_information = prepare_check
    job.check_informations << check_information
    check_information.micr_line_information = @micr_record if @micr_record

    Batch.where(:id => @original_job.batch_id).update_all(:associated_entity_updated_at => Time.now)
    job
  end

  def get_micr_and_payer_group
    temp_job = @temp_job
    micr_record = MicrLineInformation.find_or_create_by_aba_routing_number_and_payer_account_number(
      temp_job.aba_number, temp_job.account_number)
    micr_has_payer = (micr_record.present? && !micr_record.payer.blank?)
    payer_group = (micr_has_payer ? micr_record.payer.get_payer_group : '--')
    return micr_record, payer_group
  end

  def prepare_job
    temp_job = @temp_job
    job = Job.new({batch_id: @original_job.batch_id,
        check_number: temp_job.check_number,
        payer_id: @original_job.payer_id,
        image_count: temp_job.image_count,
        pages_from: '1',
        pages_to: temp_job.image_count + 1,
        split_parent_job_id: temp_job.job_id,
        created_at: temp_job.created_at,
        updated_at: temp_job.updated_at})
    job.estimated_eob = job.estimated_no_of_eobs(job.pages_to, @micr_record, temp_job.check_number)
    job
  end

  def prepare_check
    temp_job = @temp_job
    CheckInformation.new({check_number: temp_job.check_number,
        check_amount: temp_job.check_amount,
        transaction_id: @original_job.check_informations.first.transaction_id,
        index_file_check_amount: 0})
  end

  def get_selected_images
    temp_job = @temp_job
    original_images = @original_job.images_for_jobs
    selected_image_from = original_images.select{ |j| j.image_file_name.include?temp_job.image_from }
    unless selected_image_from.empty?
      images_starting_seq = selected_image_from[0].image_number
      images_ending_seq = images_starting_seq + temp_job.image_count - 1
      original_images.select{|j| (images_starting_seq .. images_ending_seq).include?j.image_number}
    else
      []
    end
  end

  def reassociate_images_and_save_child_and_parent_job
    proceed = false
    selected_image_ids, original_image_ids = [], []
    selected_images = get_selected_images
    original_images = @original_job.images_for_jobs
    unless selected_images.blank? || original_images.blank?
      selected_image_ids = selected_images.map{|i| i.id}
      original_image_ids = original_images.map{|i| i.id}
      proceed = true
    end
    if proceed && selected_images_valid?(original_image_ids, selected_image_ids)
      unless selected_images.blank?
        reassociate_images(selected_images)
        compute_initial_image_name if @original_job.initial_image_name.present?
        process_ocr_job_images(original_image_ids, selected_image_ids) if @original_job.is_ocr == "OCR"
      end
      newly_created_job = true if @new_job.id.nil?
      online_user_ids, offline_user_ids, offline_user_logins = User.get_online_and_not_idle_and_idle_users([@original_job.processor_id])
      set_job_and_processor_details(offline_user_logins)
      if @new_job.save && @original_job.save
        flash[:notice] = "Successfully Saved."
        if offline_user_logins.present?
          flash[:notice] += "The processor with login #{offline_user_logins.join(',')} already allocated is offline or idle. Please reallocate manually."
        end
        @temp_job.destroy
        image_names = selected_images.map(&:image_file_name).join(', ')
        log_job_activity(image_names) if newly_created_job
      else
        flash[:notice] = "#{@new_job.errors.full_messages.join(', ')}"
      end
    else
      flash[:notice] = "Something went wrong while assigning images"
    end
  end

  def set_job_and_processor_details(offline_user_logins)
    if @original_job.job_status == JobStatus::ADDITIONAL_JOB_REQUESTED
      if offline_user_logins.present?
        @original_job.job_status = JobStatus::NEW
        @original_job.processor_id = nil
        @original_job.processor_status = ProcessorStatus::NEW
      else
        @original_job.job_status = JobStatus::PROCESSING
        @job_processing_status_validity = true
        @original_job.processor_status = ProcessorStatus::ALLOCATED
      end
    end
  end

  def selected_images_valid?(original_image_ids, selected_image_ids)
    if selected_image_ids == original_image_ids
      flash[:notice] = "New job cannot have all the images of parent job."
      false
    else
      true
    end
  end

  def reassociate_images(selected_images)
    selected_image_ids = selected_images.map{|i| i.id}
    remaining_images = @original_job.images_for_jobs.reject{ |i| selected_image_ids.include?i.id }
  
    @new_job.images_for_jobs = selected_images
    @new_job.pages_from = 1
    @new_job.pages_to = selected_images.length
    @new_job.is_ocr = @original_job.is_ocr
    ImagesForJob.reset_page_numbers_of_images(@new_job.images_for_jobs)

    @original_job.images_for_jobs = remaining_images
    @original_job.pages_from = 1
    @original_job.pages_to = remaining_images.length
  end

  def compute_initial_image_name
    original_job_initial_image_name = @original_job.images_for_jobs.first.exact_file_name
    job_count = Job.where( :split_parent_job_id => @original_job.id ).count

    @new_job.initial_image_name = @original_job.initial_image_name.reverse.sub(".",".#{job_count+1}N_").reverse
    @original_job.initial_image_name = original_job_initial_image_name
  end

  def process_ocr_job_images(original_image_ids, selected_image_ids)
    pages = original_image_ids.each.with_index.find_all{|value,index| selected_image_ids.include?value}.map{|a,b| b+1}
    update_insurance_eob_svc(pages)
  end

  def update_insurance_eob_svc(pages_remaining)
    pages_index ={}
    pages_remaining.each_with_index {|value, index| pages_index[value] = ((index+1).to_s)}
    pages_string =  pages_remaining.join(',')
    check_id = CheckInformation.find_by_job_id("#{@original_job.id}").id
    new_check_id = @new_job.check_informations.first.id
    eobs = InsurancePaymentEob.where("check_information_id = '#{check_id}' AND image_page_no IN(#{pages_string})" ).includes(:service_payment_eobs)
    eobs.each do|eob|
      eob.details.select{|key,value| (key.to_s.include?("_page"))}.each{|key,value| eob.details[key] = pages_index[value.to_i]}
      eob.check_information_id = new_check_id
      eob.sub_job_id = @new_job.id
      image_page = eob.image_page_no
      eob.image_page_no = pages_index[image_page].to_i
      eob.save
      svcs = eob.service_payment_eobs
      svcs.each do |svc|
        svc.details.select{|key,value| (key.to_s.include?("_page"))}.each{|key,value| svc.details[key] = pages_index[value.to_i]}
        svc.save
      end
    end
  end

  def log_job_activity(image_names)
    JobActivityLog.create_activity({:job_id => @new_job.id, :allocated_user_id => @current_user.id,
        :activity => 'Job Created', :start_time => Time.now, :object_name => 'jobs',
        :object_id => @new_job.id, :field_name => 'check_number', :new_value => @new_job.check_number })
    JobActivityLog.create_activity({:job_id => @original_job.id,
        :allocated_user_id => @current_user.id,
        :activity => 'Images Are Removed', :start_time => Time.now,
        :object_name => 'jobs', :object_id => @original_job.id,
        :field_name => 'images', :old_value => image_names})
  end
  
  def get_images
    @temp_jobs = TempJob.where(:job_id => @job_information.id)
    temp_job_image_ids = TempJob.get_image_ids(@job_information.id) if @temp_jobs.present?
    @images = @job_information.images_for_jobs.sort{|a,b| a.image_number <=> b.image_number}
    @images = @images.reject{|img| temp_job_image_ids.include?img.id} if temp_job_image_ids.present?
  end

  def transfer_images_to_parent(job_to_delete)
    success = false
    images_ids = job_to_delete.images_for_jobs.map(&:id)
    original_job = Job.find(job_to_delete.split_parent_job_id)
    original_job.set_image_numbers(images_ids)
    success = ClientImagesToJob.where(:images_for_job_id => images_ids).
      update_all(:job_id => original_job.id, :updated_at => Time.now)
    success &&= Batch.where(:id => original_job.batch_id).
      update_all(:associated_entity_updated_at => Time.now) if success
    original_job_image_count = ClientImagesToJob.where(:job_id => original_job.id).count
    original_job.pages_to = original_job.pages_from + original_job_image_count - 1
    success &&= original_job.save if success
    success
  end

  def job_id_collection_valid?(jobs)
    valid = false
    unless jobs.blank?
      if jobs.class == ActiveSupport::HashWithIndifferentAccess
        jobs.delete_if do |key, value|
          value == "0"
        end
      end
      if jobs.size == 0
        flash[:notice] = "Please select atleast one job to delete"
      else
        valid = true
      
      end
    else
      flash[:notice] = "No jobs in the list"
    end
    valid
  end

  def is_job_valid?
    valid = false
    if @jobs.length > 1
      flash[:notice] = "Please select only one job"
    elsif @jobs.length == 0
      flash[:notice] = "Please select at least one job"
    elsif @jobs.length == 1
      job = Job.find(@jobs.first)
      valid = validate_based_on_facility(job)
      valid &&= validate_based_on_job_meta(job)
    end
    valid
  end

  def validate_based_on_facility(job)
    facility = job.batch.facility
    if facility.new_job_creation_applicable
      true
    else
      flash[:notice] = "New job creation is disabled for this facility"
      false
    end
  end

  def validate_based_on_job_meta(job)
    valid = false
    if job.original_job_id.present?
      flash[:notice] = "Derived job cannot be split further"
    elsif job.images_for_jobs.empty?
      flash[:notice] = "New jobs cannot be created from this job as it has no images"
    else
      valid_statuses = [JobStatus::NEW, JobStatus::ADDITIONAL_JOB_REQUESTED]
      count_of_eobs = InsurancePaymentEob.where(:sub_job_id => job.id).count if !flash[:job_processing_status_validity]
      if flash[:job_processing_status_validity] || count_of_eobs.zero?
        valid_statuses << JobStatus::PROCESSING
      end
      if not valid_statuses.include?(job.job_status)
        flash[:notice] = "Only new jobs can be split"
      else
        valid = true
      end
    end
    valid
  end

  def is_eligible_for_delete(job)
    valid_statuses = [JobStatus::NEW, JobStatus::ADDITIONAL_JOB_REQUESTED]
    if job.original_job_id.present?
      if valid_statuses.include?(job.job_status)
        true
      else
        flash[:notice] = "Unprocessed jobs can only be deleted"
        false
      end
    else
      flash[:notice] = "Original job cannot be deleted"
      false
    end
  end
  
  def redirect_to_prev_page
    redirect_to :back, :flash => {:job_processing_status_validity => @job_processing_status_validity}
  end

  def get_file_names_corr_to_pages(image_path, pages)
    file_names = []
    pages.each do |page|
      page_str = "%03d" % (page - 1).to_s
      file_names << "#{image_path}_s_#{page_str}*"
    end
    file_names
  end
   
  # For admin/supervisor to incomplete jobs
  def incomplete

  end
  
  #This is for removing file extension.
  def remove_file_extension(filename)
    extensions = ["TIF", "TIFF", "JPEG", "JPG", "PDF"]
    original_file_extension = filename.split('.').last
    if extensions.include?(original_file_extension.upcase)
      unwanted_string = "."+original_file_extension
      filename = filename.chomp(unwanted_string)
    end
    filename
  end

  def prepare
    @job = Job.find(params[:id])
    @batch = @job.batch
    @facility = @batch.facility
    @check_information = @job.check_information
    @micr_line_info = @check_information.micr_line_information
    @is_micr_configured = @facility.details[:micr_line_info]
  end

  #  This Method will return true if both aba_routing_number and payer_account_number
  #  contains no hyphen. If any of this data has a hyphen in it , then this
  #  method will return false.
  def hyphen_absent?
    aba_routing_no_frm_db_with_hyphen = @micr_line_info.aba_routing_number.match(/[\-]/)
    payer_account_no_frm_db_with_hyphen = @micr_line_info.payer_account_number.match(/[\-]/)
    hyphen_absent = aba_routing_no_frm_db_with_hyphen == nil &&
      payer_account_no_frm_db_with_hyphen == nil
  end

  def valid_corr_check_number?
    check_number = @check_information.check_number
    valid_corr_check_number = check_number.to_i.zero? && check_number.to_s.squeeze == "0"
  end

end
