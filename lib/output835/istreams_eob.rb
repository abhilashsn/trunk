class Output835::IstreamsEob < Output835::ShepherdEyeSurgicenterEob
  def claim_payment_information
    clp_elements = []
    clp_elements << 'CLP'
    clp_elements << patient_account_number
    clp_elements << claim_type_weight
    clp_elements << eob.amount('total_submitted_charge_for_claim')
    clp_elements << eob.amount('total_amount_paid_for_claim')
    clp_elements << (clp_elements[2] == 22 ? "" : eob.patient_responsibility_amount)
    clp_elements << plan_type
    clp_elements << claim_number
    clp_elements << facility_type_code
    clp_elements << claim_freq_indicator
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name
    Output835.log.info "Printing NM1*82 for Patient Acc Num : #{eob.patient_account_number}"
    prov_id, qualifier = service_prov_identification
    service_prov_name_elements = []
    service_prov_name_elements << 'NM1'
    service_prov_name_elements << '82'
    service_prov_name_elements << (eob.rendering_provider_last_name.strip.blank? ? '2': '1')
    service_prov_name_elements << prov_last_name_or_org
    service_prov_name_elements << eob.rendering_provider_first_name
    service_prov_name_elements << eob.rendering_provider_middle_initial
    service_prov_name_elements << ''
    service_prov_name_elements << ''
    service_prov_name_elements << qualifier
    service_prov_name_elements << prov_id
    service_prov_name_elements = Output835.trim_segment(service_prov_name_elements)
    service_prov_name_elements.join(@element_seperator)
  end

  #Specifies pertinent From date of the claim
  def claim_from_date
    unless eob.claim_from_date.blank?
      if eob.claim_from_date.strftime("%Y%m%d") == "20000101"
        claim_from_date = "00000000"
      else
        claim_from_date = eob.claim_from_date.strftime("%Y%m%d")
      end
      Output835.log.info "Claim From Date:#{claim_from_date}"
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '232'
      claim_date_elements << claim_from_date
      claim_date_elements.join(@element_seperator)
    end
  end

  #Specifies pertinent To dates of the claim
  def claim_to_date
    unless eob.claim_to_date.blank?
      if eob.claim_from_date.strftime("%Y%m%d") == "20000101"
        claim_to_date = "00000000"
      else
        claim_to_date = eob.claim_to_date.strftime("%Y%m%d")
      end
      Output835.log.info "Claim To Date:#{eob.claim_to_date}"
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '233'
      claim_date_elements << claim_to_date
      claim_date_elements.join(@element_seperator)
    end
  end



end