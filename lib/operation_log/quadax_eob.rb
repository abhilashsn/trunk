module OperationLog
  module QuadaxEob

    def eval_correspondence
      (check.payment_method == 'EFT' || check.payment_method == 'COR') ? 'YES' : 'NO'
    end
    
    def eval_reject_reason
      return "ERA PAYER" if check && check.job.job_status == "EXCLUDED"
      return "-" if eob.blank?
      eob.rejection_comment.blank? ? "-" : eob.rejection_comment
    end

    def eval_statement__
      payer = check.payer unless check.payer.blank?
      if eob && !payer.blank? && check.job.payer_group.downcase == "patpay"
        eob.claim_number.blank? ? "-" : eob.claim_number
      else
        "-"
      end
    end
    
    def eval_harp_source
      payer = check.payer unless check.payer.blank?
      if !payer.blank? && check.job.payer_group.downcase == "patpay"
        check.payment_type.blank? ? "-" : check.payment_type.downcase == 'check' ? "CX" : "MO"
      else
        "-"
      end
    end
    
    def eval_patient_last_name
      if eob
        if eob.patient_last_name
          patient_last_name = eob.patient_last_name
        elsif eob.claim_information && eob.claim_information.patient_last_name
          patient_last_name = eob.claim_information.patient_last_name
        end
      end
      captured_or_blank_patient_last_name(patient_last_name, "op_log")
    end
    
    def eval_patient_first_name
      if eob
        if eob.patient_first_name
          patient_first_name = eob.patient_first_name
        elsif eob.claim_information && eob.claim_information.patient_first_name
          patient_first_name = eob.claim_information.patient_first_name
        end
      end
      captured_or_blank_patient_first_name(patient_first_name, "op_log")
    end
    
    def eval_member_id
      if eob
        if eob.subscriber_identification_code
          member_id = eob.subscriber_identification_code
        elsif eob.claim_information && eob.claim_information.insured_id
          member_id = eob.claim_information.insured_id
        end
      end
      member_id.blank? ? '-' : member_id
    end
    
    def eval_patient_date_of_birth
      if eob && eob.claim_information && eob.claim_information.date_of_birth
        patient_date_of_birth = eob.claim_information.date_of_birth
      end
      patient_date_of_birth.blank? ? '-' : patient_date_of_birth
    end
    
    def eval_total_charge
      if eob
        if eob.total_submitted_charge_for_claim
          total_charges = eob.total_submitted_charge_for_claim.to_f
        elsif eob.claim_information && eob.claim_information.total_charges
          total_charges = eob.claim_information.total_charges.to_f
        end
      end
      total_charges.blank? ? '-' : total_charges
    end
    
    def eval_date_of_service
      begin
        if eob
          Output835.oplog_log.info "Patient Account Number of EOB : #{eob.patient_account_number}"
          if eob.category == "service"
            Output835.oplog_log.info "Getting Least date of service from the svc's of eob : #{eob.id}"
            date_of_service = captured_or_blank_date(eob.least_date_for_eob_svc_line)
          elsif eob.category == "claim"
            Output835.oplog_log.info "Getting Claim from date of claim level eob : #{eob.id}"
            date_of_service = eob.claim_from_date
          end
        elsif eob && eob.claim_information
          Output835.oplog_log.info "Getting Least date of MPI svc's of eob : #{eob.id}"
          date_of_service = eob.claim_information.least_date_for_mpi_svc_line
        end
        date_of_service.blank? ? '-' : date_of_service
      rescue Exception => e
        Output835.oplog_log.info "Date of service is missing"
        Output835.oplog_log.error e.message
      end
    end
    
    def eval_payer_name
      return "-" if eob.blank?
      check_payer = check.payer
      unless check_payer.nil?
        if  check.job.payer_group.downcase == "patpay"
          payer_name = eob.patient_first_name + " " + eob.patient_middle_initial + " " + eob.patient_last_name
          facility_output_config = facility.facility_output_configs.where("(report_type != 'Operation Log' or report_type is null) and
                            eob_type = 'Patient Payment'").first rescue nil
          default_patient_name = facility_output_config.details[:default_patient_name] rescue nil
          payer_name = default_patient_name.present? ? default_patient_name : payer_name
        else
          payer_name = get_micr_associated_payer(check_payer)
        end
      end
      payer_name.blank? ? '-' : payer_name    
    end
    
    # Method to print aggregated multipage image name in the operation log
    
    def eval_image_id
      image_name_with_extension(job)
    end
    
    def eval_document_classification
      if eob.class == ProviderAdjustment
        first_eob_of_check = check.insurance_payment_eobs.first
        document_classificn_of_eob = first_eob_of_check.document_classification
        document_type = document_classificn_of_eob if document_classificn_of_eob &&
                                          document_classificn_of_eob != '--'
      elsif eob.document_classification && eob.document_classification != '--'
        document_type = eob.document_classification
      end
      document_type.blank? ? '-' : document_type
    end

    def eval_837_file_type
      if eob && eob.claim_information && eob.claim_information.claim_file_information
        claim_file_type = eob.claim_information.claim_file_information.claim_file_type
      end
      claim_file_type.blank? ? '-' : claim_file_type
    end
    
    def eval_client_code
      client_code = facility.sitecode
      client_code.blank? ? '-' : client_code
    end

    def eval_unique_identifier
      return "-" if eob.blank?
      if eob
        eob.uid
      end
    end

    def eval_lockbox_id
      batch_id = batch.batchid
      if batch_id.include?("_")
        batch_id_array = batch_id.split('_')
        batch_id_array_length = batch_id_array.length
        lockbox_id = batch_id_array.first(3).join('_') if batch_id_array_length == 6
      end
      lockbox_id ||= '-'
    end

    def eval_835_amount
      total_835_amt = 0
      total_835_amt += eob.total_amount_paid_for_claim.to_f if eob
      total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
    end

    def eval_transaction_type
      payer = check.payer unless check.payer.blank?
      if !payer.blank? && check.job.payer_group.downcase == "patpay"
        "Patient Pay"
      elsif check.job.job_status.upcase == "COMPLETED"
        "Insurance"
      elsif check.job.job_status.upcase == "INCOMPLETED"
        "Correspondence"
      end
    end

    def captured_or_blank_date(date)
      if facility.date_of_service_default_match?
        return date == facility.date_of_service_default_match ? '' : date
      end
      date
    end

  end

end
