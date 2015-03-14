# Cutomized 835 document food Goodman Campbell
class Output835::GoodmanCampbellDocument < Output835::Document
  def functional_group_header
    gs_elements = []
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements <<  ((!@nextgen || (!@output_version || @output_version == '4010')) ? 'REVMED' : payer_id.to_s)
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      gs_03 = (@facility_config.details[:payee_name]).strip.justify(14, 'X')
    else
      gs_03 = payer_id.to_s.justify(14, 'X')
    end
    gs_elements <<  ((!@nextgen || (!@output_version || @output_version == '4010')) ? gs_03 : 'INDIANAPOLIS NE')
    gs_elements << Time.now().strftime("%Y%m%d")
    gs_elements << Time.now().strftime("%H%M")
    gs_elements << '2831'
    gs_elements << 'X'
    gs_elements << ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')
    gs_elements.join(@element_seperator)
  end

  def payer_id
    payid = @facility_config.details[:isa_06]
    if payid == 'Predefined Payer ID'
      payer = checks.first.payer
      job = checks.first.job
      if payer && job.payer_group == 'PatPay'
        'P9998'
      elsif payer
        (@nextgen ? payer.gcbs_output_payid(@facility): payer.output_payid(facility))
      end
    else
      payid.to_s
    end
  end

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
    isa_elements << trim(payer_id, 15)
    isa_elements << 'ZZ'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      isa_08 = trim(@facility_config.details[:payee_name].upcase,15)
    else
      isa_08 = trim(facility.name.upcase, 15)
    end
    isa_elements << ((!@nextgen || (!@output_version || @output_version == '4010')) ? isa_08 : 'INDIANAPOLIS NE')
    isa_elements << Time.now().strftime("%y%m%d")
    isa_elements << Time.now().strftime("%H%M")
    isa_elements <<  ((!@output_version || @output_version == '4010') ? 'U' : '^')
    isa_elements << ((!@output_version || @output_version == '4010') ? '00401' : '00501')
    isa_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)
    isa_elements << '0'
    isa_elements << 'P'
    isa_elements << ':'
    isa_elements.join(@element_seperator)
  end

   # Wrapper for each check in this 835
  def transactions
    segments = []
    check_op = Output835::GoodmanCampbellCheck.new(facility, @element_seperator, @nextgen)

    checks.each_with_index do |check, index|
      Output835.log.info "Generating Check related segments for check: #{check.check_number}"
      segments << check_op.generate_new(check, index)
    end
    segments
  end
  
end
