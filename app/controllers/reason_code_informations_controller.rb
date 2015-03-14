class ReasonCodeInformationsController < ApplicationController
  layout 'datacapture'
  include ApplicationHelper
 
  
  def list

    @job = Job.includes(:batch => {:facility => :client}).find(params[:job_id])
    parent_job_id = @job.get_parent_job_id
    check_information = CheckInformation.includes(:payer, :insurance_payment_eobs).find_by_job_id(parent_job_id)   
    @check_payer = check_information.payer
    @batch = @job.batch
    @facility = @batch.facility
    @client = @facility.client
    @is_partner_bac = $IS_PARTNER_BAC

    @reason_codes = ReasonCodesJob.get_valid_reason_codes parent_job_id
    @total_hipaa_and_unique_codes_of_parent_job = get_valid_hipaa_codes_and_unique_codes_in_job(@reason_codes)
    render :partial => "list"
  end


  # Method to create new reason code records with reason_code and reason_code_description
  # in reason_codes table if its a new record. After that creates associated records
  # in reason_code_jobs and reason_code_payers table
  # if association not already exists. using the methods
  # create_reason_code_jobs(reason_code_id, job),
  
  def create
    job_id = params[:job_id]
    job = Job.find(job_id)
    client_name = params[:client_name]
    activity = JobActivityLog.new
    activity.current_user_id = current_user.id if current_user
    reason_code_value = params[:reason_code][:reason_code].to_s.strip
    reason_code_description = params[:reason_code][:reason_code_description].to_s.strip
    reason_code_params = !reason_code_value.blank? && !reason_code_description.blank?
    check_information = job.check_information
    check_information_id = check_information.id
    payer_id = cookies[:payer_id].to_s.strip
    payer_name = params[:rc_payer][:popup].to_s.strip
    address_one = params[:rc_payer][:pay_address_one].to_s.strip
    address_two = params[:rc_payer][:pay_address_two].to_s.strip
    city = params[:rc_payer][:payer_city].to_s.strip
    state = params[:rc_payer][:payer_state].to_s.strip
    zip = params[:rc_payer][:payer_zip].to_s.strip
    image_from = params[:rc_payer][:job_image_from].strip.to_i
    parent_job_exists = !job.parent_job_id.blank?
    if client_name.upcase == 'MEDASSETS' || client_name.upcase == 'BARNABAS'
    rc_page_no = params[:eob_reason_codes][:page_no].strip.to_i
    end
    payer_address_fields = {
      :address_one => address_one,
      :city => city,
      :state => state,
      :zip_code => zip
    }
    valid_payer_address, statement_to_alert = validate_payer_address(payer_address_fields)
    valid_payer = !payer_name.blank? && valid_payer_address
    if valid_payer
      payer_details = {:name => payer_name,
        :address_one => !address_one.blank? ? address_one : nil,
        :address_two => !address_two.blank? ? address_two : nil,
        :city => !city.blank? ? city : nil,
        :state => !state.blank? ? state : nil,
        :zip => !zip.blank? ? zip : nil }
    
      invalid_payer_id = (payer_id == 'null' || payer_id.blank? || payer_id == 'undefined')
      if invalid_payer_id
        payer_object = Payer.get_payer_object(payer_details)
        payer_id = payer_object.id unless payer_object.blank?
      end
      valid_payer_id = (payer_id != 'null' && !payer_id.blank? && payer_id != 'undefined')
      if valid_payer_id
        payer = Payer.find(payer_id)
        payer_name = payer.payer
        set_name = payer.reason_code_set_name
        payer_footnote_indicator = payer.footnote_indicator
      else
        payer_name = nil

        if parent_job_exists
          set_name = ReasonCodeSetName.find_or_create_by_name("JOB_#{job.parent_job_id}_SET")
        else
          set_name = ReasonCodeSetName.find_or_create_by_name("JOB_#{job.id}_SET")
        end
        payer_footnote_indicator = false
      end
    
      unless set_name.blank?
        set_name_id = set_name.id 
        if reason_code_params
          if (reason_code_value.match(/^[A-Za-z0-9\-\.\_]*$/) &&
                !reason_code_value.match(/\.{2}|\_{2}|\-{2}^[\-\.\_]+$/))
            if does_default_reason_code_duplicated?(reason_code_value.upcase, reason_code_description.upcase)
              reason_code = ReasonCode.get_reason_code(reason_code_value, reason_code_description, set_name, payer)
              if reason_code.blank?
                parameters = { :check_id => check_information.id,
                  :check_number => check_information.check_number,
                  :set_name_id => set_name_id, :payer_name => payer_name,
                  :job_id => job.id, :facility_name => params[:facility_name]}
                if params[:batch].present?
                  batchid_and_date = params[:batch].split(',')
                  parameters[:batchid] = batchid_and_date[0]
                  parameters[:batch_date] = batchid_and_date[1]
                end
                  
                reason_code = ReasonCode.create_reason_code(reason_code_value, reason_code_description, parameters)
                create_eob_reason_codes(reason_code.id, rc_page_no, job_id) if client_name.upcase == 'MEDASSETS' || client_name.upcase == 'BARNABAS'
                create_reason_code_jobs(reason_code.id, job)
                rc_job_record = ReasonCodesJob.find_by_reason_code_id_and_parent_job_id(reason_code.id, job.get_parent_job_id)
                if !rc_job_record.blank?
                  rc_job_record.update_attributes(:existence => false)
                end
              else
                reason_code.update_reason_code(reason_code_value, reason_code_description, payer_footnote_indicator, check_information_id)
                 create_eob_reason_codes(reason_code.id, rc_page_no, job_id) if client_name.upcase == 'MEDASSETS' || client_name.upcase == 'BARNABAS'
                create_reason_code_jobs(reason_code.id, job)
                rc_job_record = ReasonCodesJob.find_by_reason_code_id_and_parent_job_id(reason_code.id, job.get_parent_job_id)
                if !rc_job_record.blank?
                  rc_job_record.update_attributes(:existence => true)
                end
              end
              if reason_code.unique_code.blank?
                unique_code = reason_code.get_unique_code
                reason_code.update_attributes(:unique_code => unique_code)
              end
            else
              flash[:notice] = "Default Reason Code & Reason Code Description are already created"
            end
          else
            flash[:notice] = "Please try again with valid value as follows : Reason Code should contain alphabet, number, hyphen, underscore and period only."
          end
        else
          flash[:notice] = "Reason Code & Reason Code Description cannot be blank"
        end
      else
        flash[:notice] = "Reason Code should have a set name"
      end
    else
      flash[:notice] = "PAYER NAME IS MANDATORY. " + statement_to_alert.to_s.upcase
    end
    redirect_to :action => "list", :job_id => job_id
  end
  
  def create_reason_code_jobs(reason_code_id, job)
    job_id = job.id
    parent_job_id = job.parent_job_id
    batch = job.batch
    facility = batch.facility
    check_information = job.check_information
    payer = check_information.payer
    payer_id = payer.id unless payer.blank?
    if parent_job_id.blank?
      parent_job_id = job_id
      sub_job_id = ""
    else
      parent_job_id = parent_job_id
      sub_job_id = job_id
    end
    unless reason_code_id.blank?
      reason_codes_job_exists = ReasonCodesJob.find_by_reason_code_id_and_parent_job_id(reason_code_id, parent_job_id)
      if reason_codes_job_exists.blank?
        reason_code_jobs = ReasonCodesJob.create(:reason_code_id => reason_code_id, :parent_job_id => parent_job_id,
          :sub_job_id => sub_job_id)
      end
      
      unless payer_id.blank?
        if (!@is_partner_bac && facility.details[:hipaa_code] && current_user.has_role?(:qa))
          hipaa_code = params[:hipaa_code][:hipaa_adjustment_code]
          associate_hipaa_codes(reason_code_id, payer, hipaa_code) unless hipaa_code.blank?
        end
      end
      
      unless reason_code_jobs.blank?
        flash[:notice] = "Reason Code created successfully."
      else
        flash[:notice] = "Reason Code Existing."
      end
    end
  end

  def create_eob_reason_codes reason_code_id, page_no, job_id
    unless reason_code_id.blank?
      EobReasonCode.create(:reason_code_id => reason_code_id, :page_no => page_no, :job_id => job_id)
    end
  end
  
  # Method to create association of reason codes with hipaa codes.
  # If the Partner is Non-BAC and if the role of user is QA and if hipaa mapping
  # is selcted for that facility, then a text field for selecting existing
  # hipaa codes is enabled in RC Grid and those hipaa code can be mapped
  # to a reason code through RC grid .Not able to create new hipaa codes from RC UI,
  # only association of existing ones can be done.
  
  def associate_hipaa_codes(reason_code_id, payer, hipaa_code)
    reason_code = ReasonCode.find(reason_code_id)
    set_name = payer.reason_code_set_name
    reasoncodes_clients_facilities_setname = ReasonCodesClientsFacilitiesSetName.
      find_or_create_by_reason_code_id(reason_code.id)
    crosswalk_item = ReasonCodeService::CrosswalkItem.new
    crosswalk_item.ansi_code = hipaa_code
    crosswalk_item.active = true
    reasoncodes_clients_facilities_setname.save_crosswalks(crosswalk_item, reason_code, set_name)
  end

  def destroy
    job_id = params[:job_id]
    job = Job.find(job_id)
    batch = job.batch
    facility = batch.facility
    reason_code_id = params[:reason_code_id]
    reason_code = ReasonCode.find(reason_code_id)
    check_information = job.check_information
    payer = check_information.payer
    set_name = payer.reason_code_set_name unless payer.blank?
    parent_job_id = job.get_parent_job_id
    eob_slno_for_primary_and_secondary_reason_codes  = job.get_eob_slno_for_reason_codes(reason_code_id)
    # Handling reason code association from reason_codes_jobs table during reason code deletion click.
    # If that the reason code for deletion is not at all associated with any eob or svc, then
    # Deleting associated reason code record from reason_codes_jobs table.
    # Setting marked_for_deletion as true in reason_codes table for that associated reason code record.
    # Not deleting reason code from reason_codes master table.
    if eob_slno_for_primary_and_secondary_reason_codes.blank?
      reason_codes_job = ReasonCodesJob.find_by_reason_code_id_and_parent_job_id(reason_code_id, parent_job_id)
      reason_code = ReasonCode.find_by_id_and_check_information_id_and_status(reason_code_id, check_information.id, 'NEW')
      if !reason_code.blank? && reason_codes_job.existence != true
        eob_rc_record = EobReasonCode.find_by_reason_code_id_and_job_id(reason_code_id, job_id)
      end
      reason_codes_job.destroy unless reason_codes_job.blank?
      # Deleting hipaa code association while deleting a reason code is as follows:
      # Should set the active indicator to false in the reason_codes_clients_facilities_set_names table.
      
      if (!@is_partner_bac && facility.details[:hipaa_code] && current_user.has_role?(:qa))
        reasoncodes_clients_facilities_setname = ReasonCodesClientsFacilitiesSetName.
          find_by_reason_code_id(reason_code_id)
        unless reasoncodes_clients_facilities_setname.blank?
          crosswalk_item = ReasonCodeService::CrosswalkItem.new
          crosswalk_item.active = false
          reasoncodes_clients_facilities_setname.save_crosswalks(crosswalk_item, reason_code, set_name)
        end
      end
      set_inactive_in_eob_reason_code job, reason_code_id
      flash[:notice] = "Reason code job association deleted successfully."
    else
      eob_slno_for_primary_and_secondary_reason_codes = eob_slno_for_primary_and_secondary_reason_codes.join(",")
      flash[:notice] = "Cannot delete Reason code job association as this is associated with EOB: #{eob_slno_for_primary_and_secondary_reason_codes}"
    end
    redirect_to :action => "list", :job_id => job_id
  end


  def set_inactive_in_eob_reason_code job, reason_code_id
    parent_job_exists = !job.parent_job_id.blank?

    if parent_job_exists
      jobid =  job.parent_job_id
    else
      child_job_exists = Job.exists?(:parent_job_id => job.parent_job_id)
      jobid = job.id if child_job_exists
    end

    unless jobid.blank?
      job_ids = Job.where(:parent_job_id => jobid).map(&:id)
      job_ids << jobid
      eob_rc_record = EobReasonCode.where("reason_code_id = ? and job_id in (?) ", reason_code_id, job_ids)
      eob_rc_record.update_all(:active => 0) unless eob_rc_record.blank?
    end
  end
  
  def auto_complete_for_reason_code_reason_code
    reason_code = params[:reason_code][:reason_code]
    auto_complete_for_reasoncode(reason_code)
  end

  def auto_complete_for_reason_code_reason_code_description
    reason_code_desc = params[:reason_code][:reason_code_description]
    auto_complete_for_reasoncode_desc(reason_code_desc)
  end
  
  # Auto Complete for Hipaacode of Reason Code Grid used for non bank only.
  def auto_complete_for_hipaa_code_hipaa_adjustment_code
    hipaa_code = params[:hipaa_code][:hipaa_adjustment_code]
    auto_complete_for_hipaacode(hipaa_code)
  end

  def auto_complete_for_reasoncode(reason_code)
    begin
      payer_id = cookies[:payer_id]
      payer = Payer.find(payer_id) unless payer_id.blank?
      rc_set_name_id = payer.reason_code_set_name_id
      if $IS_PARTNER_BAC
        conditions = "reason_codes.status = 'ACCEPT' && "
      else
        conditions = ""
      end
      conditions += "reason_codes.reason_code_set_name_id = #{rc_set_name_id} && reason_codes.reason_code like ? && reason_codes.active = 1"
      @reason_codes = ReasonCode.find(:all, :conditions => [conditions, reason_code.to_s+'%'],
        :select => ['reason_codes.id, reason_codes.reason_code, reason_codes.reason_code_description'],
        :order => "reason_codes.id ASC", :limit => 10)
    rescue
      @reason_codes = nil
    end
    render :partial => 'auto_complete_for_reasoncode'
  end

  def auto_complete_for_reasoncode_desc(reason_code_description)
    begin
      payer_id = cookies[:payer_id]
      payer = Payer.find(payer_id) unless payer_id.blank?
      rc_set_name_id = payer.reason_code_set_name_id
      if $IS_PARTNER_BAC
        conditions = "reason_codes.status = 'ACCEPT' && "
      else
        conditions = ""
      end
      conditions += "reason_codes.reason_code_set_name_id = #{rc_set_name_id} && reason_codes.reason_code_description like ? && reason_codes.active = 1"
      @reason_codes = ReasonCode.find(:all, :conditions => [conditions, reason_code_description.to_s+'%'],
        :select => ['reason_codes.id, reason_codes.reason_code, reason_codes.reason_code_description'],
        :order => "reason_codes.id ASC", :limit => 10)
    rescue
      @reason_codes = nil
    end
    render :partial => 'auto_complete_for_reasoncode_desc'
  end
  
  # Type ahead in the HIPAA code field in RC Grid to retrieve all hipaa codes in the master hipaa codes table.
  def auto_complete_for_hipaacode(hipaa_code)
    begin
      conditions = "hipaa_codes.active_indicator = 1 and hipaa_codes.hipaa_adjustment_code like ?"
      @hipaa_codes = HipaaCode.find(:all, :conditions => [conditions, hipaa_code.to_s+'%'],
        :select => ['hipaa_codes.id, hipaa_codes.hipaa_adjustment_code, hipaa_codes.hipaa_code_description'],
        :order => "hipaa_codes.id ASC", :limit => 10)
    rescue
      @hipaa_codes = nil
    end
    render :partial => 'auto_complete_for_hipaacode'
  end

  # A predicate method that validates for unique occurence of default reason codes
  # Input :
  # code : reason code entered
  # description : reason code description entered
  # Output :
  # result : result of validation
  def does_default_reason_code_duplicated?(code, description)
    result = true
    if !$IS_PARTNER_BAC
      default_reason_codes = [['1',  'DEDUCTIBLE AMOUNT'], ['2', 'COINSURANCE AMOUNT'], ['3', 'CO-PAYMENT AMOUNT']]
      if params[:facility_name] == "HORIZON EYE"
        default_reason_codes << ['46', "This service is not covered"]
      else
        default_reason_codes << ['23', 'The impact of prior payer(s) adjudication including payments and/or adjustments']
      end
      default_reason_codes.each do |reason_code|
        default_code = reason_code[0]
        default_description = reason_code[1]
        if default_code == code && default_description == description
          result = false
          break
        end        
      end
    end
    result
  end
  
end

