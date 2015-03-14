class Output835::QuadaxEob < Output835::Eob
  
  def claim_supplemental_info
    check_amount = eob.check_information.check_amount.to_f
    interest = eob.claim_interest.to_f
    total_balance = eob.total_service_balance.to_f
    unless interest.zero?
      unless (check_amount == interest) # segment is not needed for interest only checks
        elements = []
        elements << "AMT"
        elements << "I"
        elements << eob.amount('claim_interest')
        elements.join(@element_seperator)
      end
    end   
  end
  
  #Supplies the full name of an individual or organizational entity
  def patient_name
    member_id, qualifier = eob.member_id_and_qualifier
    patient_name_elements = []
    patient_name_elements << 'NM1'
    patient_name_elements << 'QC'
    patient_name_elements << '1'
    patient_name_elements << eob.patient_last_name
    patient_name_elements << eob.patient_first_name
    patient_name_elements << eob.patient_middle_initial
    patient_name_elements << ''
    patient_name_elements << eob.patient_suffix
    patient_name_elements << qualifier
    patient_name_elements << member_id
    patient_name_elements = Output835.trim_segment(patient_name_elements)
    patient_name_elements.join(@element_seperator)
  end


  #For Quadax, default the plan type to CI in non MPI EOBs where the claim type is "Secondary".
  def plan_type
    plan_type_config = facility.plan_type.to_s.downcase.gsub(' ', '_')
    if plan_type_config == 'payer_specific_only'
      output_plan_type = payer.plan_type.to_s if payer
      output_plan_type = 'ZZ' if output_plan_type.blank?
    else
      if eob.claim_information && !eob.claim_information.claim_type.blank?
        output_plan_type = eob.claim_information.plan_type
      elsif eob.claim_information.blank? && eob.claim_type == "Secondary"
        output_plan_type = "CI"
      else
        output_plan_type = eob.plan_type
      end
    end
    output_plan_type
  end
  
  # For Quadax if there is Remark code MA07 or MA18 or N89 or N367 available in an EOB,
  #  then we need to set the claim type 19 in the output module only.
  #  (if LQ*HE is cheked with ANSI)    
  def claim_type_weight
    is_industry_code_configured = facility.industry_code_configured?
    remark_codes = []
    rcc = ReasonCodeCrosswalk.new(payer, nil, client, facility)
    if claim_level_eob?
      crosswalked_codes = rcc.get_all_codes_for_entity(eob, true)
      remark_codes << crosswalked_codes[:remark_codes]
    else
      service_lines = eob.service_payment_eobs
      if !service_lines.blank?
        service_lines.each do |svc_line|
          crosswalked_codes = rcc.get_all_codes_for_entity(svc_line, true)
          remark_codes << crosswalked_codes[:remark_codes]
          remark_codes << svc_line.get_remark_codes
        end
      end      
    end
    remark_codes = remark_codes.flatten.compact.uniq
    condition_to_print_claim_type_19 = is_industry_code_configured && !remark_codes.blank? &&
      eob.check_validity_of_ansi_code(remark_codes)
    if condition_to_print_claim_type_19
      Output835.log.info "claim type is 19"
      19
    else
      eob.claim_type_weight
    end
  end

  def claim_from_date
    from_date = eob.claim_from_date
    unless from_date.blank?
      from_date = from_date.strftime("%Y%m%d")
      from_date = '99999999' if (from_date == '20000101' || from_date == '99990909')
      Output835.log.info "Claim From Date:#{from_date}"
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '232'
      claim_date_elements << from_date
      claim_date_elements.join(@element_seperator)
    end
  end

  def claim_to_date
    to_date = eob.claim_to_date
    unless to_date.blank?
      to_date = to_date.strftime("%Y%m%d")
      to_date = '99999999' if (to_date == '20000101' || to_date == '99990909')
      Output835.log.info "Claim To Date:#{to_date}"
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '233'
      claim_date_elements << to_date
      claim_date_elements.join(@element_seperator)
    end
  end

  def claim_payment_information
    claim_weight = claim_type_weight
    clp_elements = ['CLP', patient_account_number, claim_weight, eob.amount('total_submitted_charge_for_claim'),
        eob.payment_amount_for_output(facility, facility_output_config), ( claim_weight== 22 ? "" : eob.patient_responsibility_amount.to_amount),
        plan_type, claim_number, facility_type_code, claim_freq_indicator, nil,
        (eob.drg_code unless eob.drg_code.blank?)]
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
     unless @clp_pr_amount.blank?
        @clp_05_amount += @clp_pr_amount
      end
    clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? @clp_05_amount.to_f.to_amount_for_clp : "")
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end
  
end