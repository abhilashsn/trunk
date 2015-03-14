class Output835::BarnabasCheck < Output835::Check

  def payer_additional_identification_bac(payer)
    if payer.class == Payer
      output_payid = payer.output_payid(facility)
      ["REF", "2U", output_payid].join(@element_seperator) if output_payid
    end
  end
  
  def provider_summary_info_bac
    provider_tin = (@claim && !@claim.tin.blank?)? @claim.tin : @facility.output_tin
    facility_type_code = (@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : "")
    facility_type_code = "13" if facility_type_code.blank?
    ts3_segment = ["TS3", provider_tin, facility_type_code, "#{Date.today.year()}1231", @eobs.length.to_s, total_submitted_charges.to_s.to_dollar]
    ts3_segment.compact.join(@element_seperator)
  end

  def ref_ev_loop
    elements = []
    elements << 'REF'
    elements << 'EV'
    elements << check.batch.batchid.split('_').first[0...50]
    elements.join(@element_seperator)
  end

  def payer_identification(payer)
    output_payid = payer.output_payid(facility) if payer.class == Payer
    elements = []
    elements << 'N1'
    elements << 'PR'
    elements << payer_group(output_payid).upcase
    elements.join(@element_seperator)
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
    dtm_elements = []
    dtm_elements << 'DTM'
    dtm_elements << '405'
    if check.correspondence?
      dtm_elements << check.job.batch.date.strftime("%Y%m%d")
    else
      dtm_elements << check.check_date.strftime("%Y%m%d")
    end
    dtm_elements.join(@element_seperator)
  end

end