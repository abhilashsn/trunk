class Output835::Eob

  attr_reader :eob, :index, :facility, :payer, :service_eobs, :client, :facility_output_config, :check

  def initialize(eob, facility, payer, index, element_seperator)
    @eob = eob
    @index = index
    @element_seperator = element_seperator
    @check = eob.check_information
    @job = @check.job
    @claim = eob.claim_information
    @facility = facility
    @client = facility.client
    @payer = payer
    @facility_config = facility.facility_output_configs.first
    @facility_output_config = facility.output_config(@job.payer_group)
    @service_eobs = eob.service_payment_eobs
    @reason_codes = nil    #this variable is used in  child class for configurable section
  end

  def generate
    Output835.log.info "\n\nPatient account number : #{eob.patient_account_number}"
    Output835.log.info "This EOB has #{eob.service_payment_eobs.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if claim_level_eob?
    claim_segments = []
    claim_segments << claim_payment_loop
    claim_segments << (claim_level_eob? ? claim_from_date : statement_from_date)
    claim_segments << (claim_level_eob? ? claim_to_date : statement_to_date)
    if facility.details[:interest_in_service_line] == false
      claim_segments << claim_supplemental_info
    end
    claim_segments << claim_level_allowed_amount_bac
    claim_segments << (claim_level_eob? ? nil : service_payment_info_loop)
    update_clp! claim_segments 
    claim_segments = claim_segments.flatten.compact
    claim_segments unless claim_segments.empty?
  end

  #This predicate method returns true if the eob type is claim level.
  #Otherwise(Service level) returns false.
  def claim_level_eob?
    eob.category.upcase == "CLAIM"
  end
  
  #Loop 2100 : Supplies information common to all services of a claim
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
    claim_payment_segments << reference_identification_qualifier_bac
    claim_payment_segments << reference_identification_bac if !@reason_codes.blank?
    unless eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    claim_payment_segments << service_prov_name
    claim_payment_segments << service_prov_identifier_bac
    claim_payment_segments << reference_id_bac
    claim_payment_segments << image_page_name_bac
    claim_payment_segments << other_claim_related_id
    claim_payment_segments = claim_payment_segments.compact
    claim_payment_segments unless claim_payment_segments.blank?
  end
  
  #Supplies information common to all services of a claim
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
    clp_elements << nil
    clp_elements << eob.drg_code unless eob.drg_code.blank?
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end
  
  def claim_supplemental_info
    unless eob.claim_interest.blank? || eob.claim_interest.to_f.zero?
      elements = []
      elements << "AMT"
      elements << "I"
      elements << eob.amount('claim_interest')
      elements.join(@element_seperator)
    end
  end

  def claim_level_allowed_amount_bac
    if !@facility_output_config.details.blank? and
        @facility_output_config.details[:claim_level_allowed_amt] == true
      claim_payment_amt = eob.payment_amount_for_output(facility, facility_output_config)
      unless claim_payment_amt.to_f.zero?
        claim_level_supplemental_amount = eob.claim_level_supplemental_amount
        unless claim_level_supplemental_amount.blank?
          elements = []
          elements << "AMT"
          elements << "AU"
          elements << claim_level_supplemental_amount
          elements.join(@element_seperator)
        end
      end
    end
  end

   
  #Supplies the full name of an individual or organizational entity
  def patient_name
    patient_id, qualifier = eob.patient_id_and_qualifier
    patient_name_elements = []
    patient_name_elements << 'NM1'
    patient_name_elements << 'QC'
    patient_name_elements << '1'
    patient_name_elements << eob.patient_last_name.to_s.strip
    patient_name_elements << eob.patient_first_name.to_s.strip
    patient_name_elements << eob.patient_middle_initial.to_s.strip
    patient_name_elements << ''
    patient_name_elements << eob.patient_suffix
    patient_name_elements << qualifier
    patient_name_elements << patient_id
    patient_name_elements = Output835.trim_segment(patient_name_elements)
    patient_name_elements.join(@element_seperator)
  end

  # Required when the insured or subscriber is different from the patient
  def insured_name
    id, qual = eob.member_id_and_qualifier
    sub_name_ele = []
    sub_name_ele << 'NM1'
    sub_name_ele << 'IL'
    sub_name_ele << '1'
    sub_name_ele << eob.subscriber_last_name
    sub_name_ele << eob.subscriber_first_name
    sub_name_ele << eob.subscriber_middle_initial
    sub_name_ele << ''
    sub_name_ele << eob.subscriber_suffix
    sub_name_ele << qual
    sub_name_ele << id
    sub_name_ele = Output835.trim_segment(sub_name_ele)
    sub_name_ele.join(@element_seperator)
  end

  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name
    Output835.log.info "Printing NM1*82 for Patient Acc Num : #{eob.patient_account_number}"
    prov_id, qualifier = service_prov_identification
    service_prov_name_elements = []
    service_prov_name_elements << 'NM1'
    service_prov_name_elements << '82'
    service_prov_name_elements << (eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1')
    service_prov_name_elements << prov_last_name_or_org
    service_prov_name_elements << eob.rendering_provider_first_name
    service_prov_name_elements << eob.rendering_provider_middle_initial
    service_prov_name_elements << ''
    service_prov_name_elements << eob.rendering_provider_suffix
    service_prov_name_elements << qualifier
    service_prov_name_elements << prov_id
    service_prov_name_elements = Output835.trim_segment(service_prov_name_elements)
    service_prov_name_elements.join(@element_seperator)
  end

  # Used when additional reference numbers specific to the claim in the
  # CLP segment are provided to identify information used in the process of
  # adjudicating this claim
  def other_claim_related_id
    elem = []
    if !eob.insurance_policy_number.blank?
      elem << 'REF'
      elem << 'IG'
      elem << eob.insurance_policy_number
      elem = Output835.trim_segment(elem)
      elem.join(@element_seperator)
    end
  end

  #Specifies pertinent dates and times of the claim
  def statement_from_date
    unless claim_start_date.blank?
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '232'
      claim_date_elements << claim_start_date.strftime("%Y%m%d")
      claim_date_elements.join(@element_seperator)
    end
  end

  #Specifies pertinent dates and times of the claim
  def statement_to_date
  end

  #Specifies pertinent From date of the claim
  def claim_from_date
    unless eob.claim_from_date.blank?
      Output835.log.info "Claim From Date:#{eob.claim_from_date}"
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '232'
      claim_date_elements << eob.claim_from_date.strftime("%Y%m%d")
      claim_date_elements.join(@element_seperator)
    end
  end
  
  #Specifies pertinent To dates of the claim
  def claim_to_date
    unless eob.claim_to_date.blank?
      Output835.log.info "Claim To Date:#{eob.claim_to_date}"
      claim_date_elements = []
      claim_date_elements << 'DTM'
      claim_date_elements << '233'
      claim_date_elements << eob.claim_to_date.strftime("%Y%m%d")
      claim_date_elements.join(@element_seperator)
    end
  end
  
  #Supplies payment and control information to a provider for a particular service
  def service_payment_info_loop
    segments = []
    @clp_05_amount = 0
    eob.service_payment_eobs.each_with_index do |service, index|
      service_klass = Output835.class_for("Service", facility)
      Output835.log.info "Applying class #{service_klass}" if index == 0
      service_obj = service_klass.new(service, facility, payer, index, @element_seperator) if service
      service_segments = service_obj.generate
      segments += service_segments[0]
      @clp_05_amount += service_segments[1]
    end
    segments
  end

  # Returns the following in that precedence.
  # i. Provider NPI from 837   ii. If not, Provider TIN from 837   iii. If not NPI from FC UI   iv. If not TIN from FC UI
  # Returns qualifier 'XX' for NPI and 'FI' for TIN
  def service_prov_identification
    code, qual = nil, nil
    claim = eob.claim_information

    if (claim && !claim.provider_npi.blank?)
      code = claim.provider_npi
      qual = 'XX'
      Output835.log.info "Provider NPI from the 837 is chosen"
    elsif (claim && !claim.provider_ein.blank?)
      code = claim.provider_ein
      qual = 'FI'
      Output835.log.info "Provider TIN from 837 is chosen"
    elsif !facility.facility_npi.blank?
      code = facility.facility_npi
      qual = 'XX'
      Output835.log.info "facility NPI from FC is chosen"
    elsif !facility.facility_tin.blank?
      code = facility.facility_tin
      qual = 'FI'
      Output835.log.info "facility TIN from FC is chosen"
    end

    return code, qual
  end

  # Returns the following in that precedence.
  # i. Payee NPI from 837   ii. If not, Payee TIN from 837   iii. If not NPI from FC UI   iv. If not TIN from FC UI
  # Returns qualifier 'XX' for NPI and 'FI' for TIN
  def service_payee_identification
    code, qual = nil, nil
    claim = eob.claim_information
    fac = facility

    if (claim && !claim.payee_npi.blank?)
      code = claim.payee_npi
      qual = 'XX'
      Output835.log.info "Payee NPI from the 837 is chosen"
    elsif (claim && !claim.payee_tin.blank?)
      code = claim.payee_tin
      qual = 'FI'
      Output835.log.info "Payee TIN from 837 is chosen"
    elsif !fac.facility_npi.blank?
      code = fac.facility_npi
      qual = 'XX'
      Output835.log.info "facility NPI from FC is chosen"
    elsif !fac.facility_tin.blank?
      code = fac.facility_tin
      qual = 'FI'
      Output835.log.info "facility TIN from FC is chosen"
    end

    return code, qual
  end

  def plan_type
    plan_type_config = facility.plan_type.to_s.downcase.gsub(' ', '_')
    if plan_type_config == 'payer_specific_only'
      output_plan_type = payer.plan_type.to_s if payer
      output_plan_type = 'ZZ' if output_plan_type.blank?
    else
      if eob.claim_information && !eob.claim_information.plan_type.blank?
        output_plan_type = eob.claim_information.plan_type
      else
        output_plan_type = eob.plan_type
      end
    end
    output_plan_type
  end

  def claim_freq_indicator
    if eob.claim_information && !eob.claim_information.claim_frequency_type_code.blank?
      eob.claim_information.claim_frequency_type_code
    end
  end

  def facility_type_code
    if eob.claim_information && !eob.claim_information.facility_type_code.blank?
      eob.claim_information.facility_type_code
    end
  end

  def claim_type_weight
    eob.claim_type_weight
  end
  
  def claim_start_date
    claim = eob.claim_information
    if claim && claim.claim_statement_period_start_date
      eob.claim_information.claim_statement_period_start_date
    end
  end
 
  def prov_last_name_or_org
    if not eob.rendering_provider_last_name.to_s.strip.blank?
      eob.rendering_provider_last_name.upcase
    elsif not eob.provider_organisation.blank?
      eob.provider_organisation.to_s.upcase
    else
      facility.name.upcase
    end
  end
  
  def patient_account_number
    eob.patient_account_number
  end
  
  def claim_number
    eob.claim_number.to_s
  end

  #This method is to bypass bac specific methods which is suffixed with 'bac'
  def method_missing m, *args
    unless m.to_s[-3..-1] == 'bac'
      super
    else
      nil
    end
  end

  def standard_industry_code_segments
    Output835.standard_industry_code_segments(eob, client, facility, payer, @element_seperator)
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
    if $IS_PARTNER_BAC
      clp[5] = @clp_05_amount.to_s.to_dollar.to_blank
    else
      unless @clp_pr_amount.blank?
        @clp_05_amount += @clp_pr_amount
      end
      clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? "%.2f" %@clp_05_amount : "")
    end
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end

  def service_prov_identifier_bac
    if facility.details['re_pricer_info']
      unless check.alternate_payer_name.blank?
        ['NM1', 'PR','2', check.alternate_payer_name.to_s.strip].join(@element_seperator)
      end
    end
  end
  
end
