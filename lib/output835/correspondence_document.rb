class Output835::CorrespondenceDocument < Output835::Document
  
  # Starts and identifies an interchange of zero or more
  # interchange-related control segments
  def interchange_control_header
    empty_str = ''
    isa_elements = []
    isa_elements << 'ISA'
    isa_elements << '00'
    isa_elements << trim(empty_str,10)
    isa_elements << '00'
    isa_elements << trim(empty_str,10)
    isa_elements << 'ZZ'
    isa_elements << "RM#{trim(empty_str,13)}"
    isa_elements << 'ZZ'
    Output835.log.info "Facility abbreviation should be present and make sure whether its entered from FCUI"
    Output835.log.info "Facility abbreviation is : #{facility.abbr_name}"
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      isa_08 = trim(@facility_config.details[:payee_name].upcase,15)
    else
      isa_08 = trim(facility.name.upcase, 15)
    end
    isa_elements << isa_08
    isa_elements << Time.now().strftime("%y%m%d")
    isa_elements << Time.now().strftime("%H%M")
    isa_elements << 'U'
    isa_elements << '00401'
    isa_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)
    isa_elements << '0'
    isa_elements << 'P'
    isa_elements << ':'
    isa_elements.join(@element_seperator)
  end
  
  def functional_group_header
    gs_elements = []
    facility_name = facility.name.upcase.slice(0, 15)
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements << 'RM'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      gs_03 = (@facility_config.details[:payee_name]).strip
    else
      gs_03 = facility_name.strip
    end
    gs_elements << gs_03
    gs_elements << Time.now().strftime("%Y%m%d")
    gs_elements << Time.now().strftime("%H%M")
    gs_elements << '2831'
    gs_elements << 'X'
    gs_elements << '004010X091A1'
    gs_elements.join(@element_seperator)
  end
  
  def transactions
    segments = []
    checks.each_with_index do |check, index|
      Output835.log.info "Generating Check related segments for check: #{check.check_number}"
      check_klass = Output835.class_for("CorrespondenceCheck", facility)
      Output835.log.info "Applying class #{check_klass}" if index == 0
      check = check_klass.new(check, facility, index, @element_seperator)
      segments += check.generate
    end
    segments
  end
  
  
end