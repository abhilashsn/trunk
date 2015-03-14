module OperationLog::DataFetcherEobWithPlb
  
  def eval_plb_patient_last_name
    if eob
      patient_last_name = eob.qualifier
    end
    patient_last_name.blank? ? '-' : patient_last_name
  end

  def eval_plb_patient_first_name
    if eob
      patient_first_name = eob.description
    end
    patient_first_name.blank? ? '-' : patient_first_name
  end

  def eval_plb_patient_account_number
    if eob
      patient_account_number = eob.patient_account_number
    end
    patient_account_number.blank? ? '-' : patient_account_number
  end

  def eval_plb_835_amount
    total_835_amt = 0
    if eob
      total_835_amt = eob.amount.to_f
    end
    total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
  end

  def eval_plb_xpeditor_document_number
    "-"
  end

  def eval_plb_total_charge
    "-"
  end

  def eval_plb_date_of_service
    "-"
  end

  def eval_plb_reject_reason
    "-"
  end

  def eval_plb_statement__
    "-"
  end

  def eval_plb_reason_not_processed
    "-"
  end

  def eval_plb_member_id
    "-"
  end

  def eval_plb_patient_date_of_birth
    "-"
  end

  def eval_plb_payer
    eval_plb_payer_name
  end

  def eval_plb_payer_name
    return "-" if eob.blank?
    check_payer = check.payer
    if !check_payer.nil?
      if check.job.payer_group.downcase == "patpay"
        payer_name = eob.description + " " + eob.qualifier
      else
        payer_name = get_micr_associated_payer(check_payer)
      end
    end
    payer_name.blank? ? '-' : payer_name
  end

  def eval_plb_837_file_type
    "-"
  end

  def eval_plb_plb
    "Yes"
  end

  def eval_plb_unique_identifier
    "-"
  end

  def eval_plb_client_code
    "-"
  end

  def eval_plb_mrn
    "-"
  end

  def eval_plb_service_provider_id
    service_provider_id = "-"
    related_insurance_eob = eob.insurance_payment_eob
    if eob && related_insurance_eob && related_insurance_eob.provider_npi.present?
      service_provider_id = related_insurance_eob.provider_npi
    elsif eob && related_insurance_eob && related_insurance_eob.provider_tin.present?
      service_provider_id = related_insurance_eob.provider_tin
    elsif (!eob.blank? && !related_insurance_eob.blank? &&
          !related_insurance_eob.claim_information.blank? &&
          related_insurance_eob.claim_information.provider_npi.present?)
      service_provider_id = related_insurance_eob.claim_information.provider_npi
    elsif (!eob.blank? && !related_insurance_eob.blank? &&
          !related_insurance_eob.claim_information.blank? &&
          related_insurance_eob.claim_information.provider_ein.present?)
      service_provider_id = related_insurance_eob.claim_information.provider_ein
    elsif facility.facilities_npi_and_tins.present?
      service_provider_id = get_facility_npi_and_tin
    end
    service_provider_id
  end

  def eval_plb_transaction_type
    "-"
  end
  
end
