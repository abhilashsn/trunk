module OperationLog::DataFetcherEob
    include Output835Helper

    def eval_patient_account_number
    if eob
      account_number = captured_or_blank_patient_account_number(eob.patient_account_number, "op_log")
      if config.quote_prefixed && account_number != '-'
        account_number = "'" + account_number
      end
    end
    account_number
  end

  def eval_image_page_no
    eob.blank? ? "-" : eob.image_page_no
  end
  
  def eval_onbase_name
    micr_line_information = check.micr_line_information
    if micr_line_information && micr_line_information.payer
      onbase_name_record = FacilitiesMicrInformation.get_client_or_site_specific_onbase_name_record(micr_line_information.id, @client.id, @facility.id)
      onbase_name = onbase_name_record.onbase_name if onbase_name_record
    end
    onbase_name.blank? ? "-" : onbase_name
  end
  
  def eval_correspondence
    "-"
  end
  
  def eval_sub_total
    ""
  end

  def eval_835_amount
    total_835_amt = 0
    if eob
      total_835_amt += eob.late_filing_charge.to_f
      total_835_amt += eob.total_amount_paid_for_claim.to_f
      if facility.details[:interest_in_service_line].blank?
        total_835_amt += eob.claim_interest.to_f
      end
    end
    total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)    
  end
  
  def eval_statement_number
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
  
  def eval_xpeditor_document_number
    return "-" if eob.blank?
    if eob
      if eob.claim_information && eob.claim_information.xpeditor_document_number
        eob.claim_information.xpeditor_document_number
      else
        patient_account_number = eob.patient_account_number
        if patient_account_number.include? "SOC"
          "OLXP"
        elsif patient_account_number.include? "PCP"
          "E5SA"
        elsif patient_account_number.include? "ENT"
          "G3SA"
        elsif patient_account_number.include? "CRH"
          "CRSA"
        elsif patient_account_number.include? "002/"
          "S3SA"
        else
          "-"
        end
      end
    end
  end
  
  def eval_document_classification
    if eob
      if eob.class == ProviderAdjustment
        document_type = "PLB"
      elsif eob.document_classification && eob.document_classification != '--'
        document_type = eob.document_classification
      end
    end
    document_type.blank? ? '-' : document_type
  end

  def eval_837_file_type
    "-"
  end

  def eval_mrn
    mrn = "-" if eob.blank?
    if eob && eob.medical_record_number
      mrn = eob.medical_record_number
    elsif eob && eob.claim_information && eob.claim_information.medical_record_number
      mrn = eob.claim_information.medical_record_number
    else
      "-"
    end
    mrn.blank? ? "-" : mrn
  end
#print N104(PE) value
  def eval_payee_id
    payee_id = "-"

    if check.payee_npi.present?
      payee_id = check.payee_npi.strip.upcase
    elsif !eob.blank? && !eob.claim_information.blank? && eob.claim_information.npi.present?
      payee_id = eob.claim_information.npi.strip.upcase
    elsif facility.npi.present?
      payee_id = facility.npi.strip.upcase
    elsif check.payee_tin.present?
      payee_id = check.payee_tin.strip.upcase
    elsif !eob.blank? && !eob.claim_information.blank? && eob.claim_information.tin.present?
      payee_id = eob.claim_information.tin.strip.upcase
    elsif facility.tin.present?
      payee_id = facility.tin.strip.upcase
    end
    payee_id
  end

  #The value from NM109 (82)
  def eval_service_provider_id
    service_provider_id = "-"
    if eob && eob.provider_npi.present?
      service_provider_id = eob.provider_npi
    elsif eob && eob.provider_tin.present?
      service_provider_id = eob.provider_tin
    elsif (!eob.blank? && !eob.claim_information.blank? && eob.claim_information.provider_npi.present?)
      service_provider_id = eob.claim_information.provider_npi
    elsif (!eob.blank? && !eob.claim_information.blank? && eob.claim_information.provider_ein.present?)
      service_provider_id = eob.claim_information.provider_ein
    elsif facility.facilities_npi_and_tins.present?
      service_provider_id = get_facility_npi_and_tin
    end
    service_provider_id
  end

  def get_facility_npi_and_tin
    facility_npi_and_tin = facility.facilities_npi_and_tins.first
    if facility_npi_and_tin.npi.present?
      service_provider_id = facility_npi_and_tin.npi
    elsif facility_npi_and_tin.tin.present?
      service_provider_id = facility_npi_and_tin.tin
    end
    service_provider_id
  end

  def eval_tooth_number
    if eob
      if eob.category == "service"
        tooth_number = eob.get_formatted_tooth_number
      elsif eob.category == "claim"
        tooth_number = eob.claim_tooth_number
      end
    end
    tooth_number.blank? ? "-" : tooth_number
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
    '-'
  end

end
