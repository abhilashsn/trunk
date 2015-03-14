class Output835::HlscEob < Output835::Eob
  #Supplies information common to all services of a claim
  def claim_payment_information
    clp_elements = []
    clp_elements << 'CLP'
    clp_elements << eob.patient_account_number.sub(/\A0+/,'') #replaces leading zeros with spaces, required for all hlsc clients
    clp_elements << eob.claim_status_code
    clp_elements << eob.amount('total_submitted_charge_for_claim')
    clp_elements << eob.amount('total_amount_paid_for_claim')
    clp_elements << (clp_elements[2] == 22 ? "" : eob.patient_responsibility_amount)
    clp_elements << plan_type
    clp_elements << eob.claim_number
    clp_elements << (facility_type_code.blank? ? '13' :  facility_type_code)
    clp_elements << claim_freq_indicator
    clp_elements.join(@element_seperator)
  end

  #supply adjustment reason codes and amounts as needed for an entire claim
  #or for a particular service within the claim being paid
  def claim_adjustment
    unless eob.amount('claim_interest').blank? || eob.amount('claim_interest').to_f.zero?
      claim_adjustment_elements = []
      claim_adjustment_elements << 'CAS'
      claim_adjustment_elements << 'OA'
      claim_adjustment_elements << '85'
      claim_adjustment_elements << eob.claim_interest
      claim_adjustment_elements.join(@element_seperator)
    end
  end
  
  #Supplies the full name of an individual or organizational entity
  def patient_name
    patient_name_elements = []
    patient_name_elements << 'NM1'
    patient_name_elements << 'QC'
    patient_name_elements << '1'
    patient_name_elements << eob.patient_last_name
    patient_name_elements << eob.patient_first_name
    patient_name_elements << eob.patient_middle_initial
    patient_name_elements << ''
    patient_name_elements << eob.patient_suffix
    patient_name_elements << ('HN' if !eob.subscriber_identification_code.blank?)
    patient_name_elements << eob.subscriber_identification_code
    patient_name_elements.join(@element_seperator)
  end

  # Required when the insured or subscriber is different from the patient
  def insured_name
  end

  def other_claim_related_id
  end
  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name
    service_prov_name_elements = []
    service_prov_name_elements << 'NM1'
    service_prov_name_elements << '82'
    service_prov_name_elements << '1'
    service_prov_name_elements << eob.rendering_provider_last_name
    service_prov_name_elements << eob.rendering_provider_first_name
    service_prov_name_elements << eob.rendering_provider_middle_initial
    service_prov_name_elements << ''
    service_prov_name_elements << ''
    service_prov_name_elements << 'PC'
    service_prov_name_elements << "#{eob.check_information.batch.facility.lockbox_number}-#{eob.check_information.check_number}"
    service_prov_name_elements.join(@element_seperator)
  end

  def plan_type
    if eob.claim_information && !eob.claim_information.claim_type.blank?
      eob.claim_information.plan_type
    else
      'MC'
    end
  end
  def claim_freq_indicator
    if eob.claim_information && !eob.claim_information.claim_frequency_type_code.blank?
      eob.claim_information.claim_frequency_type_code
    else
      '1'
    end
  end
  def facility_type_code
    if eob.claim_information
      facility_code = eob.claim_information.facility_type_code
      (facility_code.blank? ? '13' : eob.facility_type_code)
    else
      '13'
    end
  end
end