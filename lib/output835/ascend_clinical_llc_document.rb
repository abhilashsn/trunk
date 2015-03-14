class Output835::AscendClinicalLlcDocument < Output835::Document
  
  def interchange_control_header
    empty_str = ''
    isa_elements = ['ISA', '00', trim(empty_str,10), '00', trim(empty_str,10), 'ZZ', "450480357".ljust(15, " "),
         'ZZ', "943357013".ljust(15, " "), Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
         ((!@output_version || @output_version == '4010') ? 'U' : '{'),
         ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
         '000021316', '0', 'P', ':'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', '450480357', '943357013', Time.now().strftime("%Y%m%d"),
        Time.now().strftime("%H%M"), '1', 'X',
        ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end

  def functional_group_trailer(batch_id)
    ['GE', checks_in_functional_group(batch_id), '1'].join(@element_seperator)
  end

  def interchange_control_trailer
    ['IEA', '1', '000021316'].join(@element_seperator)
  end

end
