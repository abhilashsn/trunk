class Output835::CorrespondenceTemplate < Output835::Template

  # Starts and identifies an interchange of zero or more
  # interchange-related control segments
  def interchange_control_header
    ['ISA', '00', (' ' * 10), '00',(' ' * 10), 'ZZ', "RM#{(' ' * 13)}", 'ZZ',
      isa_08, Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"), 'U',
      '00401', (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record), '0', 'P', ':'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', 'RM', strip_string(gs_03) , Time.now().strftime("%Y%m%d"),
        Time.now().strftime("%H%M"), '2831', 'X', '004010X091A1'].join(@element_seperator)
  end

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    trn_elements = ['TRN', '1', ref_number]
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      trn_elements <<  '1' + @facility.facility_tin if @facility.facility_tin.present?
    else
      trn_elements <<  '1999999999'
    end
    trn_elements.join(@element_seperator)
  end

end