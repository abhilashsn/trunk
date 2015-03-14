class Output835::BenefitRecoveryTemplate < Output835::Template

  # Starts and identifies an interchange of zero or more
  # functional groups and interchange-related control segments
  def interchange_control_header
    ['ISA', '00', (' ' * 10), '00', (' ' * 10), 'ZZ', trim('NETWRX',15),
      'ZZ', trim('NETWRX',15), Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
      '^', '00501', '123123123', '0', 'T', ':'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', 'NETWRX', strip_string('NETWRX'), Time.now().strftime("%Y%m%d"), Time.now().strftime("%H%M"), '123123123', 'X',
      '005010X221A1'].join(@element_seperator)
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
      bpr_elements += [id_number_qualifier, routing_number, account_num_indicator, account_number]
    else
      bpr_elements += ['', '', '', '']
    end
    bpr_elements << @payer.payid.to_s.rjust(10, '0') if @payer
    bpr_elements << '999999999'
    aba_dda_lookup = @facility.aba_dda_lookups.first
    if @check_amount.to_f > 0 && @check.payment_method != "EFT" && !aba_dda_lookup.blank?
      bpr_elements << '01'
      bpr_elements << aba_dda_lookup.aba_number
      bpr_elements << 'DA'
      bpr_elements << aba_dda_lookup.dda_number
    else
      bpr_elements << ['', '', '', '']
    end
    bpr_elements << effective_payment_date
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    ['TRN', '1', output_check_number, (@payer.payid.to_s.rjust(10, '0') if @payer),"999999999"].trim_segment.join(@element_seperator)
  end

  #The N1 loop allows for name/address information for the payee
  #which would be utilized to address remittance(s) for delivery.
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
      payee_segments.compact
    end
  end

  def payer_identification(payer)
    ['N1', 'PR', payer.name.strip.upcase[0...60].strip, 'XV', (@payer.payid.to_s if @payer)].join(@element_seperator)
  end

  def payer_technical_contact payer
  end

  def ref_ev_loop
    [ 'REF', 'EV', 'NETWRX'].join(@element_seperator)
  end

  #Loop 2100 : Supplies information common to all services of a claim
  def claim_payment_loop
    claim_payment_segments = []
    @clp_pr_amount = nil
    claim_payment_segments << claim_payment_information
    claim_payment_segments << quantity
    service_eob = @services.detect{|service| service.adjustment_line_is? }
    if service_eob
      cas_segments, @clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(service_eob,
        @client, @facility, @payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    if @is_claim_eob
      cas_segments, @clp_05_amount, crosswalked_codes = Output835.cas_adjustment_segments(@eob,
        @client, @facility, @payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << service_prov_identifier
    if @is_claim_eob
      claim_payment_segments << Output835.claim_level_remark_code_segments(@eob, @element_seperator, crosswalked_codes)
    end
    claim_payment_segments << image_page_name
    claim_payment_segments << medical_record_number
    claim_payment_segments << other_claim_related_id
    claim_payment_segments.compact
  end

  #Supplies information common to all services of a claim
  def claim_payment_information
    claim_weight = claim_type_weight
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, @eob.amount('total_submitted_charge_for_claim'),
      @eob.payment_amount_for_output(@facility, @facility_output_config),
      ( claim_weight == 22 ? "" : @eob.patient_responsibility_amount),
      "13", @eob.claim_number ].trim_segment.join(@element_seperator)
  end

  # Used when additional reference numbers specific to the claim in the
  # CLP segment are provided to identify information used in the process of
  # adjudicating this claim
  def other_claim_related_id
  end

  def quantity
    ["QTY", "PS", @services.first.service_quantity.to_f.to_amount].trim_segment.join(@element_seperator)
  end

  #supplies payment and control information to a provider for a particular service
  def service_payment_information(eob = nil,service = nil,check = nil,is_claim_eob = nil,payer = nil)
    @eob =  @eob.nil?? eob : @eob
    @service =  @service.nil?? service : @service
    ['SVC', "RX:#{captured_or_blank_patient_account_number(@eob.patient_account_number)}", @service.amount('service_procedure_charge_amount'),
      (@service.amount('service_paid_amount') == 0 ? "" : @service.amount('service_paid_amount'))].trim_segment.join(@element_seperator )
  end

end
