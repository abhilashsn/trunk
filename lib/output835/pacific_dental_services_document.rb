class Output835::PacificDentalServicesDocument < Output835::Document

  def interchange_control_header
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      isa_08 = trim(@facility_config.details[:payee_name].upcase,15)
    else
      isa_08 = facility.name.upcase.justify(15)
    end
    @gs3 = isa_08
    [ 'ISA', '00', (' '*10), '00', (' '*10), 'ZZ', payer_id.to_s.justify(15),
        'ZZ', isa_08 , Time.now().strftime("%y%m%d"),
        Time.now().strftime("%H%M"), ((!@output_version || @output_version == '4010') ? 'U' : '^'),
        ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
        (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record), '0', 'P', '>'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', payer_id, @gs3,
        Time.now().strftime("%Y%m%d"), Time.now().strftime("%H%M"), '1', 'X',
        ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end

  def functional_group_trailer(batch_id)
    ['GE', checks_in_functional_group(batch_id), '1'].join(@element_seperator)
  end
  
end