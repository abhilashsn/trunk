class Output835::AscendClinicalLlcEob < Output835::Eob

  def generate
    Output835.log.info "\n\nPatient account number : #{eob.patient_account_number}"
    Output835.log.info "This EOB has #{eob.service_payment_eobs.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if claim_level_eob?
    claim_segments = []
    claim_segments << claim_payment_loop
    claim_segments << claim_received_date if claim_level_eob?
    if facility.details[:interest_in_service_line] == false
      claim_segments << claim_supplemental_info
    end
    claim_segments << (claim_level_eob? ? nil : service_payment_info_loop)
    update_clp! claim_segments
    claim_segments = claim_segments.flatten.compact
    claim_segments unless claim_segments.empty?
  end

  def claim_payment_loop
    claim_payment_segments = []
    service_eob = nil
    @clp_pr_amount = nil
    claim_payment_segments << claim_payment_information
    eob.service_payment_eobs.collect{|service| service_eob=service if service.adjustment_line_is?}
    if !service_eob.blank?
      cas_segments, @clp_pr_amount = Output835.cas_adjustment_segments(service_eob,
        client, facility, payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    if claim_level_eob?
      cas_segments, @clp_05_amount = Output835.cas_adjustment_segments(eob,
        client, facility, payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << patient_name
    unless eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    claim_payment_segments << service_prov_name
    claim_payment_segments << reference_identification_qualifier
    claim_payment_segments = claim_payment_segments.compact
    claim_payment_segments unless claim_payment_segments.blank?
  end


  def claim_payment_information
    clp_elements = []
    clp_elements << 'CLP'
    clp_elements << patient_account_number
    clp_elements << claim_type_weight
    clp_elements << eob.amount('total_submitted_charge_for_claim')
    clp_elements << eob.payment_amount_for_output(facility, facility_output_config)
    clp_elements << (clp_elements[2] == 22 ? "" : eob.patient_responsibility_amount)
    clp_elements << plan_type
    clp_elements << claim_number
    clp_elements << facility_type_code
    clp_elements << claim_freq_indicator
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  def service_prov_name
    prov_id, qualifier = service_prov_identification
    service_prov_name_elements = ['NM1', '82', (eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
      prov_last_name_or_org, eob.rendering_provider_first_name, eob.rendering_provider_middle_initial,
      '', '', qualifier, prov_id]
    service_prov_name_elements = Output835.trim_segment(service_prov_name_elements)
    service_prov_name_elements.join(@element_seperator)
  end

  def reference_identification_qualifier
    insurance_policy_number = eob.insurance_policy_number.to_s
    ['REF', '1L', insurance_policy_number].join(@element_seperator) unless insurance_policy_number.blank?
  end

  def claim_received_date
    ['DTM', '050', eob.claim_from_date.strftime("%Y%m%d")].join(@element_seperator)
  end
  
end
