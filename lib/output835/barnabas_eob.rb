class Output835::BarnabasEob < Output835::Eob

  def claim_payment_information
    drg_code = eob.drg_code unless eob.drg_code.blank?
    drg_weight =   eob.drg_weight unless eob.drg_weight.blank?
    claim_weight = claim_type_weight
    clp_elements = ['CLP', patient_account_number, claim_weight, eob.amount('total_submitted_charge_for_claim'),
         eob.payment_amount_for_output(facility, facility_output_config), (claim_weight == 22 ? "" : eob.patient_responsibility_amount),
         plan_type.to_s, claim_number, facility_type_code, claim_freq_indicator, plan_code , drg_code, drg_weight]
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  def plan_code
    claim = eob.claim_information
    claim.plan_code.to_s[0] if claim
  end
 
end
