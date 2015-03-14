module OperationLog::DataFetcherCheck

  def method_missing(sym, *args, &block)
    #@subject.send sym, *args, &block
    #puts ">>>>>>>>>>>>>>>>>>>\n"
    #puts "The method called does not exist ........"
    #puts sym.to_s + " " 
    #puts ">>>>>>>>>>>>>>>>>>>\n"
    return "method missing .."

  end

  def eval_facility_name
    check.batch.facility.name
  end
  
  def eval_check
    (@index+1).to_s
  end

  def eval_batch_name
    batch = check.batch
    batch.batchid.blank? ? "-" : batch.real_batch_id
  end

  def eval_batch_id
    #check.batch.id
    eval_batch_name
  end

  def eval_export_date
    Time.now.strftime('%m/%d/%Y')    
  end

  def eval_check_serial_number
    "index not done"
  end

  def eval_check_number
    chk_number = check.check_number.blank? ? "-" : check.check_number
    if config.quote_prefixed and check.check_number
      chk_number = "'"+chk_number
    end
    chk_number    
  end

  def eval_check_amount
    eft_amount =  config.header_fields.index{|x| x.first == "Eft Amount"}
    if eft_amount && check.payment_method == 'EFT'
      check_amount = "-"
    else
      check_amount = check.check_amount.to_f
    end
    (check_amount.blank? || check_amount == "-") ? "-" : sprintf("%.2f", check_amount)
  end
  

  def eval_eft_amount
    if check.payment_method == 'EFT'
      eft_amount = check.check_amount.to_f
    else
      eft_amount = "-"
    end
    (eft_amount.blank? || eft_amount == "-") ? "-" : sprintf("%.2f", eft_amount)
  end

  def eval_payer_name
    payer_name = get_payer_name
    payer_name.blank? ? '-' : payer_name    
  end

  def get_payer_name
    check_payer = check.payer
    payer_name = ""
    unless check_payer.nil?
      if check.job.payer_group.present? && check.job.payer_group.downcase == "patpay"
        facility_output_config = facility.facility_output_configs.where("(report_type != 'Operation Log' or report_type is null) and
                            eob_type = 'Patient Payment'").first rescue nil
        default_patient_name = facility_output_config.details[:default_patient_name] rescue nil
        payer_name = default_patient_name.present? ? default_patient_name : "patpay"
      else
        payer_name = get_micr_associated_payer(check_payer)
      end
    end
    return payer_name
  end

  def get_micr_associated_payer(check_payer)
    is_micr_payer_present = micr && micr.payer && facility.details[:micr_line_info]
    payer_name = is_micr_payer_present ? micr.payer.payer : check_payer.payer
    payer_name
  end

  def eval_status
    label=  config.get_label_for("Status")
    yorn=false
    if label && label.downcase.strip.starts_with?("processed")
      yorn = true
    end
    if check.job.job_status == JobStatus::COMPLETED
      status =  yorn ? "Y": "Accept"
    elsif check.job.job_status == JobStatus::INCOMPLETED
      status =  yorn ? "N": "Reject"
    elsif check.job.job_status == JobStatus::EXCLUDED
      status = "Reject" 
    else
      status = "-"
    end
    status    
  end

  def eval_processed__y_n_
    if check.job.job_status == JobStatus::COMPLETED
      status =  "Y"
    elsif check.job.job_status == JobStatus::INCOMPLETED
      status =  "N"
    else
      status = "-"
    end
    status    
  end

  def eval_image_id
    job = check.job
    job.initial_image_name unless job.initial_image_name.blank?
  end

  def eval_reason_not_processed
    eval_reject_reason
  end

  def eval_reject_reason
    reject_reason = "-"
    if check && check.job && check.job.job_status == JobStatus::EXCLUDED
      reject_reason = "ERA Payer"
    else
      if check.job.rejected_comment != "null" and
          !check.job.rejected_comment.blank? and
          check.job.rejected_comment != "--" and
          (check.job.job_status == JobStatus::INCOMPLETED or check.job.job_status == JobStatus::COMPLETED)
        reject_reason = check.job.rejected_comment.strip
      end
    end
    reject_reason  
  end


  def eval_835_amount
    total_835_amt = 0
    insurance_payment_eobs = check.insurance_payment_eobs
    patient_pay_eobs = check.patient_pay_eobs
    unless insurance_payment_eobs.blank?
      insurance_payment_eobs.each do |ins_pay_eob|
        total_835_amt += ins_pay_eob.total_amount_paid_for_claim.to_f
        total_835_amt += ins_pay_eob.late_filing_charge.to_f
        if facility.details[:interest_in_service_line].blank?
          total_835_amt += ins_pay_eob.claim_interest.to_f
        end
      end
    end
    unless patient_pay_eobs.blank?
      patient_pay_eobs.each do |pat_pay_eob|
        total_835_amt += pat_pay_eob.stub_amount.to_f
      end
    end
    total_835_amt += check.provider_adjustment_amount.to_f
    total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
  end

  def eval_deposit_date
    check.batch.bank_deposit_date.blank? ? "-" : check.batch.bank_deposit_date.strftime("%m/%d/%Y")
  end

  def eval_aba_routing_number
    unless micr.blank?
      routing_number = micr.aba_routing_number.blank? ? "-" : micr.aba_routing_number
      if config.quote_prefixed and micr.aba_routing_number
        routing_number = "'" + routing_number
      end
      routing_number
    else
      "-"
    end
  end

  def eval_payer_account_number    
    unless micr.blank?
      account_number = micr.payer_account_number.blank? ? "-" : micr.payer_account_number
      if config.quote_prefixed and micr.payer_account_number
        account_number = "'" + account_number
      end
      account_number
    else
      "-"
    end
  end

  def eval_check_date
    check.check_date.blank? ? "-" : check.check_date.strftime("%m/%d/%Y")
  end

  def eval_zip_file_name
    check.batch.file_name.blank? ? "-" : check.batch.file_name
  end

  def eval_patient_account_number
    "-"
  end

  def eval_page_number
    "-"
  end

  def eval_sub_total
    ""
  end
  
  def eval_onbase_name
    "-"
  end
  
  def eval_correspondence
    "-"
  end
  
  def eval_statement__
    "-"
  end
  
  def eval_harp_source
    "-"
  end
  
  def eval_patient_last_name
    "-"
  end
  
  def eval_patient_first_name
    "-"
  end
  
  def eval_member_id
    "-"
  end

  def eval_client_code
    "-"
  end
  
  def eval_patient_date_of_birth
    "-"
  end
  
  def eval_total_charge
    "-"
  end
  
  def eval_date_of_service
    "-"
  end

  def eval_payer
    eval_payer_name
  end

  def eval_first_payer_name

    if @checks.size > 0
      payer_name_for_check @checks.first
    else
      ""
    end
  end


  def payer_name_for_check (chk)
    client_name = facility.client.name  
    check_payer = chk.payer
    payer_name = ""
    unless check_payer.nil?
      if chk.job.payer_group.downcase == "patpay" && client_name.downcase != "quadax"
        payer_name = "PATPAY"
      else
        micr = chk.micr_line_information
        is_micr_payer_present = micr && micr.payer && facility.details[:micr_line_info]
        payer = is_micr_payer_present ? micr.payer : check_payer
        if client_name.downcase == "goodman campbell"
          if payer.output_payid(facility) == "REVMED"
            payer_name = "MISCPAYER"
          else
            payer_name = payer.payer
          end
        else
          payer_name = payer.payer
        end
      end
    end
    payer_name.blank? ? '-' : payer_name
  end


  def payer_name_for_check_v2(chk)
    client_name = facility.client.name  
    check_payer = chk.payer
    payer_name = ""
    unless check_payer.nil?
      if chk.job.payer_group.downcase == "patpay" && client_name.downcase != "quadax"
        payer_name = "self pay 835 format"
      else
        micr = chk.micr_line_information
        is_micr_payer_present = micr && micr.payer && facility.details[:micr_line_info]
        payer_name = is_micr_payer_present ? micr.payer.payer : check_payer.payer
      end
    end
    payer_name.blank? ? '-' : payer_name        
  end

  def eval_837_file_type
    "-"
  end

  def eval_mrn
    "-"
  end
  
  def eval_xpeditor_document_number
    "-"
  end

  #The value from BPR04
  def eval_payment_method
    payment_method = check.payment_method
    if payment_method == "CHK" || payment_method == "OTH"
      "CHK"
    elsif check.check_amount.to_f.zero?
      "NON"
    elsif (check.check_amount.to_f > 0 && payment_method == "EFT")
      "ACH"
    else
      "-"
    end
  end

  #The value from BPR01
  def eval_payment_trans_code
    if (check.check_amount.to_f > 0 && check.payment_method == "CHK")
      "C"
    elsif (check.check_amount.to_f.zero?)
      "H"
    elsif (check.check_amount.to_f > 0 && check.payment_method == "EFT")
      "I"
    elsif (check.payment_method == "OTH")
      "D"
    else
      "-"
    end
  end

  def eval_payee_id
    "-"
  end

  def eval_service_provider_id
    "-"
  end

  def eval_tooth_number
    "-"
  end

  def eval_lockbox_id
    '-'
  end

  def eval_sequence
    '-'
  end

  def eval_account_type
    '-'
  end

  def eval_image_no
    job = check.job
    images_for_job = job.images_for_jobs.first unless job.images_for_jobs.blank?
    !images_for_job.blank? and !images_for_job.actual_image_number.blank? ? images_for_job.actual_image_number : ''
  end

  def eval_plb
    "No"
  end
end
