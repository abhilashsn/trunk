
class Output835::OrbTestFacilityTemplate< Output835::Template

  def interchange_control_header
    ['ISA', '00', (' ' * 10), '00', (' ' * 10), 'ZZ', trim('ORBOMED',15), 'ZZ', trim(transaction_payer_id, 15),
      Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
      ((!@output_version || @output_version == '4010') ? 'U' : '^'),
      ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
      '134061042', '0', 'P', ':'].join(@element_seperator)
  end

  def transaction_payer_id
    payer_name = @first_check.payer.payer.upcase
    if payer_name == 'EMPIRE BLUECROSS BLUESHIELD'
      payid ='00303'
    elsif ['OXFORD', 'UNITED HEALTHCARE'].include?(payer_name)
      payid ='87726'
    elsif @first_check.eob_type == 'Patient'
      payid ='P9998'
    else
      payid = @first_check.client_specific_payer_id(@facility)
      if payid.blank?
      payid = payer_id.to_s
      end
    end
    return payid.to_s
  end
  
  def functional_group_header
    [ 'GS', 'HP', 'ORBOMED', strip_string(trim(transaction_payer_id, 5)), Time.now().strftime("%Y%m%d"), Time.now().strftime("%H%M"),
      '134061042', 'X', ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1') ].join(@element_seperator)
  end

  def functional_group_trailer(batch_id=nil)
    ['GE',checks_in_functional_group(batch_id),'134061042'].join(@element_seperator)
  end

  def interchange_control_trailer
    ['IEA','1','134061042'].join(@element_seperator)
  end


  def generate_check
    Output835.log.info "\n\nCheck number : #{@check.check_number} undergoing processing"
    Output835.log.info "Payer : #{@check.payer.payer}, Check ID: #{@check.id}"
    transaction_segments =[transaction_set_header,financial_info,reassociation_trace,
      payer_identification_loop,payee_identification_loop,claim_loop,provider_adjustment]
    transaction_segments = transaction_segments.flatten.compact
    @se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments unless transaction_segments.blank?
  end

  def claim_loop
    segments = []
    @eobs.each_with_index do |eob, index|
      @check_grouper.last_eob = eob
      @eob = eob
      @claim = eob.claim_information
      @eob_index = index
      @services = eob.service_payment_eobs
      @is_claim_eob = (eob.category.upcase == "CLAIM")
      segments << transaction_set_line_number(index + 1) if index == 0
      segments << provider_summary_info if index == 0
      segments << transaction_statistics([eob])
      segments += generate_eobs
    end
    segments.flatten.compact
  end

  def transaction_set_line_number(index)
    ['LX', index.to_s].join(@element_seperator)
  end

  def payer_identification_loop(repeat = 1)
    payer = get_payer
    Output835.log.info "\n payer is #{payer.name}"
    if payer
      payer_segments = []
      repeat.times do
        payer_segments << payer_identification(payer)
        payer_segments << address(payer)
        payer_segments << geographic_location(payer)
      end
      payer_segments = payer_segments.compact
      payer_segments unless payer_segments.blank?
    end
  rescue NoMethodError
    raise "Payer is missing for check : #{@check.check_number} id : #{@check.id}"
  end


  def financial_info(facility = nil,check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
    @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
    @micr = @micr.nil?? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil?? correspondence_check : @is_correspndence_check
    @check_amount = @check_amount.nil?? check_amount : @check_amount
    @facility_output_config = @facility_output_config.nil?? facility_config : @facility_output_config
    bpr_elements = ['BPR', bpr_01, @check_amount.to_s, 'C', payment_indicator, '']
    if @facility.details[:micr_line_info]
      routing_number_to_print = routing_number
      id_qualifier =  routing_number_to_print.to_s.blank?? '' : id_number_qualifier
      account_number_value = account_number
      account_indicator = account_number_value.to_s.blank?? '' : account_num_indicator
      bpr_elements += [id_qualifier, routing_number_to_print, account_indicator, account_number_value ]
    else
      bpr_elements += ['', '', '', '']
    end
    payid = @check.client_specific_payer_id(@facility)
      if payid.blank?
      payid = @payer.payid
      end
    bpr_elements <<  payid.to_s.rjust(10, '0') if @payer
    bpr_elements << '999999999'
    aba_dda_lookup = @facility.aba_dda_lookups.first
    if aba_dda_lookup
      aba_number = aba_dda_lookup.aba_number
      dda_number = aba_dda_lookup.dda_number
    end
    if @check_amount.to_f > 0 && @check.payment_method != "EFT"
      aba_number = aba_number.blank? ? '' : aba_number
      aba_num_qualifier = aba_number.blank?? '':'01'
      bpr_elements << aba_num_qualifier
      bpr_elements << aba_number
      dda_number = dda_number.blank? ? '' : dda_number 
      dda_num_qualifier = dda_number.blank?? '' : 'DA'
      bpr_elements << dda_num_qualifier
      bpr_elements << dda_number 
    else
      bpr_elements << ['', '', '', '']
    end
    bpr_elements << effective_payment_date
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

  def bpr_01
    if (@check_amount.to_f > 0 && @check.payment_method == "CHK")
      "C"
    elsif @check.payment_method == 'ACH'
      @check.mismatch_transaction ? 'H' : 'C'
    elsif (@check_amount.to_f.zero?)
      "H"
    elsif (@check.payment_method == "OTH")
      "D"
    end
  end

  def payment_indicator
    payment_method = @check.payment_method
    if payment_method == "CHK" || payment_method == "OTH"
      "CHK"
    elsif payment_method == "ACH"
      @check.mismatch_transaction ? 'NON' : 'ACH'
    elsif @check_amount.to_f.zero?
      "NON"
    end
  end

  def reassociation_trace
     payid = @check.client_specific_payer_id(@facility)
      if payid.blank?
    payid = get_orbo_payer_id(@check)
      end
    ['TRN', '1', output_check_number, payid.to_s.rjust(10, '0'),"999999999"].trim_segment.join(@element_seperator)
  end

  def output_check_number
    check_num = @check.check_number
    if (@check.payment_method == 'ACH' and @check.mismatch_transaction) || !check_num
      '0'
    else
      check_num.to_s
    end
  end

  def payer_identification(payer)
    payid = nil
     payid = @check.client_specific_payer_id(@facility)
      if payid.blank?
    payid = get_orbo_payer_id(@check)
      end
    payer_name = @check.client_specific_payer_name(@facility)
    if  payer_name.blank?
      payer_name = payer.name
    end
    
    [ 'N1', 'PR', payer_name.to_s.strip.upcase[0...60].strip, 'XV', payid].compact.join(@element_seperator)
  end


  def payee_identification(payee,check = nil,claim = nil,eobs=nil)
    @check =  @check.nil?? check : @check
    @claim = @claim.nil?? claim : @claim
    elements = ['N1', 'PE']
    elements << payee_name(payee)
     if @check.payee_npi.present?
      elements << 'XX'
      elements << @check.payee_npi.strip.upcase
    elsif @check.payee_tin.present?
      elements << 'FI'
      elements << @check.payee_tin.strip.upcase
    end
    elements.join(@element_seperator)
    #['N1', 'PE', payee_name(payee), 'XX', payee_npi(payee)].compact.join(@element_seperator)
  end

  def payee_name(payee,eobs=nil)
    claim = @eobs.map(&:claim_information).flatten.compact.first
    if @check.payee_name?
      @check.payee_name.strip.upcase
    elsif claim and claim.name?
      claim.name.strip.upcase
    elsif @config_835[:payee_name].present?
      @config_835[:payee_name].strip.upcase
    else
      @facility.name.strip.upcase
    end
  end

  def payee_npi(payee)
    if @check.payee_npi?
      @check.payee_npi.strip.upcase
#    elsif payee.npi?
#      payee.npi.strip.upcase
    end
  end

  def address(party)
    ['N3',(party.address_one)? party.address_one.strip.upcase : 'PO BOX 9999'].trim_segment.join(@element_seperator)
  end

  def geographic_location(party)
    [ 'N4', ((party.city)? party.city.strip.upcase : 'UNKNOWN'),
      ((party.state)? party.state.strip.upcase : 'GA'),
      ((party.zip_code)? party.zip_code.strip : '12345') ].trim_segment.join(@element_seperator)
  end

  def payee_identification_loop(repeat = 1)
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? || payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility #if any of the billing provider address details is missing get facility address
      end
      payee_segments = []
      address_payee = @facility.details[:default_payee_details] ? @facility : payee
      repeat.times do
        payee_segments << payee_identification(payee)
        payee_segments << address(address_payee)
        payee_segments << geographic_location(address_payee)
      end
      payee_segments = payee_segments.compact
      payee_segments unless payee_segments.blank?
    end
  end

  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
    claim_segments = [claim_payment_loop, repricer_info, include_claim_dates]
    claim_segments << claim_tooth_number_info if @is_claim_eob && @eob.claim_tooth_number
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
    claim_segments << claim_level_allowed_amount
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments << service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

  def repricer_info
    ['REF', 'CE', @eob.alternate_payer_name.strip.upcase].join(@element_seperator) if @eob.alternate_payer_name.present?
  end

  #from claim_payment_information (orb_test_facility_eob.rb) to do
  def claim_payment_loop
    claim_payment_segments = []
    service_eob = nil
    @clp_pr_amount = nil
    claim_payment_segments << claim_payment_information
    @eob.service_payment_eobs.collect{|service| service_eob=service if service.adjustment_line_is?}
    if !service_eob.blank?
      cas_segments, @clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(service_eob,
        @client, @facility, @payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    if @is_claim_eob
      cas_segments, @clp_05_amount, crosswalked_codes = Output835.cas_adjustment_segments(@eob,
        @client, @facility, @payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << patient_name
    unless @eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    claim_payment_segments << service_prov_name
    claim_payment_segments << other_claim_related_id
    if @is_claim_eob
      claim_payment_segments << Output835.claim_level_remark_code_segments(@eob, @element_seperator, crosswalked_codes)
    end
    claim_payment_segments = claim_payment_segments.compact
    claim_payment_segments unless claim_payment_segments.blank?
  end

  def include_claim_dates
    from_date = @eob.claim_from_date.strftime("%Y%m%d") if @eob.claim_from_date.present?
    to_date = @eob.claim_to_date.strftime("%Y%m%d") if @eob.claim_to_date.present?
    @is_claim_eob ? ( from_date == to_date ? [claim_from_date] : [claim_from_date, claim_to_date]) : [statement_from_date, statement_to_date]
  end

  def claim_payment_information
    claim_weight = claim_type_weight
    facility_code = eob_facility_type_code
    claim_indicator_code = claim_freq_indicator
    claim_plan_type = @facility.name.strip.upcase == "GULF IMAGING ASSOCIATES" ? 'CI' : plan_type
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, @eob.amount('total_submitted_charge_for_claim'),
      @eob.payment_amount_for_output(@facility, @facility_output_config),
      ( claim_weight == 22 ? "" : @eob.patient_responsibility_amount),
      claim_plan_type, @eob.claim_number, (facility_code.blank? ? '11' : facility_code),
      (claim_indicator_code.blank? ? '1' : claim_indicator_code), nil,
      @eob.drg_code ].trim_segment.join(@element_seperator)
  end




  def patient_name
    patient_id, qualifier = @eob.patient_id_and_qualifier
    last_name = captured_or_blank_patient_last_name(@eob.patient_last_name)
    first_name = captured_or_blank_patient_first_name(@eob.patient_first_name)
    middle_initial = @eob.patient_middle_initial.to_s.strip
    ['NM1','QC','1',(last_name)? last_name :'NONE',(first_name)? first_name :'NONE',
      (middle_initial)? middle_initial : '', '', @eob.patient_suffix,qualifier,
      patient_id].trim_segment.join(@element_seperator)
  end

  def insured_name
    subscriber_last_name = @eob.subscriber_last_name
    subscriber_first_name = @eob.subscriber_first_name
    subscriber_middle_initial = @eob.subscriber_middle_initial
    if @eob_type != 'Patient'
      id, qual = @eob.member_id_and_qualifier
      ['NM1','IL','1',(subscriber_last_name)? subscriber_last_name : 'NONE',
        (subscriber_first_name)? subscriber_first_name : 'NONE',
        (subscriber_middle_initial)? subscriber_middle_initial : '','',
        @eob.subscriber_suffix,qual, id].trim_segment.join(@element_seperator)
    end
  end


  def generate_services
    is_adjustment_line = @service.adjustment_line_is?
    service_segments = []
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference
    unless is_adjustment_line
      cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, @element_seperator)
      service_segments << cas_segments
    else
      pr_amount = 0.0
    end
    service_segments << service_tooth_number_info if @service.tooth_number   
    service_segments << provider_control_number unless is_adjustment_line
    supp_amount = supplemental_amount
    service_segments << service_supplemental_amount(supp_amount)  unless supp_amount.blank? || @service.amount('service_paid_amount').blank?
    service_segments << standard_industry_code_segments(@service)
    [service_segments.compact.flatten, pr_amount]
  end

  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    service_from_date = @service.date_of_service_from
    service_to_date = @service.date_of_service_to
    from_date = service_from_date.strftime("%Y%m%d") unless service_from_date.blank?
    to_date =  service_to_date.strftime("%Y%m%d") unless service_to_date.blank?
    from_eqls_to_date = (from_date == to_date)

    if !from_date.nil? && (to_date.nil? || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      if from_date == '20000101'
        from_date = '19990101'
      end
      can_print_date = (from_date == '19990101') ? true : can_print_service_date(from_date)
      service_date_elements = dtm_472(from_date) if can_print_date
      service_date_elements unless service_date_elements.blank?
    else
      if can_print_service_date(from_date)
        svc_date_segments << dtm_150(from_date)
      end
      if can_print_service_date(to_date)
        svc_date_segments << dtm_151(to_date)
      end
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end

  def service_payment_information(eob = nil,service = nil,check = nil,is_claim_eob = nil,payer = nil)
    @service =  @service.nil?? service : @service
    quantity = @service.service_quantity.to_f.to_amount
    ['SVC', composite_med_proc_id, @service.amount('service_procedure_charge_amount'),
      @service.amount('service_paid_amount'), svc_revenue_code,
      ( (quantity > 0) ? quantity : '1'), svc_procedure_cpt_code ].trim_segment.join(@element_seperator )
  end

  def service_supplemental_amount supplemental_amount
    ["AMT","B6",supplemental_amount].trim_segment.join(@element_seperator) unless @service.insurance_payment_eob.claim_type_weight.to_s == "4"
  end

  def dtm_472(date)
    ['DTM', '472', date].join(@element_seperator)
  end

  def trim(string, size)
    string.strip.ljust(size).slice(0, size)
  end
  
  def service_prov_name(eob=nil,claim=nil)
    @eob =  @eob.nil?? eob : @eob
    @claim =  @claim.nil?? claim : @claim

    if @facility.name.to_s.strip.upcase == "SOUTH NASSAU COMMUNITY HOSPITAL"
      last_name = "SOUTH NASSAU COMMUNITY HOSPITAL"
      first_name, middle_initial, suffix = nil,nil,nil
      no_last_name, qualifier = true, 'XX'
      prov_id = @eob.provider_npi.present? ? @eob.provider_npi : '1922079094'
    elsif @eob && (@eob.provider_npi.present? || @eob.provider_tin.present?) && (@eob.rendering_provider_last_name.present? || @eob.rendering_provider_first_name.present?)
      prov_id = @eob.provider_npi.present? ? @eob.provider_npi : @eob.provider_tin
      qualifier = @eob.provider_npi.present? ? 'XX' : 'FI'
      no_last_name = @eob.rendering_provider_last_name.to_s.strip.blank?
      last_name = @eob.rendering_provider_last_name.upcase unless no_last_name
      first_name = @eob.rendering_provider_first_name
      middle_initial = @eob.rendering_provider_middle_initial
      suffix = @eob.rendering_provider_suffix
    elsif @eob.provider_organisation.present? 
      last_name = @eob.provider_organisation.to_s.upcase
      prov_id = @eob.provider_npi.present? ? @eob.provider_npi : @eob.provider_tin
      qualifier = @eob.provider_npi.present? ? 'XX' : 'FI'
      unless prov_id.present?
        payee = get_facility
        prov_id = payee_npi(payee)
        qualifier = (prov_id.present?)? 'XX' : nil
      end
      first_name = nil
      middle_initial = nil
      suffix = nil
      no_last_name = true
    else
      payee = get_facility
      if payee
        if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? || payee.state.blank? || payee.zip_code.blank?)
          @claim = payee.clone
          payee = @facility #if any of the billing provider address details is missing get facility address
        end
        prov_id = payee_npi(payee)
        qualifier = (prov_id.present?)? 'XX' : nil
        entity = true
        #no_last_name = entity
        no_last_name = true
          last_name = payee_name(payee)
        middle_initial = nil
        suffix = nil
      end
    end
    ['NM1', '82', (no_last_name ? '2': '1'), last_name, first_name,middle_initial, '',suffix, qualifier, prov_id].trim_segment.join(@element_seperator)
  end

  def service_tooth_number_info
    @service.tooth_number.split(',').delete_if{|n| n.empty?}.uniq.collect{|t| ['REF', 'JP', t].join(@element_seperator)}
  end

  def claim_tooth_number_info
    @eob.claim_tooth_number.split(',').delete_if{|n| n.empty?}.uniq.collect{|t| ['REF', 'JP', t].join(@element_seperator)}
  end

end
