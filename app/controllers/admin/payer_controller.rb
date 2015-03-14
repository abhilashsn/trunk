# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
class Admin::PayerController < ApplicationController
  include Admin::PayerHelper
  before_filter :prepare
  require 'csv'
  require 'will_paginate/array'

  layout "standard", :except => [:display_image]
  require_role ["admin","qa","processor","manager","supervisor","TL"]
  auto_complete_for :payer, :payer

  def list_build_condition
    conditions = frame_payer_criteria
    return conditions
  end
  
  def prepare
    @db_clients = Client.find(:all)
    @clients = @db_clients.collect {|p| [p.name ,p.id]}
    @is_partner_bac = $IS_PARTNER_BAC
    activity = JobActivityLog.new
    activity.current_user_id = current_user.id if current_user
  end


  def list_new_payers
    @access_condition = current_user.has_role?(:supervisor) ||
      current_user.has_role?(:admin) || current_user.has_role?(:manager)
    new_payer_condition = " payers.status in ('#{Payer::NEW}', '#{Payer::CLASSIFIED}', '#{Payer::CLASSIFIED_BY_DEFAULT}' )"
    new_micr_condition =  " micr_line_informations.status = '#{MicrLineInformation::NEW}' "
    processing_job_condition = "jobs.job_status = '#{JobStatus::PROCESSING}' OR jobs.job_status = '#{JobStatus::ADDITIONAL_JOB_REQUESTED}'"
    conditions = "(#{new_payer_condition} || #{new_micr_condition})"
    
    if !params[:to_find].blank? && !params[:criteria].blank?
      conditions =  frame_payer_criteria(conditions)
    end
    per_page = params[:per_page]
    per_page ||= 30
    
    unless conditions.blank?
      @new_payers = Payer.find(:all,
        :select => " payers.id as id\
                    , payers.status as status \
                    , payers.batch_target_time as batch_target_time \
                    , payers.payer as payer \
                    , payers.payid as payid \
                    , payers.payer_type as payer_type \
                    , payers.pay_address_one as pay_address_one \
                    , payers.pay_address_two as pay_address_two \
                    , payers.payer_city as payer_city \
                    , payers.payer_state as payer_state \
                    , payers.payer_zip as payer_zip \
                    , payers.footnote_indicator as footnote_indicator \
                    , micr_line_informations.id as micr_id \
                    , micr_line_informations.status as micr_status \
                    , micr_line_informations.payid_temp as temp_payid \
                    , micr_line_informations.aba_routing_number as aba_no \
                    , micr_line_informations.payer_account_number as payer_acc_no,
                      (CASE WHEN #{!$IS_PARTNER_BAC} || payers.status = 'MAPPED' ||
                       payers.payer_type = '#{Payer::COMMERCIAL}' ||
                       payers.payer_type = '#{Payer::PATPAY}'
                       THEN payers.payid ELSE micr_line_informations.payid_temp END) AS exact_payid",
        :conditions => conditions,
        :joins => "LEFT OUTER JOIN micr_line_informations ON payers.id = micr_line_informations.payer_id \
               INNER JOIN check_informations ON check_informations.payer_id = payers.id",
        :group => "id, micr_id",
        :order => "payers.batch_target_time asc").paginate(:page => params[:page], :per_page => per_page.to_i)

    end
    @payer_ids_under_processing = Payer.find(:all, :select => "payers.id",
      :conditions => "#{new_payer_condition} AND #{processing_job_condition}",
      :joins => "INNER JOIN check_informations ON check_informations.payer_id = payers.id \
              INNER JOIN jobs ON jobs.id = check_informations.job_id")
    @payer_ids_under_processing = @payer_ids_under_processing.uniq
  end

  def export_to_csv
    @message = "This is an offline operation. Please contact HelpDesk - DBA Support to get the payer data."
  end

  def index
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    if search_field.blank?
      #@micrs = MicrLineInformation.paginate(:all,  :conditions => " payers.id = micr_line_informations.payer_id AND
      #(payers.status = 'MAPPED' OR payers.status = 'UNMAPPED') ", :include=>[:payer],:per_page=>30, :page=> params[:page])
      @payers = Payer.joins("LEFT JOIN micr_line_informations m ON payers.id = m.payer_id").where("payers.status='MAPPED' OR payers.status='APPROVED'").select("payers.*, m.aba_routing_number, m.payer_account_number, m.id as micr_id").paginate(:per_page=>30, :page=>params[:page])

    else
      #@micrs = MicrLineInformation.paginate(:all, :conditions => " #{list_build_condition} AND payers.id = micr_line_informations.payer_id AND
      #                                  (payers.status = 'MAPPED' OR payers.status = 'UNMAPPED') ",:include=>[:payer],:per_page=>30, :page=> params[:page])

      @payers = Payer.joins("LEFT JOIN micr_line_informations m ON payers.id = m.payer_id").
        where(" #{list_build_condition} AND (payers.status = 'MAPPED' OR payers.status = 'APPROVED')").
        select("payers.*, m.aba_routing_number, m.payer_account_number, m.id as micr_id").paginate(:per_page=>30, :page=>params[:page])
    end
  end

  def list_approved_payers
    conditions = " (micr_line_informations.id IS NULL OR micr_line_informations.status = '#{MicrLineInformation::APPROVED}') && payers.status in ('APPROVED', 'UNMAPPED', 'MAPPED') && payers.active != 0"
    
    if !params[:to_find].blank? && !params[:criteria].blank?
      conditions = frame_payer_criteria(conditions)
    else
      conditions += " && payers.payer_type != '#{Payer::PATPAY}'"
    end

    @approved_payers = Payer.find(:all,:select => "distinct payers.id AS id,payers.payer AS payer,
                   payers.era_payer_name as era_payer_name,
                   payers.payid AS payid, payers.payer_type AS payer_type,
                   payers.pay_address_one AS pay_address_one, 
                   payers.pay_address_two AS pay_address_two,
                   payers.payer_city AS payer_city, payers.payer_state AS payer_state,
                   payers.payer_zip AS payer_zip, payers.company_id AS company_id,
                   payers.footnote_indicator AS footnote_indicator,
                   payers.eobs_per_image AS eobs_per_image,
                   payers.status AS status, reason_code_set_names.name AS rc_set_name,
                   micr_line_informations.id AS micr_id,
                   micr_line_informations.aba_routing_number AS aba_routing_number,
                   micr_line_informations.payer_account_number AS payer_account_number,
                   (CASE WHEN #{!$IS_PARTNER_BAC} || payers.status = 'MAPPED' ||
                       payers.payer_type = '#{Payer::COMMERCIAL}' ||
                       payers.payer_type = '#{Payer::PATPAY}'
                       THEN payers.payid ELSE micr_line_informations.payid_temp END) AS exact_payid",
      :conditions => conditions,
      :joins => "LEFT OUTER JOIN micr_line_informations ON payers.id = micr_line_informations.payer_id
                    INNER JOIN reason_code_set_names ON payers.reason_code_set_name_id = reason_code_set_names.id",
      :order => "payers.batch_target_time asc").paginate(:page => params[:page], :per_page => 30)
  end

  def filter_payers(field, comp, search, act)
    flash[:notice] = nil
    case field
    when 'Date Added'
      if search !~ /\d{4}-\d{2}-\d{2}/ then @flag_incorect_date = 0; end
      payers = Payer.find(:all, :conditions => "date_added #{comp} '#{search}'")
    when 'Initials'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "initials like '%#{search}%'")
    when 'From Date'
      if search !~ /\d{4}-\d{2}-\d{2}/ then @flag_incorect_date = 0; end
      payers = Payer.find(:all, :conditions => "from_date #{comp} '#{search}'")
    when 'Gateway'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "gateway like '%#{search}%'")
    when 'Payer Id'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "payid like '%#{search}%'")
    when 'Payer'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "payer like '%#{search}%'")
    when 'Address-1'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "pay_address_one like '%#{search}%'")
    when 'Address-2'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "pay_address_two like '%#{search}%'")
    when 'Address-3'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "pay_address_three like '%#{search}%'")
    when 'Phone'
      flash[:notice] = "String search, '#{comp}' ignored."
      payers = Payer.find(:all, :conditions => "phone like '%#{search}%'")
    end
    if @flag_incorect_date == 0
      flash[:notice] = "Invalid Date format. Please re-enter! Format - DATE : yyyy-mm-dd"
      if act == 'select'
        redirect_to :action => 'payer_selection'
      else
        redirect_to :action => 'index'
      end
    elsif payers.size == 0
      flash[:notice] = "Search for \"#{search}\" did not return any results. Try another keyword!"
      if act == 'select'
        redirect_to :action => 'payer_selection'
      else
        redirect_to :action => 'index'
      end
    end
    return payers
  end
  
  def list_payers_processor
    @payer_pages, @payers = paginate :payers, :per_page => 1
  end
  
  def show
    @payer = Payer.find(params[:id])
  end

  def new
    find_realtive_url
    @payer = Payer.new
    @payid = ''
    @payer_name = params[:payer]
    @readonly_payid = false
    @footnote_indicator = false
    @payer_type = 'Insurance'
    @rc_set_name = ''
    @facilty_ids_of_client_specific_payer_details = ''
    @facilty_ids_of_payment_or_allowance_codes = ''
    @payer_id = ''
  end

  def get_facility_for_output_payid_and_onbase_name
    @facilities = Facility.find(:all ,:conditions => ["client_id =?", params[:id]], :order => "name ASC").collect {|p| [p.name ,p.id]}
    render :partial => "show_facility"
  end

  def get_facility_for_payment_and_allowance_code
    @facilities = Facility.find(:all ,:conditions => ["client_id =?", params[:id]], :order => "name ASC").collect {|p| [p.name ,p.id]}
    render :partial => "show_facility_for_codes"
  end
  
  def get_facility
    @facilities = Facility.find(:all ,:conditions => ["client_id =?", params[:id]], :order => "name ASC").collect {|p| [p.name ,p.id]}
    @name = params[:name]
    render :update do |page|
      if @name == "client_specific_payer_details"
        page.replace_html "facility_span", :partial => "show_facility"
      elsif @name == 'plan_type_facilities'
        page.replace_html 'plan_type_facility_span', :partial => 'show_plan_type_facility'
      else
        page.replace_html "facility_span_of_payment_or_allowance_code" ,:partial => "show_facility_for_codes"
      end
    end
  end

  def get_facility_for_client
    client_name = params[:client_name]
    if !client_name.blank?
      client_array = Client.select("id").where("name = ?", client_name)
      client = client_array.first if !client_array.blank?
      if !client.blank?
        facilities = Facility.select("name").where("client_id = ?", client.id)
        @facilities = facilities.collect {|f| [f.name, f.name]} if !facilities.blank?
        @index = params[:index]
        @name = params[:name]
        render :update do |page|
          page.replace_html "output_payid_#{@index}_facility" ,:partial => "show_facility"
        end
      end
    end
  end
  
  def create
    result, error_message = save_payer_and_its_related_attributes
    
    if !result
      flash[:notice] = error_message
      render :action => 'new'
    else
      unless params[:payer][:company_id] == nil
        CrTransaction.update_payer_status(params[:payer][:company_id])
      end
      flash[:notice] = 'Payer Successfully inserted'
      redirect_to :action => 'list_approved_payers'
    end
  end
  
  def edit
    @payer = Payer.find(params[:id])
    @facility_plan_types = FacilityPlanType.includes(:facility, :client).where(:payer_id => @payer.id)
    @payid = @payer.supply_payid
    @payer_name = @payer.payer
    @era_payer_name = @payer.era_payer_name
    @micr_line_information = MicrLineInformation.find(params[:micr_id]) if !params[:micr_id].blank?
    @payer_id = @payer.id
    collect_payer_data
    @flag = params[:flag]
  end
  
  def update
    result, error_message = save_payer_and_its_related_attributes
    page = params[:page].blank? ? '1' : params[:page]
    if !result
      flash[:notice] = error_message
      if params[:from] == 'approve_payer'
        to_action = 'approve_payer'
      else
        to_action = 'edit'
      end
      redirect_to :action => to_action, :id => params[:id], :micr_id => params[:micr_id], :page => page
    else
      flash[:notice] = error_message
      if params[:from] == 'approve_payer'
        to_action = 'list_new_payers'
      else
        to_action = 'list_approved_payers'
      end
      redirect_to :action => to_action, :page => page
    end
  end

  def approve_payer
    @payer = Payer.find(params[:id])
    @payer_name = @payer.payer
    @micr_line_information = MicrLineInformation.find(params[:micr_id]) if !params[:micr_id].blank?
    collect_payer_data
    @check_number_and_job_ids = []
    checks = @payer.check_informations
    checks = checks.reverse
    if !checks.blank?
      count_of_checks = 0
      checks.each do |check|
        @check_number_and_job_ids << [check.check_number, check.job_id]
        count_of_checks += 1
        break if count_of_checks == 10
      end
    end
    @payer_id = @payer.id
    if(@payer.supply_payid == 'D9998' && @payer.payer_type == Payer::COMMERCIAL)
      @rc_set_name = ''
      @payid = ''
    else
      @payid =  @payer.supply_payid
    end
    @page = params[:page]
  end

  def map_payer
    @payer = Payer.find(params[:id])
    @approved_payer = Payer.find(params[:old_payer_id])
    if(@payer.footnote_indicator == @approved_payer.footnote_indicator)
      @payer.replacement_payer_id = @approved_payer.id
      @payer.active = 0
      new_set_name = @approved_payer.reason_code_set_name
      success = @payer.clean_up_the_rcs_if_set_name_has_changed(new_set_name)
      if success && !new_set_name.blank?
        @payer.reason_code_set_name_id = new_set_name.id
        @payer.payid = @approved_payer.payid
      end
      success = @payer.save
    end
    if success
      @payer.check_informations.update_all(:payer_id => @approved_payer.id,:original_payer_id => @payer.id, :updated_at => Time.now)
      @payer.micr_line_informations.update_all(:payer_id => @approved_payer.id,:original_payer_id => @payer.id, :updated_at => Time.now)
      ActivityLog.create(:object_id => @payer.id,:action => "Payer is mapped to #{@approved_payer.id}",:actor_id => current_user.id)

      redirect_to :action => 'list_approved_payers'
    end
  end


  def collect_payer_data
    find_realtive_url
    @readonly_payid = readonly_payid_conditions_for_payer_administarion
    @payer_type = (@payer.payer_type == Payer::PATPAY)? "PatPay" : "Insurance"
    @footnote_indicator = @payer.footnote_indicator
    
    unless @payer.plan_type.blank?
      payer_type_list.each do |type|
        @plan_type = type if( type =~ /#{@payer.plan_type}/ )
      end
    end

    unless @micr_line_information.blank?
      @onbase_name_records = FacilitiesMicrInformation.get_onbase_name_record_for_all_levels(@micr_line_information.id)
      @onbase_name_client_and_facility_ids = ""
      @onbase_name_records.each do |onbase_name_record|
        @onbase_name_client_and_facility_ids  << ",#{onbase_name_record.client_id}:#{onbase_name_record.facility_id}"
      end
    end

    @facilities_payers_information = FacilitiesPayersInformation.select("
      facilities_payers_informations.in_patient_payment_code AS in_patient_payment_code,
      facilities_payers_informations.out_patient_payment_code AS out_patient_payment_code,
      facilities_payers_informations.out_patient_allowance_code AS out_patient_allowance_code,
      facilities_payers_informations.in_patient_allowance_code AS in_patient_allowance_code,
      facilities_payers_informations.capitation_code AS capitation_code,
      facilities_payers_informations.id AS id,
      facilities_payers_informations.facility_id AS facility_id,
      clients.name AS client_name,
      facilities.name AS facility_name").
      joins("INNER JOIN facilities ON facilities.id = facilities_payers_informations.facility_id
      INNER JOIN clients ON clients.id = facilities.client_id").
      where("payer_id = #{@payer.id} AND (in_patient_payment_code IS NOT NULL OR
            out_patient_payment_code IS NOT NULL OR out_patient_allowance_code IS NOT NULL OR
            in_patient_allowance_code IS NOT NULL OR capitation_code IS NOT NULL)")

    facilty_ids_of_payment_or_allowance_codes = []
    @facilities_payers_information.each do |facility_payer_info|
      facilty_ids_of_payment_or_allowance_codes << facility_payer_info.facility_id
    end
    @facilty_ids_of_payment_or_allowance_codes = (facilty_ids_of_payment_or_allowance_codes.blank? ? '' : facilty_ids_of_payment_or_allowance_codes.join(','))
    
    @output_payid_records = FacilitiesPayersInformation.get_output_payid_record_for_all_levels(@payer.id)
    @output_payid_client_and_facility_ids = ""
    @output_payid_records.each do |output_payid_record|
      @output_payid_client_and_facility_ids  << ",#{output_payid_record.client_id}:#{output_payid_record.facility_id}"
    end
    #For Quadax client only
    clients_with_output_payid_mandatory = []
    clients_with_output_payid_mandatory << Client.where(:is_output_payid_mandatory => true).collect(&:id)
    @clients_with_output_payid_mandatory = clients_with_output_payid_mandatory.flatten
    blank_output_payid_records = FacilitiesPayersInformation.get_blank_output_payid_record_for_all_levels(@payer.id)
    @blank_output_payid_records = blank_output_payid_records.select{|output_payid_record| @clients_with_output_payid_mandatory.include?(output_payid_record.client_id)}
    @blank_output_payid_records_array = @blank_output_payid_records.collect(&:id).join(",")
    payer_specific_records = FacilitiesPayersInformation.get_payer_specific_records(@payer.id)
    @payer_specific_records = payer_specific_records.select{|payer_specific_record| @clients_with_output_payid_mandatory.include?(payer_specific_record.client_id)}
    @payer_specific_records_array = @payer_specific_records.collect(&:id).join(",")
    set_name = @payer.reason_code_set_name
    @rc_set_name = set_name.name if !set_name.blank?
  end
  
  def display_image
    @payer = Payer.find(params[:id])
    if !params[:job_id].blank?
      job = Job.find(params[:job_id])
    else
      check = CheckInformation.find_last_by_payer_id(@payer.id)
      if !check.blank?
        job = check.job
      end
    end
    if !job.blank?
      @job = job
      parent_job_id = job.parent_job_id
      if !parent_job_id.blank?
        @parent_job = check.job
      end
      facility_image_type = job.batch.facility.image_type
      get_images(job.parent_job_id, facility_image_type, job.id)
    end
  end

  def approve_patient_payers
    payer_ids, micr_ids = [], []
    if !params[:verify_patpay_payer].blank?
      params[:verify_patpay_payer].each do |payer_id_and_micr_id, selected|
        if selected == '1'
          payer_id_and_micr_id_array = payer_id_and_micr_id.to_s.split('_')
          payer_ids << payer_id_and_micr_id_array[0].to_s if !payer_id_and_micr_id_array[0].blank?
          micr_ids << payer_id_and_micr_id_array[1].to_s  if !payer_id_and_micr_id_array[1].blank?
        end
      end
      payer_ids = payer_ids.uniq.compact
      micr_ids = micr_ids.uniq.compact
      if !payer_ids.blank?
        Payer.where(:id => payer_ids).update_all(:status => "#{Payer::MAPPED}", :updated_at => Time.now)

        job_activities =[]
        payer_ids.each do |payer_id|
          job_activities << JobActivityLog.create_activity({:allocated_user_id => @current_user.id,
              :activity => 'Payer Approved', :start_time => Time.now,
              :object_name => 'payers', :object_id => payer_id,
              :field_name => 'status', :old_value => Payer::NEW, :new_value => Payer::MAPPED}, false)
        end
        JobActivityLog.import job_activities if !job_activities.blank?
      end
      if !micr_ids.blank?
        MicrLineInformation.where(:id => micr_ids).update_all(:status => "#{MicrLineInformation::APPROVED}", :updated_at => Time.now)
      end
      flash[:notice] = "Selected patient payers are approved."
    end
    redirect_to :action => 'list_new_payers'
  end
  
  def delete_payers_OLD
    # Shamnath/KK on OCT 1/2011, said this functioality is not currently working
    # any way this have to be remplimented @Geegee

    # TODO: Messy way to handle multiple checkboxes from the view
    payers = params[:payers_to_delete]
    deleted_payer_names, referenced_payer_names = [],[]
    flash[:notice] = ''
    payers.delete_if do |key, value|
      value == "0"
    end
    payers.keys.each do |id|
      payer = Payer.find(id)
      # get the first check associated with this payer
      check = CheckInformation.find_by_payer_id(id)
      # check if it is a 'No Payer', used by all the jobs
      no_payer = (payer.payer == "No Payer" && payer.supply_payid == "No Payer" && payer.id == 1)

      # do not allow an already associated payer's delete
      if (check.nil? && !no_payer)
        reason_codes = payer.reason_codes
        #Deleting MICR data
        micr_line_informations = payer.micr_line_informations
        reason_codes.destroy_all
        micr_line_informations.destroy_all
        payer.destroy
        deleted_payer_names << payer.payer
      elsif no_payer
        flash[:notice] += " #{payer.payer} cannot be deleted as it is the default payer for jobs."
      else
        referenced_payer_names << payer.payer
      end
    end
    if payers.size == 0
      flash[:notice] = "Please select atleast one payer to delete"
    end
    if not deleted_payer_names.empty?
      flash[:notice] +=  " #{deleted_payer_names.size} payer(s) have been deleted"
    end
    if not referenced_payer_names.empty?
      str = (referenced_payer_names.size > 1 ? 'are' : 'is')
      flash[:notice] += " #{referenced_payer_names.join(',')} #{str} associated with one or more checks and cannot be deleted."
    end
    redirect_to :action => 'index'
  end
  
  def destroy
    Payer.destroy params[:id]
    redirect_to :action => 'index'
  end
  
  def manage_newly_added_codes
    @filter_hash = params[:filter_hash]
    @field_options = ['', 'Batch Date', 'Batch ID', 'Check Number',
      'Facility Name', 'Payer Name', 'Paper Code', 'Paper Code Description']
    initial_condition = "reason_codes.status = 'New' AND reason_codes.marked_for_deletion = 0 AND reason_codes.active = 1 AND reason_codes.payer_name IS NOT NULL"

    condition_string, condition_values = frame_conditions_from_filter(initial_condition)

    @newly_added_payer_codes = ReasonCode.select("reason_codes.id AS reason_code_id, \
      reason_codes.check_number AS check_number, reason_codes.reason_code, \
      reason_codes.reason_code_description, reason_codes.payer_name, rcc.id AS rcc_id,\
      reason_codes.job_id AS job_id, reason_codes.facility_name AS facility_name, \
      reason_codes.batchid AS batchid, reason_codes.batch_date AS batch_date").
      joins("LEFT JOIN reason_codes_clients_facilities_set_names rcc ON rcc.reason_code_id = reason_codes.id \
      AND rcc.client_id is null AND rcc.facility_id is null").
      where(condition_string, condition_values).
      paginate(:page => params[:page], :per_page => 30)
  end
  
  def code_accept
    @status = ['ACCEPT','REJECT']
    @code_id = params[:id]
    @facilities = Facility.find(:all)
    @payer = ReasonCode.find(params[:id]).payer.payer unless ReasonCode.find(params[:id]).payer.blank?
  end
  
  def reasoncode_accept
    reason_code = ReasonCode.find(params[:id])
    reason_code.update_attribute("status", "ACCEPT")
    JobActivityLog.create_activity({:allocated_user_id => @current_user.id,
        :activity => 'Reason Code Approved', :start_time => Time.now,
        :object_name => 'reason_codes', :object_id => reason_code.id,
        :field_name => 'status', :old_value => "NEW", :new_value => "ACCEPT"})
    flash[:notice] =  "Code has been Accepted"
    redirect_to  :action => 'manage_newly_added_codes', :page => params[:page], :filter_hash => params[:filter_hash]
  end
  
  #for editing the job
  def payer_selection
    @job = Job.find(params[:id])
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    if search_field.blank?
      payers = Payer.find(:all)
    else
      payers = filter_payers(criteria, compare, search_field, action = 'select')
    end
    @payer_pages = payers.paginate( :per_page => 30,:page => params[:page])
  end
  
  #for creating new job
  def select_payer
    @batch = Batch.find(params[:id])
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    if search_field.blank?
      payers = Payer.find(:all)
    else
      payers = filter_payers(criteria, compare, search_field, action = 'select')
    end
    @payer_pages = payers.paginate( :per_page => 30,:page => params[:page])
  end
  
  def assign_payer
    @payer = Payer.find(params[:id])
    @job = Job.find_by_id(params[:job])
    @job.payer = @payer
    @job.save
    redirect_to :controller => 'job' ,:action => 'edit_payer', :id => @job.id
  end
  
  def remove_payer
    @job = Job.find_by_id(params[:id])
    @job.payer = nil
    @job.save
    redirect_to :controller => '../qa', :action => 'verify', :job => @job
  end
  
  def allocate_payer
    search_field = params[:to_find]
    compare = params[:compare]
    criteria = params[:criteria]
    if search_field.blank?
      payers = Payer.find(:all)
    else
      payers = filter_payers(criteria, compare, search_field, action = 'index')
    end
    @payer_pages = payers.paginate( :per_page => 30,:page => params[:page])
  end
  
  def new_payers
    @payers = Payer.paginate(:per_page=>30, :page=>params["page"])
    if @payers.size == 0
      if flash[:notice].nil?
        flash[:notice] =  "No newly added Payer found"
        redirect_to :action => 'index'
      else
        flash[:notice] = flash[:notice] + "<br/>" + "No newly added Payer found"
        redirect_to :action => 'index'
      end
    end
  end

  def code_delete
    reason_code = ReasonCode.find(params[:id])
    if reason_code && !reason_code.is_associated_somewhere?
      reason_code.delete # if reason_code
      flash[:notice] =  "Reason Code has been deleted"
    else
      flash[:notice] =  "Reason Code cannot be  deleted"
    end
    redirect_to :action => 'manage_newly_added_codes', :page => params[:page], :filter_hash => params[:filter_hash]
  end
  
  def accept_payer
    id = params[:id]
    payer = Payer.find(id)
    payer.payer_type = id
    payer.save
    flash[:notice] =  "Payer Accepted"
    redirect_to :action => 'new_payers'
  end
  
  def duplicate_payer_checking
    payer_name = params[:payer]
    payer_count = Payer.count(:all,:conditions => "payer = '#{payer_name}' and payid != 'D9999'")
    if(payer_count > 0)
      status = "true"
      render :text =>  status
    else
      status = "false"
      render :text =>  status
    end
  end


  def verify_payer
    @micr = MicrLineInformation.find(params[:id])
    @payer = @micr.payer
    @images = @payer.check_informations.uniq.map{|c| c.job.images_for_jobs }
    @images_check_numbers = @payer.check_informations.map{|c| c.check_number }.flatten.uniq
    if @images.size > 0
      @image_type  =  @payer.check_informations.last.batch.facility.image_type
    end
    set_name = @payer.reason_code_set_name
    @rc_set_name = set_name.name if !set_name.blank?
  end
  
  def verify_payer_without_micr
    @payer = Payer.find(params[:id])
    @images = @payer.check_informations.uniq.map{|c| c.job.images_for_jobs }
    @images_check_numbers = @payer.check_informations.map{|c| c.check_number }.flatten.uniq
    if @images.size > 0
      @image_type  =  @payer.check_informations.last.batch.facility.image_type
    end
    set_name = @payer.reason_code_set_name
    @rc_set_name = set_name.name if !set_name.blank?
  end

  
  def process_facilities_micr_informations
    hash_of_facilities_micr_informations = params[:onbase]
    hash_of_facilities_micr_informations.each {|key,value|
      facilities_micr_info_id = value["onbase_id"]
      onbase_name = value["name"]
      facility_id = value["facility"]
      
      if facilities_micr_info_id.blank?
        facilities_micr_information = create_facilities_micr_information(onbase_name, facility_id)
        logger.debug "-> Onbase name is created : #{facilities_micr_information.id}"
      else
        if onbase_name.blank?
          delete_facilities_micr_information(facilities_micr_info_id.to_i)
          logger.debug "-> Onbase name is deleted : #{facilities_micr_info_id}"
        else
          facilities_micr_information = update_facilities_micr_information(facilities_micr_info_id.to_i, onbase_name, facility_id)
          logger.debug "-> Onbase name is updated : #{facilities_micr_information.id}"
        end
      end
    } unless hash_of_facilities_micr_informations.blank?
  end

  def create_facilities_micr_information(onbase_name, facility_id)
    FacilitiesMicrInformation.create(
      :onbase_name => onbase_name,
      :facility_id => facility_id,
      :micr_line_information_id => @micr_line_information.id)
  end

  def update_facilities_micr_information(facilities_micr_information_id, onbase_name, facility_id)
    FacilitiesMicrInformation.update(facilities_micr_information_id,
      :onbase_name => onbase_name,
      :facility_id => facility_id,
      :micr_line_information_id => @micr_line_information.id)
  end

  def delete_facilities_micr_information(facilities_micr_information_id)
    FacilitiesMicrInformation.delete(facilities_micr_information_id)
  end

  def payer_name_search

    condition_list = Array.new
    mpi_query_condition = Array.new
    condition_list << "payers.status in ('APPROVED', 'UNMAPPED', 'MAPPED') && payers.active != 0 && (micr_line_informations.id IS NULL OR micr_line_informations.status = '#{MicrLineInformation::APPROVED}')"
    condition_list << "payer like '%#{params[:payer_name].strip}%'"  unless params[:payer_name].blank?
    condition_list << "pay_address_one = '#{params[:address1].strip}'"   unless params[:address1].blank?
    condition_list << "pay_address_two = '#{params[:address2].strip}'"  unless params[:address2].blank?
    condition_list << "payer_city = '#{params[:city].strip}'"   unless params[:city].blank?
    condition_list << "payer_state = '#{params[:state].strip}'"  unless params[:state].blank?
    condition_list << "payer_zip = '#{params[:zip].strip}'"  unless params[:zip].blank?
    mpi_query_condition = condition_list.join(" and ")
    if(condition_list.length > 1)
      @matching_payers = Payer.find(:all,:select => "distinct payers.id AS id,payers.payer AS payer,
                   payers.era_payer_name as era_payer_name,
                   payers.payid AS payid, payers.payer_type AS payer_type,
                   payers.pay_address_one AS pay_address_one,
                   payers.pay_address_two AS pay_address_two,
                   payers.payer_city AS payer_city, payers.payer_state AS payer_state,
                   payers.payer_zip AS payer_zip, payers.company_id AS company_id,
                   payers.footnote_indicator AS footnote_indicator,
                   payers.eobs_per_image AS eobs_per_image,
                   payers.status AS status, reason_code_set_names.name AS rc_set_name,
                   micr_line_informations.id AS micr_id,
                   micr_line_informations.aba_routing_number AS aba_routing_number,
                   micr_line_informations.payer_account_number AS payer_account_number,
                   (CASE WHEN #{!$IS_PARTNER_BAC} || payers.status = 'MAPPED' ||
                       payers.payer_type = '#{Payer::COMMERCIAL}' ||
                       payers.payer_type = '#{Payer::PATPAY}'
                       THEN payers.payid ELSE micr_line_informations.payid_temp END) AS exact_payid",
        :conditions => mpi_query_condition,
        :joins => "LEFT OUTER JOIN micr_line_informations ON payers.id = micr_line_informations.payer_id
                    INNER JOIN reason_code_set_names ON payers.reason_code_set_name_id = reason_code_set_names.id",
        :order => "payers.batch_target_time asc").paginate(:page => params[:page], :per_page => 15)
      #      @matching_payers = Payer.where(mpi_query_condition).paginate(:per_page => 15, :page => params[:page])

      if((@matching_payers.length) == 0)
        flash[:notice] = "NO MATCH FOUND"
      else
        flash[:notice] = nil
      end
    end
  end

  # Validates and saves the payer, micr record and their related elements
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def save_payer_and_its_related_attributes
    result = true
    error_message = nil
    if !params[:id].blank?
      @payer = Payer.find(params[:id])
    else
      @payer = Payer.new
    end
    params[:payer][:payer_type] = params[:payer_type]
    params[:payer][:footnote_indicator] = params[:payer_footnote_indicator]
    params[:payer][:set_name] = params[:rc_set][:name]

    result, error_message = validate_payer_and_its_related_attributes
    message = error_message if result
    logger.debug "validate_payer_and_its_related_attributes  : #{result}"
    return result, error_message if not result

    result, error_message = save_payer
    return result, error_message if not result

    if @is_partner_bac
      logger.debug "Invoking BAC payer mapping webservice call."
      if make_edc_calls
        flash.now[:notice] = "Payer  #{@payer.payer} updated sucessfully and marked for approval"
      end
    end
    if !@do_not_save_micr
      result, error_message = save_micr
      return result, error_message if not result
      save_micr_specific_payer_name
      save_facility_specific_plan_type
    end
    save_payment_and_allowance_and_capitation_codes
    save_output_payid

    error_message = message.to_s + error_message.to_s
    error_message = nil if error_message.blank?
    return result, error_message
  end

  private

  def make_edc_calls
    begin
      res = RevService::PayerEncounterHelper.get_edc_payer(@micr.aba_routing_number,@micr.payer_account_number, @payer.name, @payer.footnote_indicator,@payer.payer_address_dto)
      logger.debug res.inspect
      if res.present?
        @micr.update_temp_payer_details(res)
      else
        @micr.update_payer_and_gateway_defaults
      end
    rescue Exception => e
      logger.error e
      if e.to_s == "Cannot communicate with server"
        @micr.update_payer_and_gateway_defaults
      else
        return false
      end
    end
  end

  def find_realtive_url
    @relative = ""
    url = request.url
    pieces = url.split("/")
    index = pieces.index("admin")
    if index > 3
      @relative = pieces[index-1]
    end
  end

  # Provides the new footnote indicator after re-classification
  # Input :
  # payer_footnote_indicator : old footnote indicator coming from User input
  # Output :
  # footnote_indicator_to_be_updated : New footnote indicator after re-classification
  # tried_to_change_footnote_indicator : Indication whether the new indicator
  #   was different from the old one
  def footnote_indicator_after_reasoncode_cleanup(payer_footnote_indicator)
    footnote_indicator_to_be_updated = nil
    if payer_footnote_indicator.to_s == 'true' || payer_footnote_indicator.to_s == '1'
      new_footnote_indicator = true
    else
      new_footnote_indicator = false
    end
    if !@payer.cleanup_reason_codes_before_reclassification(new_footnote_indicator).blank?
      footnote_indicator_to_be_updated = new_footnote_indicator
    end
    tried_to_change_footnote_indicator = @payer.footnote_indicator != new_footnote_indicator
    return footnote_indicator_to_be_updated, tried_to_change_footnote_indicator
  end

  # Validates all the data related to payer, micr and their related elements
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def validate_payer_and_its_related_attributes
    result = true
    error_message = nil
    if !params[:payer].blank?
      payer_address_fields = {
        :address_one => params[:payer][:pay_address_one].to_s.strip,
        :city => params[:payer][:payer_city].to_s.strip,
        :state => params[:payer][:payer_state].to_s.strip,
        :zip_code => params[:payer][:payer_zip].to_s.strip
      }
    end
    if !params[:micr_line_information].blank?
      routing_number = params[:micr_line_information][:aba_routing_number]
      account_number = params[:micr_line_information][:payer_account_number]
    end
    
    result, error_message = validate_payer_address(payer_address_fields)
    logger.debug "validate_payer_address result : #{result}"
    return result, error_message if not result

    result, error_message = @payer.validate_payer_id(params[:payer][:payid])
    logger.debug "validate_payer_id result : #{result}"
    return result, error_message if not result

    result, error_message = @payer.validate_against_payer_duplication(params[:payer],
      params[:id], params[:micr_line_information])
    if !error_message.blank?
      @do_not_save_micr = true
    end
    logger.debug "validate_against_payer_duplication result : #{result}"
    message = error_message if result
    return result, error_message if not result
    
    result, error_message = @payer.validate_unique_payer_for_micr(routing_number, account_number)
    logger.debug "validate_unique_payer_for_micr result : #{result}"
    return result, error_message if not result

    result, error_message = @payer.validate_presence_of_eobs_when_payer_type_changes(params[:payer][:payer_type])
    logger.debug "validate_presence_of_eobs_when_payer_type_changes result : #{result}"
    return result, error_message if not result

    result, error_message = validate_client_id(params[:facilities_micr_information],
      params[:serial_numbers_for_adding_onbase_name])
    logger.debug "validate_client_id for Onbase Name result : #{result}"
    return result, error_message if not result

    result, error_message = validate_client_id(params[:facilities_payers_information],
      params[:serial_numbers_for_adding_output_payid])
    logger.debug "validate_client_id for Output Payid result : #{result}"
    return result, error_message if not result

    result, error_message = validate_footnote_indicator_for_assigning_set_name
    logger.debug "validate_footnote_indicator_for_assigning_set_name result : #{result}"
    return result, error_message if not result

    result, error_message = validate_payment_and_allowance_and_capitation_codes
    logger.debug "validate_payment_and_allowance_and_capitation_codes result : #{result}"
    return result, error_message if not result
    
    error_message = message.to_s + error_message.to_s
    return result, error_message
  end

  def validate_client_id(object, serial_numbers_added)
    result = true
    error_message = ''
    if !object.blank? && !serial_numbers_added.blank?
      serial_numbers_added = serial_numbers_added.split(',')
      serial_numbers_added.each do |serial_number|
        if !serial_number.blank?
          if object["client_id#{serial_number}"].blank?
            result = false
            error_message = "Please enter client."
            break
          end
        end
      end
    end
    return result, error_message
  end

  # Validates to check if the footnote indicators of the payer having the same set name are same
  # Output :
  # result : result of validation
  # error_message : cause for the error
  def validate_footnote_indicator_for_assigning_set_name
    result = true
    error_message = nil
    set_name = params[:rc_set][:name] if params[:rc_set]
    if !set_name.blank? && !params[:payer_footnote_indicator].blank?
      footnote_indicator = params[:payer_footnote_indicator]
      if footnote_indicator.to_s == 'true' || footnote_indicator.to_s == '1'
        footnote_indicator = true
      else
        footnote_indicator = false
      end
      set_name_obj = ReasonCodeSetName.find_by_name(set_name)
      if !set_name_obj.blank?
        payers = Payer.select("id, footnote_indicator").where(:reason_code_set_name_id => set_name_obj.id, :status => "#{Payer::MAPPED}")
        if payers.length > 0
          if !(payers.length == 1 && payers[0] && payers[0].id.to_s == params[:id])
            footnote_indicators = payers.map(&:footnote_indicator)
            footnote_indicators << footnote_indicator
            if footnote_indicators.length > 1 && footnote_indicators.uniq.length != 1
              result = false
              error_message = "The setname given is given to another payer with different footnote indicator. Please correct the footnote indicator of the payer."
            end
          end
        end
      end
    end
    return result, error_message
  end

  # Validates the data related to payer specific payment,allowance and capitation codes
  # Output :
  # result : result of validation
  # error_message : cause for the error
  def validate_payment_and_allowance_and_capitation_codes
    result = true
    error_message = nil
    facility_id_array, capitation_code_array = [], []
    in_patient_payment_code_array, out_patient_payment_code_array = [], []
    in_patient_allowance_code_array, out_patient_allowance_code_array = [], []
    facilities_payers_information = params[:facilities_payers_information]
    if !facilities_payers_information.blank?
      serial_numbers_added = params[:serial_numbers_for_adding_payment_or_allowance_codes]
      if !serial_numbers_added.blank?
        serial_numbers_added = serial_numbers_added.split(',')
        serial_numbers_added.each do |serial_number|
          if !serial_number.blank?
            facility_id_array << format_ui_param(facilities_payers_information["facility_id#{serial_number}"])
            in_patient_payment_code_array << format_ui_param(facilities_payers_information["in_patient_payment_code#{serial_number}"])
            out_patient_payment_code_array << format_ui_param(facilities_payers_information["out_patient_payment_code#{serial_number}"])
            in_patient_allowance_code_array << format_ui_param(facilities_payers_information["in_patient_allowance_code#{serial_number}"])
            out_patient_allowance_code_array << format_ui_param(facilities_payers_information["out_patient_allowance_code#{serial_number}"])
            capitation_code_array << format_ui_param(facilities_payers_information["capitation_code#{serial_number}"])
          end
        end
      end
    end

    result, error_message = presence_of_facility_in_associated_data(facility_id_array)
    return result, error_message if not result

    facility_id_array.each_with_index do |facility, index|
      if !facility.blank? && capitation_code_array[index].blank? &&
          in_patient_payment_code_array[index].blank? &&
          out_patient_payment_code_array[index].blank? &&
          in_patient_allowance_code_array[index].blank? &&
          out_patient_allowance_code_array[index].blank?
        result = false
        error_message = "Please enter valid values for facility and payer specific data."
      end
    end
    return result, error_message
  end

  # Validates for the presence of facility for micr specific and payer specific data
  # Output :
  # result : result of validation
  # error_message : cause for the error
  def presence_of_facility_in_associated_data(facility_id_array)
    result = true
    error_message = nil
    blank_facility_array = facility_id_array.select{|facility| facility.blank?}
    uniq_facility_array = facility_id_array.uniq
    another_record_with_same_facility_exists = uniq_facility_array.length != facility_id_array.length
    if !blank_facility_array.blank? || another_record_with_same_facility_exists
      result = false
      error_message = "Please enter one row for a facility."
    end
    return result, error_message
  end

  # Saves the payer attributes
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def save_payer
    result = true
    error_message = nil
    old_payid = @payer.supply_payid
    old_footnote_indicator = @payer.footnote_indicator
    old_setname = @payer.reason_code_set_name.name unless @payer.reason_code_set_name.blank?
    set_name = @payer.get_set_name(params[:payer][:payer_type], params[:payer][:payid])

    result, error_message = process_footnote_indicator
    logger.debug "process_footnote_indicator  : #{result}"
    return result, error_message if not result

    normalize_values
    @payer.gateway = @payer.get_gateway
    logger.debug "set_name : #{set_name}"
    new_set_name = ReasonCodeSetName.find_or_create_by_name(set_name)

    success = @payer.clean_up_the_rcs_if_set_name_has_changed(new_set_name)
    set_name_changed_and_cleaned_up = success
    if success && !new_set_name.blank?
      @payer.reason_code_set_name_id = new_set_name.id
    end

    old_status = @payer.status
    if !@payer.accepted?
      @payer.status = "#{Payer::MAPPED}"
    end
    if old_status != @payer.status
      JobActivityLog.create_activity({:allocated_user_id => @current_user.id,
          :activity => 'Payer Approved', :start_time => Time.now,
          :object_name => 'payers', :object_id => @payer.id,
          :field_name => 'status', :old_value => old_status, :new_value => @payer.status})
    end
    if !set_name_changed_and_cleaned_up
      @payer.clean_up_rcs_if_status_has_changed(old_status, old_footnote_indicator)
    end

    #Creating user activity log
    if (!old_payid.blank? && @payer.supply_payid != old_payid) || (!old_footnote_indicator.blank? && @payer.footnote_indicator != old_footnote_indicator)
      new_rc_set_name = ((success)? new_set_name.name : @payer.reason_code_set_name.name)
      activity = "PAYER EDIT"
      description = "PayID: old = #{old_payid}, new = #{@payer.supply_payid}, Set Name: old = #{old_setname}, new = #{new_rc_set_name}, FN Indicator: old = #{old_footnote_indicator}, new = #{@payer.footnote_indicator}"
      UserActivityLog.create_activity_log(current_user, activity, @payer, description)
    end
    
    if !@payer.save
      error_message = 'Payer was not saved'
      logger.error "#{error_message}"
      logger.error "#{@payer.errors.full_messages.join(", ")}"
      return false, error_message
      
    else
      if !params[:payer][:payer_type].blank?
        if params[:payer][:payer_type].strip == "#{Payer::PATPAY}"
          @payer.payer_type = params[:payer][:payer_type].strip
        else
          @payer.payer_type = @payer.id
        end
        logger.debug "@payer.payer_type : #{@payer.payer_type}"
        @payer.save
      end
    end
    @payer_id = @payer.id
    return result, error_message
  end

  # Saves the payer attributes in the object
  def normalize_values
    @payer.payid = format_ui_param(params[:payer][:payid])
    @payer.payer = format_ui_param(params[:payer][:payer])
    @payer.era_payer_name = format_ui_param(params[:payer][:era_payer_name])
    @payer.pay_address_one = format_ui_param(params[:payer][:pay_address_one])
    @payer.pay_address_two = format_ui_param(params[:payer][:pay_address_two])
    @payer.pay_address_three = format_ui_param(params[:payer][:pay_address_three])
    @payer.payer_state = format_ui_param(params[:payer][:payer_state])
    @payer.payer_zip = format_ui_param(params[:payer][:payer_zip])
    @payer.payer_city = format_ui_param(params[:payer][:payer_city])
    @payer.eobs_per_image = format_ui_param(params[:payer][:eobs_per_image])
    if !params[:plan_type].blank?
      plan_type  = params[:plan_type].split('-')
      @payer.plan_type =  plan_type[1]
    else
      @payer.plan_type =  nil
    end
    @payer.payer_tin = format_ui_param(params[:payer][:payer_tin])
    @payer.company_id = format_ui_param(params[:payer][:company_id])
  end

  # Saves the footnote indicator of a payer
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def process_footnote_indicator
    footnote_indicator_successfully_updated = true
    footnote_indicator_to_be_assigned, tried_to_change_footnote_indicator = footnote_indicator_after_reasoncode_cleanup(params[:payer_footnote_indicator])
    if tried_to_change_footnote_indicator
      if !footnote_indicator_to_be_assigned.nil?
        @payer.footnote_indicator = footnote_indicator_to_be_assigned
        footnote_indicator_successfully_updated = true
      else
        footnote_indicator_successfully_updated = false
        error_message = "Footnote indicator was not successfully updated."
      end
    else
      footnote_indicator_successfully_updated = true
    end
    return footnote_indicator_successfully_updated, error_message
  end

  # Saves the micr attributes
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def save_micr
    result = true
    error_message = nil
    if !params[:micr_line_information].blank?
      aba_routing_number = params[:micr_line_information][:aba_routing_number].to_s.strip
      payer_account_number = params[:micr_line_information][:payer_account_number].to_s.strip
      is_ocr = params[:micr_line_information][:is_ocr]
    end

    if !aba_routing_number.blank? && !payer_account_number.blank?
      micr_id = params[:micr_id]
      if !micr_id.blank?
        @micr = MicrLineInformation.find(micr_id)
      else
        @micr = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(aba_routing_number, payer_account_number)
        if @micr.blank?
          @micr = MicrLineInformation.new
        end
      end
      @micr.aba_routing_number = aba_routing_number
      @micr.payer_account_number = payer_account_number
      @micr.is_ocr = is_ocr
      @micr.payer_id = @payer.id

      if (@micr.status.blank? || @micr.status.to_s.upcase == "#{MicrLineInformation::NEW}") && !$IS_PARTNER_BAC
        @micr.status = "#{MicrLineInformation::APPROVED}"
      elsif @micr.status.blank?
        @micr.status = "#{MicrLineInformation::NEW}"
      end

      result = @micr.save!
      if not result
        error_message = "MICR record was not created / updated."
        logger.error "#{error_message}"
        logger.error "#{@micr.errors.full_messages.join(", ")}"
      end
    end
    
    return result, error_message
  end

  # Saves the micr specific payer name and payid
  def save_micr_specific_payer_name
    if !params[:fac_micr_info_ids_to_delete].blank?
      ids_to_delete = params[:fac_micr_info_ids_to_delete].split(',')
      FacilitiesMicrInformation.destroy(ids_to_delete)
    end

    facilities_micr_information = params[:facilities_micr_information]
    if !facilities_micr_information.blank?      
      serial_numbers_added = params[:serial_numbers_for_adding_onbase_name]
      if !serial_numbers_added.blank? && !@micr.blank?
        new_records = []
        serial_numbers_added = serial_numbers_added.split(',')

        serial_numbers_added.each do |serial_number|
          if !serial_number.blank?
            client_id = format_ui_param(facilities_micr_information["client_id#{serial_number}"])
            facility_id = format_ui_param(facilities_micr_information["facility_id#{serial_number}"])
            onbase_name = format_ui_param(facilities_micr_information["onbase_name#{serial_number}"])
            if !onbase_name.blank?
              onbase_name = onbase_name.strip
              new_record = FacilitiesMicrInformation.initialize_or_update_if_found(@micr.id, client_id, facility_id, onbase_name)
              new_records << new_record if !new_record.blank?
            end
          end
        end
        FacilitiesMicrInformation.import new_records if !new_records.blank?
      end
    end

    # Saves the payer specific payment, allowance and capitation codes
    def save_payment_and_allowance_and_capitation_codes
      if !params[:fac_payer_info_ids_to_delete].blank?
        ids_to_delete = params[:fac_payer_info_ids_to_delete].split(',')
        ids_to_delete.each do |id|
          facility_payers_info = FacilitiesPayersInformation.find(id)
          if facility_payers_info.output_payid.blank?
            FacilitiesPayersInformation.destroy(id)
          else
            facility_payers_info.in_patient_payment_code = nil
            facility_payers_info.out_patient_payment_code = nil
            facility_payers_info.in_patient_allowance_code = nil
            facility_payers_info.out_patient_allowance_code = nil
            facility_payers_info.capitation_code = nil
            facility_payers_info.save
          end
        end
      
      end

      facilities_payers_information = params[:facilities_payers_information]
      if !facilities_payers_information.blank?
        serial_numbers_added = params[:serial_numbers_for_adding_payment_or_allowance_codes]
        if !serial_numbers_added.blank? && !@payer.blank?
          serial_numbers_added = serial_numbers_added.split(',')
        
          serial_numbers_added.each do |serial_number|
            if !serial_number.blank?
              client_id = format_ui_param(params[:facilities_payers_information]["client_id#{serial_number}"])
              facility_id = format_ui_param(params[:facilities_payers_information]["facility_id#{serial_number}"])
              in_patient_payment_code = format_ui_param(params[:facilities_payers_information]["in_patient_payment_code#{serial_number}"])
              out_patient_payment_code = format_ui_param(params[:facilities_payers_information]["out_patient_payment_code#{serial_number}"])
              in_patient_allowance_code = format_ui_param(params[:facilities_payers_information]["in_patient_allowance_code#{serial_number}"])
              out_patient_allowance_code = format_ui_param(params[:facilities_payers_information]["out_patient_allowance_code#{serial_number}"])
              capitation_code = format_ui_param(params[:facilities_payers_information]["capitation_code#{serial_number}"])

              if !@payer.id.blank? && facility_id
                facility_array = Facility.select("id").where("id = ?", facility_id)
                facility = facility_array.first if !facility_array.blank?
                if !facility.blank?
                  facility_payer_info = FacilitiesPayersInformation.find_by_payer_id_and_facility_id(@payer.id, facility.id)
                  unless facility_payer_info.blank?
                    facility_payer_info.in_patient_payment_code = in_patient_payment_code
                    facility_payer_info.out_patient_payment_code = out_patient_payment_code
                    facility_payer_info.in_patient_allowance_code = in_patient_allowance_code
                    facility_payer_info.out_patient_allowance_code = out_patient_allowance_code
                    facility_payer_info.capitation_code = capitation_code
                    facility_payer_info.client_id = client_id
                    facility_payer_info.save
                  else
                    FacilitiesPayersInformation.create!(:facility_id => facility.id,
                      :payer_id => @payer.id,
                      :in_patient_payment_code => in_patient_payment_code,
                      :out_patient_payment_code => out_patient_payment_code,
                      :in_patient_allowance_code => in_patient_allowance_code,
                      :out_patient_allowance_code => out_patient_allowance_code,
                      :capitation_code => capitation_code)
                  end
                end
              end
            end
          end
        end
      end
    end

    # Saves the output payid
    def save_output_payid
      if !params[:fac_payer_info_ids_to_delete_for_output_payid].blank?
        ids_to_delete = params[:fac_payer_info_ids_to_delete_for_output_payid].split(',')
        ids_to_delete.each do |id|
          facility_payers_info = FacilitiesPayersInformation.find(id)
          if facility_payers_info.in_patient_payment_code.blank? &&
              facility_payers_info.out_patient_payment_code.blank? &&
              facility_payers_info.in_patient_allowance_code.blank? &&
              facility_payers_info.out_patient_allowance_code.blank? &&
              facility_payers_info.capitation_code.blank?
            FacilitiesPayersInformation.destroy(id)
          else
            facility_payers_info.update_attribute("output_payid", nil)
          end
        end
      end

      facilities_payers_information = params[:facilities_payers_information]
      if !facilities_payers_information.blank?        
        serial_numbers_added = params[:serial_numbers_for_adding_output_payid]
        if !serial_numbers_added.blank? && !@payer.blank?
          new_records = []
          serial_numbers_added = serial_numbers_added.split(',')

          serial_numbers_added.each do |serial_number|
            if !serial_number.blank?
              client_id = format_ui_param(params[:facilities_payers_information]["client_id#{serial_number}"])
              facility_id = format_ui_param(params[:facilities_payers_information]["facility_id#{serial_number}"])
              output_payid = format_ui_param(params[:facilities_payers_information]["output_payid#{serial_number}"])

              if !output_payid.blank?
                output_payid = output_payid.strip
                new_record = FacilitiesPayersInformation.initialize_or_update_if_found(@payer.id, client_id, facility_id, output_payid)
                new_records << new_record if !new_record.blank?
              end
            end
          end
          FacilitiesPayersInformation.import new_records if !new_records.blank?
        end        
      end
    end
  end

  def save_facility_specific_plan_type
    ids_to_delete = params[:plan_ids_to_delete].split(',').compact.drop(1)
    FacilityPlanType.delete_all(:id => ids_to_delete)
    facility_plan_types = params[:facility_plan_type]
    if facility_plan_types
      facility_plan_types.each_pair do |id, plan_data|
        FacilityPlanType.create!(:payer_id => @payer.id, :plan_type => plan_data['plan_type'],
          :client_id => plan_data['client_id'], :facility_id => plan_data['facility_id'])
      end
    end
  end

end
