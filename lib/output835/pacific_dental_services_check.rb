class Output835::PacificDentalServicesCheck < Output835::Check

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
      if payer
        trn_elements = []
        trn_elements << 'TRN'
        trn_elements << '1'
        trn_elements <<  ref_number
        trn_elements <<  '1999999999'
        trn_elements.join(@element_seperator)
      end
  end

  def provider_summary_info_bac
    provider_tin = (@claim && !@claim.tin.blank?)? @claim.tin : @facility.output_tin
    facility_type_code = (@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : "13")
    facility_type_code = "13" if facility_type_code.blank?
    ts3_segment = ["TS3", provider_tin, facility_type_code, "#{Date.today.year()}1231", @eobs.length.to_s, total_submitted_charges.to_s.to_dollar]
    ts3_segment.compact.join(@element_seperator)
  end

  def ref_ev_loop
    nil
  end

  def transaction_set_line_number(index)
    ['LX', index.to_s].join(@element_seperator)
  end


end