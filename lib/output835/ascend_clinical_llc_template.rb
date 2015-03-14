class Output835::AscendClinicalLlcTemplate < Output835::Template

  def interchange_control_header
    ['ISA', '00',  (' ' * 10) , '00',  (' ' * 10), 'ZZ', "450480357      ",
      'ZZ', "943357013      ", Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
      ((!@output_version || @output_version == '4010') ? 'U' : '{'),
      ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
      '000021316', '0', 'P', ':'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', '450480357',strip_string('943357013'), Time.now().strftime("%Y%m%d"),
      Time.now().strftime("%H%M"), '1', 'X',
      ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end

  def functional_group_trailer(batch_id = nil)
    ['GE', checks_in_functional_group(batch_id), '1'].join(@element_seperator)
  end

  def interchange_control_trailer
    ['IEA', '1', '000021316'].join(@element_seperator)
  end

  def financial_info(facility = nil, check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
    @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
    @micr = @micr.nil?? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil?? correspondence_check : @is_correspndence_check
    @check_amount = @check_amount.nil?? check_amount : @check_amount
    @facility_output_config = @facility_output_config.nil?? facility_config : @facility_output_config
    bpr_elements = [ "BPR", bpr_01, @check_amount.to_s, 'C', payment_indicator]
    
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      bpr_elements += ["CCP", "01",  "999999999", "DA", "999999999", "9999999999",
        "199999999", "01", "999999999","DA", "999999999"]
    else
      bpr_elements += ['', '', '', '','', '', '', '', '', '','']
    end
    bpr_elements << effective_payment_date
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

  def payer_additional_identification(payer)
    payid = nil
    if payer.class == Payer
      claim_information = @eobs.where("claim_payid is not null").group("claim_payid").order("COUNT(claim_payid) DESC,id ASC")
      if claim_information && claim_information[0].present?
        payid = claim_information[0].claim_payid.to_s
      else
        check_payer = (@micr && @micr.payer && @facility.details[:micr_line_info] ? @micr.payer : @check.payer)
        payid= output_payid(check_payer)
      end
      ["REF", "2U", payid].join(@element_seperator) unless payid.blank?
    end
  end

  def ref_ev_loop
    ['REF','EV', @check.job.initial_image_name.to_s[0...50]].join(@element_seperator)
  end

  def payer_identification(payer)
    ['N1', 'PR', payer.name.strip.upcase[0...60].strip].join(@element_seperator)
  end

  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if @is_claim_eob
    claim_segments = [ claim_payment_loop]
    claim_segments << claim_received_date if @is_claim_eob
    claim_segments << claim_supplemental_info unless @facility.details[:interest_in_service_line]
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments << service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

  def claim_payment_loop
    @clp_pr_amount = nil
    claim_payment_segments = [claim_payment_information]
    service_eob = @services.detect{|service| service.adjustment_line_is? }
    if service_eob.present?
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
    claim_payment_segments << insured_name unless @eob.pt_name_eql_sub_name?
    claim_payment_segments << service_prov_name
    if @is_claim_eob
      claim_payment_segments << Output835.claim_level_remark_code_segments(@eob, @element_seperator, crosswalked_codes)
    end
    claim_payment_segments << reference_identification_qualifier
    claim_payment_segments.compact
  end


  def claim_payment_information
    claim_weight = claim_type_weight
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, @eob.amount('total_submitted_charge_for_claim'),
      @eob.payment_amount_for_output(@facility, @facility_output_config),
      (claim_weight == 22 ? "" : @eob.patient_responsibility_amount), plan_type,
      @eob.claim_number, eob_facility_type_code, claim_freq_indicator].trim_segment.join(@element_seperator)
  end

  def service_prov_name(eob = nil,claim = nil)
    @eob =  @eob.nil?? eob : @eob
    prov_id, qualifier = service_prov_identification
    ['NM1', '82', (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
      prov_last_name_or_org, @eob.rendering_provider_first_name, @eob.rendering_provider_middle_initial,
      '', '', qualifier, prov_id].trim_segment.join(@element_seperator)
  end

  def reference_identification_qualifier
    insurance_policy_number = @eob.insurance_policy_number.to_s
    ['REF', '1L', insurance_policy_number].join(@element_seperator) if insurance_policy_number.present?
  end

  def claim_received_date
    ['DTM', '050', @eob.claim_from_date.strftime("%Y%m%d")].join(@element_seperator)
  end


  def generate_services
    service_segments = []
    is_adjustment_line = @service.adjustment_line_is?
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference
    unless is_adjustment_line
      cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, @element_seperator)
    else
      cas_segments, pr_amount = nil,0.0
    end
    service_segments << cas_segments unless is_adjustment_line
    service_segments << service_line_item_control_num
    service_segments << provider_control_number unless is_adjustment_line
    supp_amount = supplemental_amount
    service_segments << service_supplemental_amount(supp_amount) unless supplemental_amount.blank?
    service_segments << standard_industry_code_segments(@service)
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

end