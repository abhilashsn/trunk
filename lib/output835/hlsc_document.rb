class Output835::HlscDocument < Output835::Document
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
    isa_elements << 'ZZ'
    isa_elements << trim('HLSC', 15)
    isa_elements << 'ZZ'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      isa_08 = trim(@facility_config.details[:payee_name].upcase,15)
    else
      isa_08 = trim(federal_tax_id, 15)
    end
    isa_elements << isa_08
    isa_elements << Time.now().strftime("%y%m%d")
    isa_elements << Time.now().strftime("%H%M")
    isa_elements << 'U'
    isa_elements << '00401'
    isa_elements << facility.lockbox_number.rjust(9, '0')
    isa_elements << '0'
    isa_elements << 'P'
    isa_elements << '>'
    isa_elements.join(@element_seperator)
  end
  # A functional group of related transaction sets, within the scope of X12
  # standards, consists of a collection of similar transaction sets enclosed by a
  # functional group header and a functional group trailer
  def functional_group_loop
    segments = []
    batchids.each do |batch_id|
      Output835.log.info "batch_id : #{batch_id}"
      segments << functional_group_header
      segments << transactions
      segments << functional_group_trailer(batch_id)
    end
    segments = segments.compact
    segments
  end
  def functional_group_header
    gs_elements = []
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements << 'HLSC'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      gs_03 = (@facility_config.details[:payee_name]).strip
    else
      gs_03 = federal_tax_id
    end
    gs_elements << gs_03
    gs_elements << Time.now().strftime("%Y%m%d")
    gs_elements << Time.now().strftime("%H%M")
    gs_elements << '1'
    gs_elements << 'X'
    gs_elements << '004010X091A1'
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
    ge_elements << '1'
    ge_elements.join(@element_seperator)
  end

  # To define the end of an interchange of zero or more functional groups and
  # interchange-related control segments
  def interchange_control_trailer
    iea_elements = []
    iea_elements << 'IEA'
    iea_elements << '1'
    iea_elements << facility.lockbox_number.rjust(9, '0')
    iea_elements.join(@element_seperator)
  end

  def checks_in_functional_group(batch_id)
    checks_in_batch = checks.collect {|check| check.batch.id == batch_id}
    checks_in_batch.length
  end
  
  def federal_tax_id
		(facility.facility_tin unless facility.facility_tin.blank? ) || '999999999'
	end
end