class Output835::ClientEEob < Output835::HlscEob
  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name
    service_prov_name_elements = []
    service_prov_name_elements << 'NM1'
    service_prov_name_elements << '82'
    service_prov_name_elements << '1'
    service_prov_name_elements << eob.patient_last_name
    service_prov_name_elements << eob.patient_first_name
    service_prov_name_elements << eob.patient_middle_initial
    service_prov_name_elements << ''
    service_prov_name_elements << ''
    service_prov_name_elements << 'PC'
    service_prov_name_elements << "#{eob.check_information.batch.facility.lockbox_number}-#{eob.check_information.check_number}"
    service_prov_name_elements.join(@element_seperator)
  end
  #Specifies pertinent dates and times of the claim
  def statement_to_date
    unless claim_end_date.blank?
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '233'
      claim_date_elements << claim_end_date.to_s.split('-').join
      claim_date_elements.join(@element_seperator)
    end
  end
  def claim_supplemental_info
  end
  def claim_end_date
    claim = eob.claim_information
    if claim && claim.claim_statement_period_start_date
      eob.claim_information.claim_statement_period_start_date
    elsif eob.service_payment_eobs
      #choose the least 'from date' among the service lines for this EOB
      eob.service_payment_eobs.collect{|spe| spe.date_of_service_to}.compact.sort.last
    end
  rescue
    nil
  end
end
