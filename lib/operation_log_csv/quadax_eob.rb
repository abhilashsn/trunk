class OperationLogCsv::QuadaxEob < OperationLogCsv::Eob
  def onbase_name
    if operation_log_config.details[:onbase_name]
      if check.micr_line_information && check.micr_line_information.payer
        onbase_name = check.micr_line_information.payer.onbase_name
      else
        onbase_name = "-"
      end
      onbase_name.blank? ? "-" : onbase_name 
    end
  end
 
  def correspondence
    if operation_log_config.details[:correspondence]
      check.correspondence? ? 'YES' : 'NO'     
    end
  end

  def reject_reason
    if operation_log_config.details[:reject_reason]
      eob.rejection_comment.blank? ? "-" : eob.rejection_comment
    end
  end
  
  #Method to display 'Statement Number' in the operation log of Self pay checks,
  #which is captured and stored using the claim_number field of insurance_payment_eobs table.
  
  def statement_number
    if operation_log_config.details[:statement_number]
      payer = check.payer unless check.payer.blank?
      if !payer.blank? && payer.payer_type.downcase == "patpay"
        eob.claim_number.blank? ? "-" : eob.claim_number
      else
        "-"
      end
    end
  end
  
  #Method to display 'Harp Source' in the operation log of Self pay checks,
  #which is captured and stored using the payment type field of check_informations table.
  
  def harp_source
    if operation_log_config.details[:harp_source]
      payer = check.payer unless check.payer.blank?
      if !payer.blank? && payer.payer_type.downcase == "patpay"
        check.payment_type.blank? ? "-" : check.payment_type.downcase == 'check' ? "CX" : "MO"
      else
        "-"
      end
    end
  end

  def payer_name
    if operation_log_config.details[:payer_name]
      check_payer = check.payer
      unless check_payer.nil?
       
       if  check_payer.payer_type.downcase == "patpay"
         payer_name = eob.patient_first_name + " " + eob.patient_middle_initial + " " + eob.patient_last_name
        else
          is_micr_payer_present = micr && micr.payer && facility.details[:micr_line_info]
          payer_name = is_micr_payer_present ? micr.payer.payer : check_payer.payer
        end
      end
      payer_name.blank? ? '-' : payer_name
    end
  end
  
end
