class Output835::BarnabasTemplate < Output835::Template


  def payer_additional_identification(payer)
    if payer.class == Payer
      output_payid = payer.output_payid(@facility)
      ["REF", "2U", output_payid].join(@element_seperator) if output_payid
    end
  end

  def provider_summary_info
    provider_tin = (@claim && @claim.tin.present?)? @claim.tin : @facility.output_tin
    first_claim = @eobs.first.claim_information
    facility_type_code = (first_claim ? first_claim.facility_type_code.to_s : "")
    facility_type_code = "13" if facility_type_code.blank?
    ["TS3", provider_tin, facility_type_code, "#{Date.today.year()}1231", @eobs.length.to_s, total_submitted_charges.to_s.to_dollar].compact.join(@element_seperator)
  end

  def ref_ev_loop
    ['REF', 'EV', @batch.batchid.split('_').first[0...50]].join(@element_seperator)
  end

  def payer_identification(payer)
    output_payid = payer.output_payid(@facility) if payer.class == Payer
    ['N1', 'PR', payer_group(output_payid).upcase].join(@element_seperator)
  end

  def payer_group payerid
    case payerid
    when 'WC001'
      'WorkersComp'
    when 'NF001'
      'NoFault'
    when 'CO001'
      'Commercial'
    when 'D9998'
      'Default'
    else
      'Unidentified'
    end
  end

  def date_time_reference
    ['DTM', '405', (@is_correspndence_check ? @batch.date.strftime("%Y%m%d") : @check.check_date.strftime("%Y%m%d") )].join(@element_seperator)
  end

  def claim_payment_information
    claim_weight = claim_type_weight
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, @eob.amount('total_submitted_charge_for_claim'),
      @eob.payment_amount_for_output(@facility, @facility_output_config), (claim_weight == 22 ? "" : @eob.patient_responsibility_amount),
      plan_type.to_s, @eob.claim_number, eob_facility_type_code, claim_freq_indicator, plan_code , @eob.drg_code, @eob.drg_weight].trim_segment.join(@element_seperator)
  end

  def plan_code
    @claim.plan_code.to_s[0] if @claim
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
    service_segments << service_supplemental_amount(supp_amount) unless supp_amount.blank?
    service_segments << standard_industry_code_segments(@service)
    [service_segments.compact.flatten, pr_amount]
  end

  def service_prov_identifier
    if @facility.details['re_pricer_info'] && @eob.alternate_payer_name.present?
      ['NM1', 'PR', '2', @eob.alternate_payer_name.to_s.strip].join(@element_seperator)
    end
  end
  
end