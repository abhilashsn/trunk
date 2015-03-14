#Represents an 835 document
class Output835::Document
  attr_reader :checks, :facility, :batchids, :log
  def initialize(checks, conf = {},check_eob_hash=nil )
    default_configuration = {:single_transaction => false, :element_seperator => '*', :segment_separator => '~', :lookahead => "\n"}
    conf.reverse_merge!(default_configuration)
    @single_transaction = conf[:single_transaction]
    @element_seperator = conf[:element_seperator]
    @segment_separator = conf[:segment_separator]
    @lookahead = conf[:lookahead]
    @isa_record = IsaIdentifier.find(:first)
    @checks = checks
    @check_eob_hash = check_eob_hash
    @facility = checks.first.batch.facility
    @facility_config = facility.facility_output_configs.first
    batchids = checks.collect{|check| check.batch.id}
    @batchids = batchids.uniq
    @eobs = checks.collect{|check| get_ordered_insurance_payment_eobs(check)}.flatten
    @output_version = @facility_config.details[:output_version]
  end

  def generate
    Output835.log.info "\n\n\n\n Starting 835 output generation at #{Time.now} for batch id/s #{@batchids}\n\n\n"
    Output835.log.info "Total no. of checks : #{checks.length}"
    check_group = (['BYH', 'CNS', 'KOD', 'LLU'].include? facility.client.group_code.to_s.upcase) ? checks.group_by{|check| check.job.batch} : {1 => checks}
    segments = []
    segments << interchange_control_header
    check_group.each do |batch, checks|
      @checks = checks
      segments << functional_group_loop
    end
    segments << interchange_control_trailer
    segments = segments.flatten.compact
    if segments.blank?
      puts "835 output generation failed with errors, please refer <rails_root>/835Generation.log for details"
      return false
    else
      if @facility_config.details[:wrap_835_lines]
        segments = segments.join(@segment_separator) + '~'
        segments = segments.scan(/.{1,80}/).join("\n")
      else
        segments = segments.join(@segment_separator + @lookahead) + '~'
      end
      @isa_record.update_attributes({:isa_number => (@isa_record.isa_number + 1)})
      return segments
    end   
  rescue Exception => e
    Output835.log.error e.message
    Output835.log.error e.backtrace.join("\n")
    puts "835 output generation failed with errors, please refer <rails_root>/835Generation.log for details"
    false
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
    if facility.name.upcase == "SOLUTIONS 4 MDS"
      static_value = "4108"
      isa_08 = trim(static_value,15)
    else
      if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
        isa_08 = trim(@facility_config.details[:payee_name].upcase,15)
      else
        isa_08 = trim(facility.name.upcase, 15)
      end
    end
    isa_elements << isa_08
    isa_elements << Time.now().strftime("%y%m%d")
    isa_elements << Time.now().strftime("%H%M")
    isa_elements << ((!@output_version || @output_version == '4010') ? 'U' : '^')
    isa_elements << ((!@output_version || @output_version == '4010') ? '00401' : '00501')
    isa_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)
    isa_elements << '0'
    isa_elements << 'P'
    isa_elements << ':'
    isa_elements.join(@element_seperator)
  end

  # A functional group of related transaction sets, within the scope of X12
  # standards, consists of a collection of similar transaction sets enclosed by a
  # functional group header and a functional group trailer
  def functional_group_loop
    segments = []
    segments << functional_group_header
    segments << transactions
    segments << functional_group_trailer(nil)
    segments = segments.compact
    segments
  end

  def functional_group_header
    facility_name = facility.name.upcase.slice(0, 15)
    gs_elements = []
    gs_elements << 'GS'
    gs_elements << 'HP'
    gs_elements << payer_id
    if facility.name.upcase == "SOLUTIONS 4 MDS"
      gs_03 = "4108"
    else
      if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
        gs_03 = (@facility_config.details[:payee_name]).strip
      else
        gs_03 = facility_name.strip
      end
    end
    gs_elements << gs_03
    gs_elements << group_date
    gs_elements << Time.now().strftime("%H%M")
    gs_elements << '2831'
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
    ge_elements << '2831'
    ge_elements.join(@element_seperator)
  end

  # To define the end of an interchange of zero or more functional groups and
  # interchange-related control segments
  def interchange_control_trailer
    iea_elements = []
    iea_elements << 'IEA'
    iea_elements << '1'
    iea_elements << (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)
    iea_elements.join(@element_seperator)
  end

  def checks_in_functional_group(batch_id)
    if batch_id
      checks_in_batch = checks.collect {|check| check.batch.id == batch_id}
      checks_in_batch.length
    else
      checks.length
    end
  end

  # Formats a given string by taking in its size
  # if string length < size, it pads the string with white spaces
  # to the right
  # else slices the string to the size specified
  def trim(string, size)
    if string
      if string.strip.length > size
        string.strip.slice(0,size)
      else
        string.strip.ljust(size)
      end
    end
  end
  
  def group_date
    (facility.index_file_parser_type == 'Barnabas' ? checks.first.batch.date.strftime("%Y%m%d") : Time.now().strftime("%Y%m%d"))
  end

  def payer_id
    payid = @facility_config.details[:isa_06]
    if payid == 'Predefined Payer ID'
      if $IS_PARTNER_BAC
        @facility_config.predefined_payer.to_s
      elsif facility.index_file_parser_type == 'Barnabas'
        checks.first.payer.output_payid(facility) if checks.first.payer
      elsif facility.client.name.upcase == "PACIFIC DENTAL SERVICES"
        checks.first.payer.gcbs_output_payid(@facility)
      else
        checks.first.payer.supply_payid if checks.first.payer
  end
    else
      payid.to_s
    end
  end
  
  # Wrapper for each check in this 835
  def transactions
    segments = []
    batch_based_index = 0

    check_klass = Output835.class_for("Check", facility)
    Output835.log.info "Applying class #{check_klass}"
    check_op = check_klass.new(nil, facility, 0, @element_seperator, @check_eob_hash)
    check_op.instance_variable_set("@plb_excel_sheet", @plb_excel_sheet)
    checks.each_with_index do |check, index|
      batch_based_index += 1
      batch_based_index = 1 if new_batch?(check)
      Output835.log.info "Generating Check related segments for check: #{check.check_number}"
      check_klass.class_eval("@@batch_based_index =  #{batch_based_index}")
      segments << check_op.generate_new(check, index)
    end
    segments
  end

  def new_batch? check
    batchid = check.batch.batchid.to_s
    if batchid != @prev_batchid
      @prev_batchid = batchid
      true
    else
      false
    end
  end
 
end