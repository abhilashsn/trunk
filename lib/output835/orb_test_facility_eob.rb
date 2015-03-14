# To change this template, choose Tools | Templates
# and open the template in the editor.

class Output835::OrbTestFacilityEob< Output835::Eob

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
    claim_payment_segments << claim_interest_information_bac  # _bac methods are used for dynamic output section it will be bypassed for non_banks
    if claim_level_eob?
      cas_segments, @clp_05_amount = Output835.cas_adjustment_segments(eob,
        client, facility, payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << patient_name
    unless eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    
    claim_payment_segments = claim_payment_segments.compact
    claim_payment_segments unless claim_payment_segments.blank?
  end


  def claim_payment_information
    facility_code = nil
    claim_indicator_code = nil
    patient_acc_number = nil
    clp_elements = []
    clp_elements << 'CLP'
    patient_acc_number = patient_account_number
    clp_elements << ((patient_acc_number)?patient_acc_number : '000000000')
    clp_elements << claim_type_weight
    clp_elements << eob.amount('total_submitted_charge_for_claim')
    clp_elements << eob.payment_amount_for_output(facility, facility_output_config)
    clp_elements << (clp_elements[2] == 22 ? "" : eob.patient_responsibility_amount)
    clp_plan_type = plan_type
    clp_elements << ((clp_plan_type)? clp_plan_type :'MC')             #plan_type
    clp_elements << claim_number
    facility_code = facility_type_code
    clp_elements << ((facility_code)? facility_code :'11')
    claim_indicator_code = claim_freq_indicator
    clp_elements << ((claim_indicator_code)? claim_indicator_code : '1')
    clp_elements << nil
    clp_elements << eob.drg_code unless eob.drg_code.blank?
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  def patient_name
    patient_id, qualifier = eob.patient_id_and_qualifier
    patient_name_elements = []
    patient_name_elements << 'NM1'
    patient_name_elements << 'QC'
    patient_name_elements << '1'
    last_name = eob.patient_last_name.to_s.strip
    patient_name_elements << ((last_name)? last_name :'NONE')
    first_name = eob.patient_first_name.to_s.strip
    patient_name_elements << ((first_name)? first_name :'NONE')
    middle_initial = eob.patient_middle_initial.to_s.strip
    patient_name_elements << ((middle_initial)? middle_initial : '')
    patient_name_elements << ''
    patient_name_elements << eob.patient_suffix
    patient_name_elements << qualifier
    patient_name_elements << patient_id
    patient_name_elements = Output835.trim_segment(patient_name_elements)
    patient_name_elements.join(@element_seperator)
  end

  def insured_name
    id, qual = eob.member_id_and_qualifier
    sub_name_ele = []
    sub_name_ele << 'NM1'
    sub_name_ele << 'IL'
    sub_name_ele << '1'
    subscriber_last_name = eob.subscriber_last_name
    sub_name_ele << ((subscriber_last_name)? subscriber_last_name : 'NONE')
    subscriber_first_name = eob.subscriber_first_name
    sub_name_ele << ((subscriber_first_name)? subscriber_first_name : 'NONE')
    subscriber_middle_initial = eob.subscriber_middle_initial
    sub_name_ele << ((subscriber_middle_initial)? subscriber_middle_initial : '')
    sub_name_ele << ''
    sub_name_ele << eob.subscriber_suffix
    sub_name_ele << qual
    sub_name_ele << id
    sub_name_ele = Output835.trim_segment(sub_name_ele)
    sub_name_ele.join(@element_seperator)
  end

  def plan_type
    plan_type_config = facility.plan_type.to_s.downcase.gsub(' ', '_')
    if plan_type_config == 'payer_specific_only'
      output_plan_type = payer.plan_type.to_s if payer
      output_plan_type = 'MC' if output_plan_type.blank?
     else
      if eob.claim_information && !eob.claim_information.plan_type.blank?
        output_plan_type = eob.claim_information.plan_type
     else
        output_plan_type = eob.plan_type
      end
    end
    output_plan_type
  end

end
