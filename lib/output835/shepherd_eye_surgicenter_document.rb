class Output835::ShepherdEyeSurgicenterDocument < Output835::Document
     
  # Starts and identifies an interchange of zero or more
  # functional groups and interchange-related control segments
  def interchange_control_header
    empty_str = ''
    isa_elements = []
    isa_elements << 'ISA'
    isa_elements << '00'
    isa_elements << trim(empty_str,10)
    isa_elements << '00'
    isa_elements << trim(empty_str,10)
    isa_elements << '30'
    isa_elements << trim('582574363', 15)
    isa_elements << '30'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      isa_08 = trim(@facility_config.details[:payee_name].upcase,15)
    else
      isa_08 = trim(facility.tin, 15)
    end
    isa_elements << isa_08
    isa_elements << Time.now().strftime("%y%m%d") 
    isa_elements << Time.now().strftime("%H%M")
    isa_elements <<  ((!@output_version || @output_version == '4010') ? 'U' : '^')
    isa_elements << ((!@output_version || @output_version == '4010') ? '00401' : '00501')
    isa_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record) 
    isa_elements << '1'
    isa_elements << 'P'
    isa_elements << ':'
    isa_elements.join(@element_seperator)
  end
   
  # header part of a functional group loop
  def functional_group_header
    gs_elements = []
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements << payer_id  
    gs_elements << '1000000'
    gs_elements << Time.now().strftime("%Y%m%d") 
    gs_elements << Time.now().strftime("%H%M")
    gs_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record) 
    gs_elements << 'X'
    gs_elements << ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')
    gs_elements.join(@element_seperator)
  end

  # The use of identical data interchange control numbers in the associated
  # functional group header and trailer is designed to maximize functional
  # group integrity. The control number is the same as that used in the
  # corresponding header.
  def functional_group_trailer(batch_id)
    ge_elements = []
    ge_elements << 'GE'
    ge_elements << checks_in_functional_group(batch_id)
    ge_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)
    ge_elements.join(@element_seperator)
  end

  def payer_id
    payid = @facility_config.details[:isa_06]
    if payid == 'Predefined Payer ID'
      check = checks.first
      batch = check.batch
      facility = batch.facility
      check_payer = check.payer
      if check_payer
        default_payer = FacilitiesPayersInformation.find(:first,:conditions=>["facility_id = #{batch.facility.id} and payer= '#{check_payer.payer}' "])
	payid = (default_payer.blank?) ? @facility_config.predefined_payer.to_s : default_payer.output_payid
      end
    else
      payid.to_s
    end
  end
  
end
