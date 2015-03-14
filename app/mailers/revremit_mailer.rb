class RevremitMailer < ActionMailer::Base
  default :from => "admin@revenuemed.com"
  
  def notify_webservice_down hsh
    mail(:to => "cms@revenuemed.com", :subject => "PE webservice is down")    
  end  

  def notify_batch_upload(recipient, subject, filename,facility_name,machine_name,file_size,ip_adder,user_name,bool_ok)
    logger.info "working fine in email...model"
    @filename = filename
    @facility_name = facility_name
    @machine_name = machine_name
    @ip_adder = ip_adder
    @file_size = file_size
    @user_name = user_name
    @bool_ok = bool_ok
    mail(:from =>"revremit_notification@revenuemed.com",:to => recipient, :subject => subject)
  end

  def notify_late_ocr_xml_arrival(check_number, batch_id, batch_name)
    @check_number = check_number
    @batch_id = batch_id
    @batch_name = batch_name
    subject = "OCR XML for check number '#{check_number}' from batch '#{batch_id}' is available for upload"
    mail(:to => $RR_REFERENCES['email']['late_ocr_xml_arrival']['notification'], :subject => subject)
  end

  def notify_837_not_ansi_compliant(file_name, file_location)
    subject = "The 837 file #{file_name} is not ANSI compliant"
    @file_name = file_name
    @file_location = file_location
    mail(:to => $RR_REFERENCES['email']['837_upload']['failure'], :subject => subject)
  end

  def notify_st_se_mismatch(file_name, file_location)
    subject = "The 837 file has a ST/SE mismatch."
    @file_name = file_name
    @file_location = file_location
    mail(:to => $RR_REFERENCES['email']['837_upload']['failure'], :subject => subject)
  end

  def notify_claim_file_loaded(file_name, status, file_location, facility_name, claim_count, svcline_count, zip_file_name, date)
    subject = "The 837 file #{file_name} has been loaded with status: #{status} - #{date}"
    @file_name = file_name
    @file_location = file_location
    @facility_name = facility_name
    @status = status
    @claim_count = claim_count
    @svcline_count = svcline_count
    @zip_file_name = zip_file_name
    if status == "SUCCESS"
      mail(:to => $RR_REFERENCES['email']['837_upload']['success'], :subject => subject)
    else
      mail(:to => $RR_REFERENCES['email']['837_upload']['failure'], :subject => subject)
    end
  end

  def notify_claim_upload(recipient, subject, filename, facility_name, client_name, file_path, old_file, body_content)
    logger.info "working fine in email...model"
    @old_file = old_file
    @filename = filename
    @facility_name = ((facility_name == "") ? "-" : facility_name)
    @file_path = file_path
    @client_name = ((client_name == "") ? "-" : client_name)
    @body_content = body_content
    mail(:from =>"revremit_notification@revenuemed.com",:to => recipient, :subject => subject)
  end

  def notify_wrong_loading(recipient, filename, wrong_facility_name, correct_facility_name)
    logger.info "Wrong facility #{wrong_facility_name} given for loading, but corrected with the right facility and loaded"
    subject = "Wrong facility '#{wrong_facility_name}' used for claim loading"
    @filename = filename
    @wrong_facility_name = ((wrong_facility_name == "") ? "-" : wrong_facility_name)
    @correct_facility_name = ((correct_facility_name == "") ? "-" : correct_facility_name)
    mail(:from =>"revremit_notification@revenuemed.com",:to => recipient, :subject => subject)
  end

  def notify_wrong_xml_format(recipient, filename, errors)
    logger.info "OCR XML file #{filename} does not comply with the Schema. The errors/warnings are #{errors}"
    subject = "OCR XML file #{filename} does not comply with the Schema."
    @filename = filename
    @errors = errors
    mail(:from =>"revremit_notification@revenuemed.com", :to => recipient, :subject => subject)
  end

  def notify_absence_of_sitecode(recipient, filename)
    logger.info "The site code associated with the file '#{filename}' is not found while loading claim file"
    subject = "The site code associated with the file '#{filename}' is not found while loading claim file"
    @filename = filename
    mail(:from =>"revremit_notification@revenuemed.com",:to => recipient, :subject => subject)
  end

  def notify_duplicate(file_name, file_creation_date, file_creation_time, file_location, orig_file_name, trigger)
    subject = "The ACH file #{file_name} received on #{file_creation_date.scan(/../).reverse.join("/")} at #{file_creation_time.scan(/../).join(":")} did not pass validation checks"
    logger.info "#{subject} (#{trigger})"
    @file_name = orig_file_name
    @trigger = trigger
    @file_location = file_location
    mail(:to => $RR_REFERENCES['email']['ach_loading']['notification'], :subject => subject)
  end
  
  def notify_input_batch_duplicate(sender, recipient, subject, duplicate_batch, client_name, facility_name, file_name, is_duplicate_name, arrival_time )
    @duplicate_batch, @client_name, @facility_name, @is_duplicate_name, @file_name, @arrival_time = duplicate_batch, client_name, facility_name, is_duplicate_name, file_name, arrival_time
    mail(:from => sender, :to => recipient, :subject => subject)
  end
  
  def notify_output_generation_status(recipients, subject, batch_id, group_batchids, e, et_params, status)
    @batch_id, @group_batchids, @error, @et_params, @status = batch_id, group_batchids, e, et_params, status 
    mail(:from => "revremit_notification@revenuemed.com", :to => recipients, :subject => subject)
  end

  def notify_output_config_edit_status(old_config,new_config, subject,message)
    @old_details = old_config
    @new_details = new_config
    @message = message
    mail(:from => "revremit_notification@revenuemed.com", :to => $RR_REFERENCES['email']['output_config_edit_status']['notification'], :subject => subject)
  end

  def notify_orbo_batch_edit_nonlockbox_client(file_name,location,subject)
    @batch_file_name = file_name
    @batch_file_location = location
    mail(:from => "revremit_notification@revenuemed.com", :to => $RR_REFERENCES['email']['orbo_batch_edit_nonlockbox_client']['notification'], :subject => subject)
  end

  def notify_fc_config_edit(facility_name, user, feature, edited_time, access_info)
    subject = "Facility #{facility_name} Configuration has been changed"
    @facility_name, @user, @feature, @edited_time, @access_info = facility_name, user, feature, edited_time, access_info
    mail(:to => $RR_REFERENCES['email']['fc_config_edit']['notification'], :subject => subject)
  end

  def notify_fc_edit_permission_grant(edited_user, grant_user, access_info)
    subject = "#{edited_user.name} is given permission to edit Facility Configuration"
    @edited_user, @grant_user, @access_info = edited_user, grant_user, access_info
    mail(:to => $RR_REFERENCES['email']['fc_config_edit']['notification'], :subject => subject)
  end
  

  def notify_inactive_claims(file_name, inactive_claims, claim_file_info)
    subject = "Claims with unidentified Billing Provider NPI - #{file_name}"
    @inactive_claims, @claim_file_info, @file_name = inactive_claims, claim_file_info, file_name
    mail(:to => $RR_REFERENCES['email']['inactive_claims']['notification'], :subject => subject)
  end

  def notify_wrong_rms_kfi_batch_type(recipient, zip_file_name)
    subject = "EOB Lite batch received at KFI batches folder."
    body = "The EOB Lite batch _ #{zip_file_name} has arrived at KFI batches folder. Please take necessary actions."
    mail(:to => recipient, :subject => subject, :body => body)
  end
end
