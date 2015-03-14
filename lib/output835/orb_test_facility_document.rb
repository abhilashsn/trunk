# To change this template, choose Tools | Templates
# and open the template in the editor.

class Output835::OrbTestFacilityDocument< Output835::MedassetsDocument
  
  def interchange_control_header
    empty_str = ''
    isa_elements = []
    isa_elements << 'ISA'
    isa_elements << '00'
    isa_elements << trim(empty_str,10)
    isa_elements << '00'
    isa_elements << trim(empty_str,10)
    isa_elements << 'ZZ'
    isa_elements << trim('ORBOMED',15)
#    isa_06_number = '01234'
#    isa_elements << isa_06_number.rjust(15, '0')
    isa_elements << 'ZZ'
    isa_elements << trim('00303',15)
#    isa_08_number = '56789'
#    isa_elements << isa_08_number.rjust(15, '0')
    isa_elements << Time.now().strftime("%y%m%d")
    isa_elements << Time.now().strftime("%H%M")
    isa_elements << ((!@output_version || @output_version == '4010') ? 'U' : '^')
    isa_elements << ((!@output_version || @output_version == '4010') ? '00401' : '00501')
    isa_elements << '134061042'
    isa_elements << '0'
    isa_elements << 'P'
    isa_elements << ':'
    isa_elements.join(@element_seperator)
  end

  def functional_group_header
    gs_elements = []
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements << 'ORBOMED'
    gs_elements << '00303'
    gs_elements << Time.now().strftime("%Y%m%d")
    gs_elements << Time.now().strftime("%H%M%S%2N")
    gs_elements << '134061042'
    gs_elements << 'X'
    gs_elements << ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')
    gs_elements.join(@element_seperator)
  end


  def transactions
    segments = []
    check_nums = checks.collect{|check| check.check_number}
    checks.each_with_index do |check, index|
      Output835.log.info "Generating Check related segments for check: #{check.check_number}"
      check_klass = Output835.class_for("Check", facility)
      Output835.log.info "Applying class #{check_klass}" if index == 0
      check = check_klass.new(check, facility, index, @element_seperator, check_nums)
      segments += check.generate
    end
    segments
  end


  def functional_group_trailer(batch_id)
    ge_elements = []
    ge_elements << 'GE'
    ge_elements << checks_in_functional_group(batch_id)
    ge_elements << '134061042'
    ge_elements.join(@element_seperator)
  end

  def interchange_control_trailer
    iea_elements = []
    iea_elements << 'IEA'
    iea_elements << '1'
    iea_elements << '134061042'
    iea_elements.join(@element_seperator)
  end


end
