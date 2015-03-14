# xCopyright (c) 2007. RevenueMed, Inc. All rights reserved.

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

require 'tzinfo'
include TZInfo

class ApplicationController < ActionController::Base
  # AuthenticatedSystem must be included for RoleRequirement, and is provided by installing acts_as_authenticates and running 'script/generate authenticated account user'.

  # RAILS3.1 Correction
  require File.join(Rails.root, 'lib', 'authenticated_system.rb')

  include AuthenticatedSystem
  include ApplicationHelper
  
  # You can move this into a different controller, if you wish.  This module gives you the require_role helpers, and others.
  # RAILS3.1 Correction
  require File.join(Rails.root, 'lib', 'role_requirement_system.rb')
  include RoleRequirementSystem
  
  before_filter :authenticate_user!, :last_activity
  protect_from_forgery :only => [:update, :delete, :create]

  # The Client names of the HLSC made into Global variable
  $HLSC_CLIENT_A = "Client A"
  $HLSC_CLIENT_B = "Client B"
  $HLSC_CLIENT_C = "Client C"
  $HLSC_CLIENT_D = "Client D"
  $HLSC_CLIENT_E = "Client E"
  $HLSC_CLIENT_F = "Client F"

  # Method for devise to redirect path after sign in
  def after_sign_in_path_for(resource)
    app_root + "/welcome"
  end

  # Method for devise to redirect path after sign out
  def after_sign_out_path_for(resource)
    app_root + "/sessions/new"
  end

  def number_with_precision(number, *args)
    options = args.extract_options!
    options.symbolize_keys!
    defaults           = I18n.translate('number.format''number.format', :locale => options[:locale], :raise => true) rescue {}
    precision_defaults = I18n.translate('number.precision.format''number.precision.format', :locale => options[:locale],
      :raise => true) rescue {}
    defaults           = defaults.merge(precision_defaults)
    unless args.empty?
      ActiveSupport::Deprecation.warn('number_with_precision takes an option hash ' +
          'instead of a separate precision argument.', caller)
    end
    precision ||= (options[:precision] )
    begin
      rounded_number = (Float(number) * (10 ** precision)).round.to_f / 10 ** precision
      ("%01.#{precision}f" % rounded_number
      )
    rescue
      number
    end
  end

  def client_activity(checknumber,eob_id,client_action,jobid)
    eob_type=nil
    if cookies[:userid]
      @client_activity_log=ClientActivityLog.new()
      @client_activity_log.start_time=Time.now()
      user_id = User.find_by_login(cookies[:userid]).id
      @client_activity_log.user_id= user_id
      if !eob_id.blank?
        check_information = CheckInformation.find(checknumber)
        eob_type = check_information.payer.payer unless check_information.payer.blank?
        if !eob_type.blank?
          @client_activity_log.eob_type="ins_eob"
        else
          @client_activity_log.eob_type="pat_eob"
        end
        @client_activity_log.eob_id=eob_id
      end
      @client_activity_log.activity=client_action
      @client_activity_log.job_id = jobid
      @client_activity_log.save
      if client_action=="Logged Out"
        session[:client_recored_id]=nil
        session[:client_id] = nil
      end
    end

  end

  # An addition last boolean flag to collect job_activity object for bulk save, otherwise to individual save
  def save_job_activity(job_id, eob_id, processor_id, qa_id, activity_name, time, end_time, eob_type_id, do_save = true, activity_user_id = nil)
    @job_activity=JobActivityLog.new()
    @job_activity.job_id=job_id
    @job_activity.eob_id=eob_id
    @job_activity.processor_id= processor_id
    @job_activity.qa_id=qa_id
    @job_activity.activity=activity_name
    @job_activity.start_time=time
    @job_activity.end_time = end_time
    @job_activity.eob_type_id = eob_type_id
    @job_activity.allocated_user_id = activity_user_id
    if do_save    
      @job_activity.save
    else
      return @job_activity
    end
  end

  def assign_job_activity(job_id,processor_id,allocated_userid,qa_id, eob_type_id)
    @job_activity=JobActivityLog.new()
    @job_activity.job_id=job_id
    @job_activity.processor_id= processor_id
    @job_activity.qa_id= qa_id
    @job_activity.allocated_user_id = allocated_userid
    @job_activity.activity="Allocated Job"
    @job_activity.start_time=Time.now
    @job_activity.eob_type_id = eob_type_id
    @job_activity.save
  end

  def save_output_activity(batch_id,user_id,activity_name)
    @output_activity=OutputActivityLog.new()
    @output_activity.batch_id=batch_id
    @output_activity.user_id= user_id
    @output_activity.activity=activity_name
    @output_activity.start_time=Time.now
    @output_activity.save
  end

  def save_regenerated_activity(eob_id,user_id,activity_name)
    @regenerated_activity=OutputRegeneratedLog.new()
    @regenerated_activity.eob_id=eob_id
    @regenerated_activity.user_id= user_id
    @regenerated_activity.activity=activity_name
    @regenerated_activity.start_time=Time.now
    @regenerated_activity.save
  end

  def save_mpi_statistics(batch_id,user_id,eob,mpi_status,search_criteria,time)
    @mpi_statistics = MpiStatisticsReport.new()
    @mpi_statistics.batch_id = batch_id
    @mpi_statistics.user_id = user_id
    @mpi_statistics.mpi_status = mpi_status
    @mpi_statistics.search_criteria = search_criteria
    @mpi_statistics.start_time = time
    @mpi_statistics.eob = eob
    @mpi_statistics.save!
  end

  def get_saved_eob(job_id,page_no)
    @parent_job_id = Job.find(job_id).parent_job_id
    if @parent_job_id.blank?
      check_information = CheckInformation.find_by_job_id(job_id)
      @insurance_eobs = InsurancePaymentEob.find(:all,:conditions => "check_information_id = #{check_information.id}")
    else
      check_information = CheckInformation.find_by_job_id(@parent_job_id)
      @insurance_eobs = InsurancePaymentEob.find(:all,:conditions => "sub_job_id = #{job_id}")
    end
    @patient_pay_eobs = PatientPayEob.find(:all,:conditions => "check_information_id = #{check_information.id}")
    if !@insurance_eobs.blank?
      for j in 0..@insurance_eobs.length-1
        j = page_no.to_i - 1
        eob_id = @insurance_eobs[j].id
      end
    else
      for k in 0..@patient_pay_eobs.length-1
        k = page_no.to_i - 1
        eob_id = @patient_pay_eobs[k].id
      end
    end
    return eob_id
  end

  def flash_message
    redirect_to :controller => '/dashboard', :action => 'index'
  end
  def flash_message_data
    flash[:notice] = 'You Don\'t have necessary permission.'
    redirect_to :controller => '/dashboard', :action => 'index'
  end

  def flash_shift_message
    flash[:notice] = 'You are not allowed to work in this shift.'
  end


  def list_sort (items, sort)
    sorted = items.sort_by do
      sort
    end
    if sort =~ /reverse/
      sorted = items.reverse
    end
    return sorted
  end
  # seconds to hh:mm:ss format
  def to_dot_time(time)
    time = time.to_i
    hours = time/3600.to_i
    minutes = (time/60 - hours * 60).to_i
    seconds = (time - (minutes * 60 + hours * 3600))
    #    [hours, minutes, seconds].join(":")
    [format('%02d', hours),format('%02d', minutes) , format('%02d', seconds)].join(":")
  end

  #Converting given EST time into IST time
  def convert_to_ist_time(time)
    tz_est = Timezone.get('US/Eastern')
    utc_time = tz_est.local_to_utc(time, false)
    tz_ist = Timezone.get('Asia/Calcutta')
    ist_time = tz_ist.utc_to_local(utc_time)
    return ist_time
  end

  #Converting given IST time into EST time
  def convert_to_est_time(time)
    tz_ist = Timezone.get('Asia/Calcutta')
    utc_time = tz_ist.local_to_utc(time, false)
    tz_est = Timezone.get('US/Eastern')
    est_time = tz_est.utc_to_local(utc_time)
    return est_time
  end
  #split_decimal function formats the amount as 35 if it appears 35.00 or 35.0 (for 835 output)
  def split_decimal(total_amount)
    total_amount = total_amount.to_s
    total_amount_array=total_amount.split(".")
    if total_amount_array[1]== "00" or total_amount_array[1]== "0"
      total_amount=total_amount_array[0]
    end
    return total_amount
  end

  #format_amount function formats the amount as 3500 if it appears 35.00 or 35.0 (for patient_pay_output)
  def format_amount(total_amount)
    total_amount_array=total_amount.split(".")

    if total_amount_array[1] and total_amount_array[1].size<=1
      total_amount_array[1]=total_amount_array[1]+"0"
    end
    if total_amount_array[1]
      total_amount=total_amount_array[0]+total_amount_array[1]
    end
    return total_amount
  end

  def report_file_name(file_name)

    new_file_name = file_name.split("/")
    patient_file_name=""
    for i in 0..new_file_name.size-1
      if patient_file_name!=""
        patient_file_name = patient_file_name+"_"+new_file_name[i]
      else
        patient_file_name = new_file_name[i]
      end
    end
    return patient_file_name
  end

  def format_deposit_date(date_of_deposit)
    deposit_date_array = date_of_deposit.split("-")
    bank_deposit_date_format = deposit_date_array[0].slice(2,4)+deposit_date_array[1]+deposit_date_array[2]
    return(bank_deposit_date_format)
  end

  def validate_payer_address(payer_address_fields)   
    if !payer_address_fields.blank?
      to_proceed = true
      if $IS_PARTNER_BAC
        to_proceed = validate_presence_of_all_or_no_payer_address_fields(payer_address_fields)
        if not to_proceed
          statement_to_alert = "Please enter full payer address or leave all fields blank."
        end
      else
        to_proceed = validate_presence_of_all_payer_address_fields(payer_address_fields)
       
        if not to_proceed
          statement_to_alert = "Please enter full and valid payer address fields."
        end
      end
    end
    return to_proceed, statement_to_alert.to_s
  end

  def validate_presence_of_all_payer_address_fields(payer_address_fields)   
    if !payer_address_fields.blank?
      validation = true
      are_all_address_fields_present = !payer_address_fields[:address_one].blank? &&
        !payer_address_fields[:city].blank? && !payer_address_fields[:state].blank? && !!(payer_address_fields[:state] =~ /^[a-zA-Z]{2}$/) &&
        !payer_address_fields[:zip_code].blank? && (payer_address_fields[:zip_code] =~ /^\d{5}$/ || payer_address_fields[:zip_code] =~ /^\d{9}$/)

      if not are_all_address_fields_present
        validation = false
      end
    end
    return validation
  end

  def validate_presence_of_all_or_no_payer_address_fields(payer_address_fields)
    if !payer_address_fields.blank?
      validation = true
      number_of_blank_address_fields = 0
      length_of_address_fields = payer_address_fields.length
      payer_address_fields.each do |key, address_field|
        if address_field.to_s.blank?
          number_of_blank_address_fields += 1
        end
      end
      if number_of_blank_address_fields > 0 && number_of_blank_address_fields != length_of_address_fields
        validation = false
      end
    end
    return validation
  end

  def validate_patient_address(patient_address_fields, facility_name)  
    validate_patient_address_flag = true
    eob_type_value = eob_type
    patient_pay = (eob_type_value == 'Patient')
    if patient_pay && @facility.details[:patient_address] &&
        facility_name != "GOODMAN CAMPBELL BRAIN AND SPINE"
      unless patient_address_fields.blank?
        patient_address_fields_present = !patient_address_fields[:address_one].blank? &&
          !patient_address_fields[:city].blank? &&
          !patient_address_fields[:state].blank? &&
          !patient_address_fields[:zip_code].blank?
        if !patient_address_fields_present
          validate_patient_address_flag = false
          patient_address_alert = "Patient Pay EOB must have complete patient address : Address1, City, State, Zip"
        end
      end
    end
    return validate_patient_address_flag, patient_address_alert.to_s
  end

  def is_micr_format_valid?(micr_data)
    (micr_data.nil? || !(micr_data == '' || micr_data.match(/^[\w]+$/).blank? ||
          micr_data.match(/[^0]/).blank?))
  end

  def is_aba_length_valid?(aba_data)
    (aba_data.nil? || !(aba_data == '' || aba_data.match(/(^\d{9}$)/).blank?))
  end

  def is_payer_accno_length_valid?(payer_accno_data)
    (payer_accno_data.nil? || !(payer_accno_data == '' || payer_accno_data.length >= 3 ||
          payer_accno_data.length <= 14))
  end

  def get_job_level_balance(check_information, parent_job, facility)
    (check_information.check_amount.to_f.round(2) - (InsurancePaymentEob.amount_so_far(check_information, facility).to_f +
          parent_job.get_provider_adjustment_amount).round(2)).round(2)
  end

  def validate_netgen_eob_saved_already(check_information)
    to_save = true
    patient_pay_eob = check_information.patient_pay_eobs.exists?
    if(patient_pay_eob == true)
      to_save = false
      eob_releated_to_check_alert = "This check already contains EOBs of type:NextGen."
    end
    return to_save,eob_releated_to_check_alert
  end
  
  def validate_insurance_eob_saved_already(check_information)
    to_save = true
    insurance_payment_eobs = check_information.insurance_payment_eobs.exists?
    if(insurance_payment_eobs == true)
      to_save = false
      payer_type = check_information.payer.payer_type
      payer_type = "Insurance" if(payer_type =~ /^\d+$/ || payer_type == "Commercial")
      statement_to_alert = "This check already contains EOBs of type: '#{payer_type}'."
    end
    return to_save,statement_to_alert
  end

  def clean_up_reason_codes_jobs
    job_id = params[:job_id]
    job = Job.find(job_id)
    job_id = job.get_parent_job_id
    reason_codes_for_job = ReasonCodesJob.all(:select => "reason_codes.*, reason_codes_jobs.*",
      :conditions => ["((parent_job_id = #{job_id} or sub_job_id = #{job_id}) and unique_code NOT IN ('1','2','3','4','5'))"], :joins => :reason_code)
    ids_to_delete = reason_codes_for_job.map(&:id)
    deleted_rc_jobs_count = ReasonCodesJob.delete(ids_to_delete)
    if params[:get_deleted_rc_jobs_count] == 'true'
      render :text => deleted_rc_jobs_count
    end
  end

  def update_job_and_batch_when_associated_entities_are_changed(batch, job)
    Batch.where(:id => batch.id).update_all(:associated_entity_updated_at => Time.now)
    Job.where(:id => job.id).update_all(:associated_entity_updated_at => Time.now)
  end

  def frame_conditions_from_filter(initial_condition = "")
    condition_string_array = []
    condition_string = ""
    condition_values = {}

    if initial_condition.present?
      condition_string_array << initial_condition
    end

    ['1', '2'].each do |number|
      if params[:filter_hash]
        criteria = params[:filter_hash]["criteria_#{number}".to_sym]
        to_find = params[:filter_hash]["to_find_#{number}".to_sym]
        compare = params[:filter_hash]["compare_#{number}".to_sym]
      else
        criteria = params["criteria_#{number}".to_sym]
        to_find = params["to_find_#{number}".to_sym]
        compare = params["compare_#{number}".to_sym]
      end
      if criteria.present? && to_find.present?
        condition_string_1, condition_values = frame_conditions(criteria, to_find, compare, condition_values)
        if condition_string_1.present?
          condition_string_array << condition_string_1
        end
      end
    end
    if condition_string_array.present?
      condition_string = condition_string_array.flatten.join(" AND ")
    end

    return condition_string, condition_values
  end

  def frame_conditions(criteria, to_find, compare = "=", condition_values = {})
    condition_string = []
    to_find = to_find.strip
    case criteria
    when 'Batch ID'
      if condition_values[:batchid].blank?
        batchid = "%#{to_find}%"
        batchid =  batchid.gsub!("_","\\_") if batchid.include?'_'
        condition_string << " reason_codes.batchid like :batchid"
        condition_values[:batchid] = batchid
      end
    when 'Batch Date'
      begin
        if condition_values[:batch_date].blank?
          date = Date.strptime(to_find,"%m/%d/%y").to_s
          condition_string << " reason_codes.batch_date #{compare} :batch_date"
          condition_values[:batch_date] = date
        end
      rescue ArgumentError
        flash[:notice] = "Invalid date format, use mm/dd/yy"
        return ""
      end
    when 'Facility', 'Site Name', 'Facility Name'
      if condition_values[:facility_name].blank?
        condition_string << " reason_codes.facility_name like :facility_name "
        condition_values[:facility_name] = "%#{to_find}%"
      end
    when 'Check Number'
      if condition_values[:check_number].blank?
        condition_string << " reason_codes.check_number like :check_number "
        condition_values[:check_number] = "%#{to_find}%"
      end
    when 'Payer Name'
      if condition_values[:payer_name].blank?
        condition_string << " reason_codes.payer_name like :payer_name "
        condition_values[:payer_name] = "%#{to_find}%"
      end
    when 'Paper Code'
      if condition_values[:reason_code].blank?
        condition_string << " reason_codes.reason_code like :reason_code "
        condition_values[:reason_code] = "%#{to_find}%"
      end
    when 'Paper Code Description'
      if condition_values[:reason_code_description].blank?
        condition_string << " reason_codes.reason_code_description like :reason_code_description "
        condition_values[:reason_code_description] = "%#{to_find}%"
      end
    end
    return condition_string, condition_values
  end

  def normalize_date_format(date)
    if date.length == 10
      date.slice!(6..7)
    end
    flash_notice = ''
    begin
      # normalized_date is in IST
      normalized_date = Date.strptime(date, "%m/%d/%y")
    rescue ArgumentError
      flash_notice = "Invalid date format, use mm/dd/yy"
    end
    return normalized_date, flash_notice
  end
  
  def processor_report
    @svc_count  = 0
    @error_count = 0
    claim_svc_count = 0
    total_time_spent_in_svc = 0
    @total_time_spent_in_eob = 0
    @hourly_eob_count = 0
    @hourly_svc_count = 0
    @total_time_spent = 0
    total_time_spent_in_insurance_eob = 0
    total_time_spent_in_patient_eob = 0
    insurance_eob = JobActivityLog.joins('LEFT OUTER JOIN service_payment_eobs ON service_payment_eobs.insurance_payment_eob_id = job_activity_logs.eob_id LEFT OUTER JOIN eob_qas ON eob_qas.eob_id = job_activity_logs.eob_id AND eob_qas.eob_error_id !=1').where("job_activity_logs.processor_id = ? and job_activity_logs.start_time >= ? and job_activity_logs.activity =? and job_activity_logs.eob_type_id =? ",current_user.id,(Time.now-12.hour),'Processing Started',1). select("sum(time_to_sec(timediff(job_activity_logs.end_time,job_activity_logs.start_time)))AS total_eob_time, count(distinct(job_activity_logs.eob_id)) AS eob_count,count(distinct(service_payment_eobs.id)) AS svc_count,count(distinct(eob_qas.id)) AS qa_count")
    patient_eob_log_info = JobActivityLog.joins('LEFT OUTER JOIN eob_qas ON eob_qas.eob_id = job_activity_logs.eob_id AND eob_qas.eob_error_id !=1').where("job_activity_logs.processor_id = ? and job_activity_logs.start_time >= ? and job_activity_logs.activity =? and job_activity_logs.eob_type_id =? ",124,(Time.now-12.hour),'Processing Started',2). select("sum(time_to_sec(timediff(job_activity_logs.end_time,job_activity_logs.start_time)))AS total_eob_time,count(distinct(job_activity_logs.eob_id)) AS eob_count,count(distinct(eob_qas.id)) AS qa_count")
    unless insurance_eob.nil?
      unless patient_eob_log_info.nil?
        ins_eob_count = insurance_eob.first.eob_count
        pat_eob_count = patient_eob_log_info.first.eob_count
        @eob_count = ins_eob_count + pat_eob_count
        @error_count += insurance_eob.first.qa_count
        @error_count += patient_eob_log_info.first.qa_count
        total_time_spent_in_insurance_eob = insurance_eob.first.total_eob_time
        total_time_spent_in_patient_eob = patient_eob_log_info.first.total_eob_time
        @total_time_spent_in_eob = total_time_spent_in_insurance_eob.to_f + total_time_spent_in_patient_eob.to_f
        if(@total_time_spent_in_eob != 0)
          @total_time_spent = (@total_time_spent_in_eob/3600)
          @hourly_eob_count = (@eob_count/@total_time_spent).round
          svc_start_time_eobs = InsurancePaymentEob.where("svc_start_time >= ? and processor_id =? and processing_completed >=? ", (Time.now-12.hour),current_user.id,(Time.now-12.hour)).select("time_to_sec(timediff(end_time,svc_start_time)) AS total_svc_time ,category AS category")
          svc_start_time_eobs.each do |svc|
            total_time_spent_in_svc += svc.total_svc_time
            claim_svc_count +=1 if(svc.category == 'claim')
          end
          @svc_count = insurance_eob.first.svc_count

          total_time_spent_in_svc = total_time_spent_in_svc/3600
          @hourly_svc_count = (total_time_spent_in_svc != 0 ? (@svc_count/total_time_spent_in_svc).round : 0)

          unless params[:job_id].nil?
            batch_tat = @batch.target_time
            @batch_tat_in_ist =  format_complete_date_and_time(convert_to_ist_time(batch_tat))
            claim_normalization_factor = @facility.details[:claim_normalized_factor]
            svc_normalization_factor = @facility.details[:service_line_normalised_factor]
            claim_normalization_factor = claim_normalization_factor.to_f
            svc_normalization_factor = svc_normalization_factor.to_f
            @normalized_eobs_count = (@eob_count * claim_normalization_factor).round(2)
            if !@svc_count.blank?
              @normalized_svc_count = (@svc_count * svc_normalization_factor).round(2)
            end
          end
          @formated_total_time = to_dot_time(@total_time_spent_in_eob)
        end
      end
    end
  end



  private

  def last_activity
    if current_user
      # user = User.find(current_user)
      user = current_user
      user.last_activity_at = Time.now
      user.save
    end
  end

  #Fetching the images and page no.s corresponding to a job, to be passed to the Applet Viewer
  def get_images(parent_job_id, facility_image_type, job_id)
    logger.debug "get_images ->"
    images  = []

    #Single page tif (1 page = 1 image file)image names are appended to each other with asterisk seperating them ex: abc_1.tif*abc_2.tif*abc_3.tif
    #Multi page tif (all pages = 1 image file)image name is sent as is, by appending page 'from' and 'to' numbers with asterisk seperating them ex: abc.tif*0*20
    if (facility_image_type == 0)
      unless @parent_job_id.blank?
        job = @parent_job
        #in case of split jobs, the split job id is stored in the intermediate table client_images_to_jobs,
        #through which we can fetch the images_to_jobs id where image file name is stored
        job_image_ref = ClientImagesToJob.find(:all,
          :conditions => ["sub_job_id = ?", job_id]).sort!{|a, b| a.updated_at <=> b.updated_at}
        
        job_image_ref = job_image_ref.compact
        if job_image_ref.length > 0
          images_for_job_ids = job_image_ref.map(&:images_for_job_id)
          images = ImagesForJob.get_image_records_in_order(images_for_job_ids)
          images = images.flatten
        end
        images_to_jobs = ClientImagesToJob.select("COUNT(id) AS image_count, id").
          where("job_id = #{parent_job_id} AND sub_job_id IS NOT NULL").group('sub_job_id')
        if !images_to_jobs.blank?
          images_to_job = images_to_jobs.first
          if !images_to_job.blank?
            @image_count_in_a_job = images_to_job.image_count
          end
        end
        pagefrom = job.pages_from.to_s
        pageto = job.pages_to.to_s
      else
        job = @job
        pagefrom = job.pages_from.to_s
        pageto = job.pages_to.to_s
        images = job.images_for_jobs.sort{|a,b| a.image_number <=> b.image_number}
      end

      @single_page_tiff_files = "*"
      images.each do |imagename|
        @single_page_tiff_files += ("*" + imagename.public_filename()).to_s
      end
    elsif (facility_image_type == 1)
      job = @job
      if job.parent_job_id
        imageforjobid = ClientImagesToJob.find_by_job_id(job.parent_job_id).images_for_job_id
      else
        imageforjobid = ClientImagesToJob.find_by_job_id(job_id).images_for_job_id
      end
      pagefrom = job.pages_from.to_s
      pageto = job.pages_to.to_s
      image = ImagesForJob.find(imageforjobid)
      @multi_page_tiff_file = (image.public_filename()).to_s if (image)
      @multi_page_tiff_file +=  "*" + pagefrom + "*" + pageto
    end
    logger.debug "<- get_images"

  end

  # Returns whether particular element has been duplicated in an array
  def element_duplicates?(elem, array)
    first_occurrence = array.index(elem)
    last_occurrence = array.rindex(elem)
    first_occurrence != last_occurrence
  end

  # Returns an array of all the indexes where an element is found, in the given array
  def all_indices(elem, array)
    indices = []
    array.each_with_index do |element, index|
      (indices << index) if element == elem
    end
    indices
  end

  #This is for changing date format from "mm/dd/yy" to "mm/dd/yyyy"
  def format_date(date)   
    (date == "mm/dd/yy" || date == "MM/DD/YY" || date.blank?)? nil : Date.strptime(date, '%m/%d/%y')
  end

  def format_service_date(service_date, default_service_date)
    century_number = ""
    century_number = get_century(service_date, default_service_date)
    unless (service_date == "mm/dd/yy" || service_date == "MM/DD/YY" || service_date.blank?)
      date_array = service_date.strip.split('/')
      if date_array[2].length == 2
        date_year = century_number + date_array[2]
      elsif date_array[2].length == 4
        date_year = date_array[2]
      end
      formatted_date = (date_array[0]+ date_array[1] + date_year).strip
      formatted_date = Date.strptime(formatted_date, '%m%d%Y')
    end
  end

  def get_century(service_date, default_service_date)
    unless default_service_date.blank?
      default_date = default_service_date.strip
      if (default_date != 'Batch Date' && default_date != 'Check Date')
        if(default_date.length == 10)
          default_date_separator = default_date[2,1]
          default_date_array = default_date.split(default_date_separator)
          default_date_month = default_date_array[0]
          default_date_day = default_date_array[1]
          if(default_date_array[2].length == 4)
            default_date_year = default_date_array[2][2,2]
          elsif(default_date_array[2].length == 2)
            default_date_year = default_date_array[2]
          end
          given_date_separator = service_date[2,1]
          given_date_array = service_date.split(given_date_separator)
          given_date_month = given_date_array[0]
          given_date_day = given_date_array[1]
          given_date_year = given_date_array[2]
          if(default_date_month == given_date_month && default_date_day ==  given_date_day && default_date_year == given_date_year)
            century_number = default_date.slice(6, 2)
          end
        end
      end
    end
    if(century_number.blank?)
      year =  Date.today.year
      century_number = year.to_s.slice(0, 2)
    end
    century_number = '20' if century_number.blank?
    return century_number

  end

  def format_ui_param(param)
    param.blank? ? nil : param.strip.upcase
  end

  def normalize_amount(param)
    param.blank? ? nil : param.to_f.round(2)
  end

  def format_amount_ui_param(value)
    if @facility.details[:adjustment_amount_zero]
      value.blank? ? nil : value.to_f.round(2)
    else
      value.to_f.zero? ? nil : value.to_f.round(2)
    end
  end

  # Sets the eob type instance variable
  # this variable is used to hold the type of eob being processed
  # If the check is not associated with a payer yet, then eob type is determined
  # based the tab is chosen by the user, on the UI
  # If a payer is associated with the check then
  # payer id is looked up to determine its type, see CheckInformation#eob_type
  # EOB Type can be 'Insurance' or 'Patient'
  # returns the type current eob if already exists
  # else returns the tab that user chose to enter a new eob
  def eob_type
    if @facility.qualified_to_have_patient_payer? && @check_information
      if @payer_of_check
        is_pat_pay_eob = @check_information.does_check_have_patient_payer?(@facility, @payer_of_check)
      elsif (@check_information.patient_pay_eobs.length >= 1)    
        is_pat_pay_eob = 'Patient'
      else       
        is_pat_pay_eob = display_pat_pay_grid_for_check_with_no_payer?      
      end
    end
    is_pat_pay_eob ? 'Patient' : 'Insurance'
  end

  def display_pat_pay_grid_for_check_with_no_payer?
    session[:tab] = params[:tab]  unless params[:tab].blank?   
    if !session[:tab].blank?     
      session[:tab] == 'patient_pay'
    else
      @check_information.display_patpay_grid_by_default?(@client_name, @facility, @job.payer_group)
    end
  end

end
