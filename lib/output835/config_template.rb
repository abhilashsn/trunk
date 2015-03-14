class Output835::ConfigTemplate

  include Output835ConfigHelper
  attr_accessor :last_check, :last_eob

  def initialize(checks, facility, config, check_grouper=nil, conf = {},check_eob_hash=nil, total_jobs=nil )
    default_configuration = {:single_transaction => false, :element_seperator => '*', :segment_separator => '~', :lookahead => "\n"}
    conf.reverse_merge!(default_configuration)
    @single_transaction = conf[:single_transaction]
    @element_seperator = conf[:element_seperator]
    @segment_separator = conf[:segment_separator]
    @lookahead = conf[:lookahead]
    @check_eob_hash = check_eob_hash
    @checks = checks
    @facility = facility
    @facility_name = facility.name.upcase
    @client = facility.client
    @client_name = @client.name.strip.upcase
    @facility_config = config
    @facility_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @config_835 = config.details
    @first_check = @checks.first
    @job =  @first_check.job
    @batch = @first_check.batch
    @facility_class_type = @facility_config.multi_transaction ? 'multi' : 'single'
    @facility_lockboxes = @facility.facility_lockbox_mappings
    @insurance_eob_output_config = @facility.output_configuration 'Insurance EOB'
    @patpay_eob_output_config = @facility.output_configuration 'Patient Payment'
    @insurance_config_details = @insurance_eob_output_config.details
    @patpay_config_details = @patpay_eob_output_config.details
    @output_version = @insurance_eob_output_config.details[:output_version]
    @isa_record = IsaIdentifier.first
    @delimiter = ':'
    @check_grouper = check_grouper
    batchids = @checks.collect{|check| check.batch.id}
    @batchids = batchids.uniq
    initialize_segment_config
  end

  def create_segment seg_name, static_part
    if @config_835["configurable_segments"][seg_name]
      if @config_835["#{seg_name}_segment"]
        config_part = @config_835["#{seg_name}_segment"].convert_keys
        segment = config_part.merge(static_part).segmentize
        segment = eval( "if @#{seg_name}_config
                         segment.collect! do |element|
                           if element.include? '@'
                             element, default = element.split('@')
                           end
                           if element =~ /^\\[[^\\[\\]]+\\]$/
                             value = eval_hash @#{seg_name}_config[element]
                             if default =~ /^\\[[^\\[\\]]+\\]$/ and value.blank?
                               value = eval_hash @#{seg_name}_config[default]
                             end
                           else
                             value = element
                           end
                           ((value.blank? && default) ? default : value)
                         end
                       else
                         segment
                       end " )
        trim_segment(segment).join('*')
      end
    else
      nil
    end
  end

  def eval_hash value_string
    eval(value_string.to_s)
  end

  def trim_segment(array)
    while array.last.blank?
      array.pop
    end
    if array.first!='ISA'
      array.collect {|element| element.to_s.strip}
    end
    return array
  end

  def generate
    Output835.log.info "\n\n\n\n Starting 835 output generation at #{Time.now} for batch id/s #{@batchids} (with 835 config)\n\n\n"
    Output835.log.info "Total no. of checks : #{@checks.length}"
    @isa_record = IsaIdentifier.find(:first)
    @counter =  @isa_record? @isa_record.isa_number.to_s.justify(9, '0') : nil
    segments = [interchange_control_header, functional_group_loop, interchange_control_trailer]
    segments = segments.flatten.compact
    unless segments.blank?
      if @config_835[:wrap_835_lines]
        segments = segments.join("~") + '~'
        segments = segments.scan(/.{1,80}/).join("\n")
      else
        segments = segments.join('~' + "\n") + '~'
      end
      @isa_record.update_attributes({:isa_number => (@isa_record.isa_number + 1)})
      return segments
    else
      return false
    end
  end

  def interchange_control_header
    isa_elements = {0=> 'ISA', 2 => ' ' * 10, 4 => ' ' * 10, 9 => Time.now().strftime('%y%m%d'),
      10 => Time.now().strftime('%H%M') }
    Output835.log.info "Creating ISA segments"
    isa = create_segment('isa', isa_elements)
    if isa
      isa = isa.split('*')
      isa[6] = isa[6].justify(15)
      isa[8] = isa[8].justify(15)
      isa.join('*')
    end
  end

  def functional_group_loop
    segments = [functional_group_header, transactions,functional_group_trailer]
    segments = segments.flatten.compact
  end

  def interchange_control_trailer
    Output835.log.info "Creating IEA segments"
    elements = {0 => 'IEA', 1 => '1'}
    create_segment 'iea', elements
  end

  def functional_group_header
    Output835.log.info "Creating GS segments"
    elements = {0 => 'GS', 1 => 'HP', 7 => 'X'  }
    create_segment 'gs', elements
  end

  def transactions
    segments = []
    @batch_based_index = 0
    @checks.each_with_index do |check, index|
      @check_grouper.last_check = check
      @check = check
      @index = index
      @eob_type = @check.eob_type
      if @eob_type == "Insurance"
        @config_835 = @insurance_config_details
        @config_obj = @insurance_eob_output_config
      else
        @config_835 = @patpay_config_details
        @config_obj = @patpay_eob_output_config
      end
      @check_amount = check_amount
      @batch_based_index += 1
      @batch_based_index = 1 if new_batch?
      segments << generate_check
    end
    segments
  end

  def functional_group_trailer
    Output835.log.info "Creating GE segments"
    elements =  {0 => 'GE', 1 => @checks.length.to_s}
    create_segment 'ge', elements
  end

  def generate_check
    @micr = @check.micr_line_information
    if @micr && @micr.payer && @facility.details[:micr_line_info]
      @payer = @micr.payer
    else
      @payer = @check.payer
    end
    #check_image = @check.image_file_name.to_s
    @batch = @check.batch
    @eob_type = @check.eob_type
    if @check.insurance_payment_eobs.length > 1
      @eobs =  get_ordered_insurance_payment_eobs(@check)
    else
      @eobs = @check.insurance_payment_eobs
    end
    @payer_tin = (@payer && @payer.payer_tin) ? '1' + @payer.payer_tin : '1' + @facility.facility_tin
    @payerid =  @payer.payer_identifier(@micr)
    #st03 = (@claim && !@claim.npi.blank? || !@payee.npi.blank?) ? 'XX' :'FI'
    @check_sequence = (@index + 1).to_s
    #   @default_payer_address = @payer.default_payer_address(@facility, @check)
    @svc_procedure_cpt_code = true
    @composite_med_proc_id = true
    @is_correspndence_check = @check.correspondence?
    transaction_segments = [ transaction_set_header, financial_info, reassociation_trace]
    transaction_segments << ref_ev_loop if !@config_835.blank? and @config_835[:ref_ev_batchid]== true
    transaction_segments << date_time_reference
    transaction_segments << payer_identification_loop
    transaction_segments << payee_identification_loop
    transaction_segments << claim_loop
    transaction_segments << provider_adjustment
    #@se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments = transaction_segments.flatten.compact
    @transaction_count = transaction_segments.length + 1
    transaction_segments << transaction_set_trailer   #(transaction_segments.length + 1)
  end


  def transaction_set_header
    Output835.log.info "Creating ST segments"
    elements = {0 => 'ST', 1 => '835'}
    create_segment 'st', elements
  end

  def financial_info
    Output835.log.info "Creating BPR segments"
    check_amount = check_amount_truncate
    if @config_835[:configurable_segments][:bpr_from_code]
      Output835.log.info "BPR from code...."
      bpr_class = find_class(@facility, @facility_class_type)
      financial_info_details = bpr_class.new(@checks, @facility,@facility_config)
      financial_info_details.financial_info(@facility,@check,@facility_config,check_amount,@micr,@is_correspndence_check)
    else
      Output835.log.info "BPR from config..."
      @bpr_elements = []
      if (@config_835['bpr_segment']['5'] == "[Value From Code]" && @config_835['bpr_segment']['6'] == "[Value From Code]" && @config_835['bpr_segment']['7'] == "[Value From Code]" && @config_835['bpr_segment']['8'] == "[Value From Code]" &&
            @config_835['bpr_segment']['9'] == "[Value From Code]" && @config_835['bpr_segment']['10'] == "[Value From Code]" && @config_835['bpr_segment']['11'] == "[Value From Code]" && @config_835['bpr_segment']['12'] == "[Value From Code]" &&
            @config_835['bpr_segment']['13'] == "[Value From Code]" && @config_835['bpr_segment']['14'] == "[Value From Code]" && @config_835['bpr_segment']['15'] == "[Value From Code]")
        Output835.log.info "BPR from config with Value From Code option"
        find_other_bpr_elements
        elements = {0 => 'BPR',
          3 => 'C', 4 => payment_indicator, 5 => @bpr_elements[0],6=>@bpr_elements[1],7=>@bpr_elements[2],8=>@bpr_elements[3],
          9 => @bpr_elements[4],10=>@bpr_elements[5],11=>@bpr_elements[6],12=>@bpr_elements[7],13 => @bpr_elements[8],14=>@bpr_elements[9],15=>@bpr_elements[10]}
      else
        Output835.log.info "BPR from config with out Value From Code option"
        elements = {0 => 'BPR',
          3 => 'C', 4 => payment_indicator, 5 => '' }
      end
      create_segment 'bpr', elements
    end
  end

  def reassociation_trace
    Output835.log.info "Creating TRN segments"
    if @payer
      elements =  {0 => 'TRN', 1 => '1'}
      create_segment 'trn', elements
    end
  end

  def ref_ev_loop
    Output835.log.info "Creating REF EV segments"
    elements = {0=>'REF', 1=>'EV'}
    create_segment 'refev', elements
  end

  def date_time_reference
    Output835.log.info "Creating DTM 405 segments"
    elements = {0 => 'DTM', 1 => '405'}
    create_segment 'dtm405', elements
  end

  def payer_identification_loop
    payer = get_payer
    @n1_pr_payer = payer
    if payer
      payer_segments = [payer_identification, address(payer), geographic_location(payer),unique_output_payid, payer_technical_contact(payer)]
      payer_segments = payer_segments.compact
    end
  end

  def payer_identification
    Output835.log.info "Creating N1 PR segments"
    elements = {0 => 'N1', 1 => 'PR'}
    create_segment 'n1pr', elements
  end

  def address(party)
    elements = {0 => 'N3'}
    Output835.log.info "address of #{party.class}"
    id = ((party.class == Payer || party.class == Patient ) ? 'pr' : 'pe')
    Output835.log.info "Creating N3 #{id} segments"
    create_segment "n3#{id}", elements
  end

  def geographic_location(party)
    Output835.log.info "geographic location of #{party.class}"
    elements = {0 => 'N4', 4 => '', 5 => '', 6 => ''}
    id = ((party.class == Payer || party.class == Patient) ? 'pr' : 'pe')
    Output835.log.info "Creating N4 #{id} segments"
    create_segment "n4#{id}", elements
  end

  def payer_technical_contact payer
    Output835.log.info "Creating PER BL segments"
    elements = {0 => 'PER', 1 => 'BL'}
    create_segment "perbl", elements
  end

  def payee_identification_loop
    @provider_tin = ((@claim && !@claim.tin.blank?) ? @claim.tin : @facility.facility_tin)
    @payee = find_payee
    @st03 = (@claim && !@claim.npi.blank? || !@payee.npi.blank?) ? 'XX' :'FI'
    if @payee
      payee_segments = [ payee_identification, address(@payee), geographic_location(@payee),payee_additional_identification(@payee),
        provider_number]
      payee_segments = payee_segments.compact
    end
  end

  def payee_identification
    Output835.log.info "Creating N1 PE segments"
    if @config_835[:configurable_segments][:n1pe_from_code]
      Output835.log.info "N1 PE from code"
      n1pe_class = find_class(@facility, @facility_class_type)
      payee_details = n1pe_class.new(@checks, @facility,@facility_config)
      payee_details.payee_identification(@payee,@check,@claim,@eobs)
    else
      Output835.log.info "N1 PE using config"
      elements = {0 => 'N1', 1 => 'PE'}
      create_segment 'n1pe', elements
    end
  end

  def provider_adjustment
    Output835.log.info "Creating PLB segments"
    if @config_835[:configurable_segments][:plb_from_code]
      Output835.log.info "PLB from code"
      plb_class = find_class(@facility, @facility_class_type)
      adjustment_details = plb_class.new(@checks, @facility,@facility_config)
      if @client_name == 'AHN'
        is_plb_excel_sheet_applicable = true
      else
        is_plb_excel_sheet_applicable = nil
      end
      adjustment_details.provider_adjustment(@eobs, @facility, @payer, @check,
        is_plb_excel_sheet_applicable, @facility_config)#(@payee,@check,@claim)
    else
      Output835.log.info "PLB using config"
      plb_array = @config_835['plb_segment']['3'].to_s.split("@")
      # end
      plb03 = eval(@plb_config[plb_array[0]].to_s)
      plb03_1 = eval(@plb_config[plb_array[1]].to_s)
      if !plb03.blank? and !plb03_1.blank?
        plb03 =   plb03.to_s + @config_835["plb_separator"].to_s.strip + plb03_1.to_s
        elements = {0 => 'PLB', 3 => plb03}
      else
        elements = {0 => 'PLB'}
      end
      create_segment 'plb', elements
    end
  end

  def payee_additional_identification payee
    Output835.log.info "Creating REF TJ (paye_additional_identification) segments"
    if has_default_identification
      elements = {0 => 'REF'}
     reftj_seg = create_segment 'reftj', elements
    elsif  !payee.npi.blank?
      elements = {0 => 'REF'}
      reftj_seg = create_segment 'reftj', elements
    end
    unless reftj_seg.blank?
       return (reftj_seg.split("*")[2].blank?? nil : reftj_seg)
    else
      return nil
    end
  end

  def provider_number
    Output835.log.info "Creating REF PQ segments"
    elements = {0 => 'REF', 1 => 'PQ'}
    create_segment 'refpq', elements
  end

  def claim_loop
    segments = []
    @eobs.each_with_index do |eob, index|
      @check_grouper.last_eob = eob
      @eob = eob
      @claim = eob.claim_information
      @eob_index = index
      @services = eob.service_payment_eobs
      @is_claim_eob = (eob.category.upcase == "CLAIM")
      segments << transaction_set_line_number(index + 1)
      segments << provider_summary_info if index == 0
      segments += generate_eobs
    end
    segments.flatten.compact
  end


  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
    @provider_npi =  ((@claim && !@claim.provider_npi.blank?) ? @claim.provider_npi : @facility.facility_npi)
    #    if @facility.sitecode.strip == "00895"
    #      claim_period_start_date = @claim.blank? ? nil : @claim.claim_statement_period_start_date
    #      @service_date =  claim_period_start_date.blank? ? nil : claim_period_start_date.strftime("%Y%m%d")
    #    else
    #      service_date = @services.first.date_of_service_from.strftime("%Y%m%d") if @services.first.date_of_service_from
    #      @service_date = claim_level_eob? ? eob.claim_from_date.strftime("%Y%m%d") : service_date
    #    end
    claim_segments = [claim_payment_loop, include_claim_dates]
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
    claim_segments << claim_level_allowed_amount
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments <<  service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

  def unique_output_payid
    Output835.log.info "Creating REF 2U segments"
    elements = {0 => "REF", 1=>"2U"}
    if @config_835[:configurable_segments][:ref2u]
      ref2u_seg = create_segment 'ref2u', elements
      return (ref2u_seg.split("*")[2].blank?? nil : ref2u_seg)
    else
      return nil
    end
  end

  def include_claim_dates
    Output835.log.info "Claim level EOB: #{@is_claim_eob}"
    @is_claim_eob ? [claim_from_date, claim_to_date] : [statement_from_date, statement_to_date]
  end

  def claim_level_allowed_amount
    Output835.log.info "Facility config for claim_level allowed amount: #{@config_835[:claim_level_allowed_amt]}"
    claim_eob = false
    eob_total = 0
    eob_total_allowable = @eob.total_allowable
    if @is_claim_eob && eob_total_allowable.present? && @client_name == "QUADAX"
      claim_eob = true
      unless eob_total_allowable.to_f.zero?
      Output835.log.info "Creating AMT AU segments"
      eob_total = "%g" % @eob.total_allowable
       elements = {0 => "AMT", 1=>"AU",2=>eob_total}
      create_segment 'amtau', elements
      end
    elsif @config_835[:claim_level_allowed_amt] and claim_eob == false
      claim_payment_amt = @eob.payment_amount_for_output(@facility, @config_obj)
      Output835.log.info "Claim payment amount : #{claim_payment_amt}"
      unless claim_payment_amt.to_f.zero?
        claim_level_supplemental_amount = @eob.claim_level_supplemental_amount
        Output835.log.info "Claim level supplimental amount : #{claim_level_supplemental_amount}"
        unless claim_level_supplemental_amount.to_f.zero?
          Output835.log.info "Creating AMT AU segments"
          elements = {0 => "AMT", 1=>"AU"}
          create_segment 'amtau', elements
        end
      end
    end
  end


  def statement_to_date
  end

  def transaction_set_line_number(index)
    elements = {0 => 'LX'}
    @lx_index = index
    Output835.log.info "Creating LX segments"
    create_segment 'lx', elements
  end

  def transaction_set_trailer #(segment_count)
    elements = {0 => 'SE'}  #, 1 => segment_count.to_s}
    Output835.log.info "Creating SE segments"
    create_segment 'se', elements
  end

  def provider_summary_info
    Output835.log.info "Creating TS3 segments"
    elements =  {0 => 'TS3', 3 => "#{Date.today.year()}1231", 4 => @eobs.length.to_s,
      5 => total_submitted_charges.to_s.to_dollar, 6 => '', 7 => '', 8 => ''}
    create_segment 'ts3', elements
  end



  def claim_payment_loop
    claim_payment_segments = [claim_payment_information]  #, claim_interest_information ]
    @clp_pr_amount = nil
    service_eob = @services.detect{|service| service.adjustment_line_is? }
    if service_eob
      cas_segments, @clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(service_eob,
        @client, @facility, @payer, @element_seperator, @eob, @batch, @check)
      claim_payment_segments << cas_segments
    end
    if @is_claim_eob
      cas_segments, @clp_05_amount, crosswalked_codes = Output835.cas_adjustment_segments(@eob,
        @client, @facility, @payer, @element_seperator, @eob, @batch, @check )
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << patient_name
    unless @eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    claim_payment_segments << service_prov_name
    claim_payment_segments << service_prov_identifier
    if @is_claim_eob
      claim_payment_segments << Output835.claim_level_remark_code_segments(@eob, @element_seperator, crosswalked_codes)
    end
    # claim_payment_segments << image_page_name
    claim_payment_segments << medical_record_number
    claim_payment_segments << claim_uid
    claim_payment_segments << other_claim_related_id
    claim_payment_segments = claim_payment_segments.compact
  end

  def claim_uid
    Output835.log.info "Creating REF*BB segments"
    uid_number = @eob.uid
    Output835.log.info "UID for claim : #{uid_number}"
    if uid_number.present?
      elements =  {0 => 'REF', 1 =>'BB'}
      create_segment 'refbb', elements
    end
  end

  def claim_payment_information
    Output835.log.info "Creating CLP segments"
    elements =  {0 => 'CLP', 1 => @eob.patient_account_number, 4 => @eob.amount('total_amount_paid_for_claim').to_s,
      5 => (@eob.claim_type_weight == 22 ? "" : @eob.patient_responsibility_amount.to_s), 10 => '' }
    create_segment 'clp', elements
  end

  def claim_interest_information
    Output835.log.info "Creating CAS segments"
    unless (@eob.amount('claim_interest').to_f.zero?)
      elements = {0 => 'CAS', 3 => @eob.amount('claim_interest').to_s.to_dollar}
      create_segment 'cas', elements
    end
  end

  def patient_name
    Output835.log.info "Creating NM1 QC segments"
    elements =  {0 => 'NM1', 1 => 'QC', 2 => '1', 5 => @eob.patient_middle_initial.to_s.strip, 6 => ''}
    create_segment 'nm1qc', elements
  end

  def insured_name
    Output835.log.info "Creating NM1 IL segments"
    elements =  {0 => 'NM1', 1 => 'IL', 2 => '1', 3 => @eob.subscriber_last_name.to_s.strip,
      4 => @eob.subscriber_first_name.to_s, 5 => @eob.subscriber_middle_initial.to_s.strip,
      6 => '', 7 => @eob.subscriber_suffix.to_s.strip}
    create_segment 'nm1il', elements
  end

  def service_prov_identifier
    Output835.log.info "Config for re_pricer_info: #{@facility.details['re_pricer_info']} "
    Output835.log.info "alternate_payer_name: #{@check.alternate_payer_name}"
    if @facility.details['re_pricer_info'] && @check.alternate_payer_name.present?
      Output835.log.info "Creating NM1*PR*2 segments"
      ['NM1', 'PR', '2', @check.alternate_payer_name.to_s.strip].join(@element_seperator)
    end
  end
  def service_prov_name
    Output835.log.info "Creating NM1 82 segments"
    if @config_835[:configurable_segments][:nm182_from_code]
      Output835.log.info "NM1 82 from code"
      nm182_class = find_class(@facility, @facility_class_type)
      provider_details = nm182_class.new(@checks, @facility,@facility_config)
      provider_details.service_prov_name(@eob,@claim)
    else
      Output835.log.info "NM1 82 using config"
      elements = {0 => 'NM1', 1 => '82', 6 => '' }
      create_segment 'nm182', elements
    end
  end

  def medical_record_number
    Output835.log.info "Creating REF*EA segments"
    if @eob.medical_record_number.present? or  (@claim.present? && @claim.medical_record_number.present?)
      elements = {0 => 'REF', 1 => 'EA' }
      create_segment 'refea', elements
    end
  end

  def other_claim_related_id
    amount = nil
    Output835.log.info "Creating REF*F8(other claim_related_id) segments"
    if @config_835["configurable_segments"]["reff8"]
    amount = eval(@reff8_config[@config_835['reff8_segment']['2']]) if @config_835['reff8_segment']
    Output835.log.info "Amount in ref02 : #{amount}"
    end
    if !amount.blank?
      elements = {0 =>'REF'}
      create_segment 'reff8', elements
    end
  end

  def claim_from_date
    Output835.log.info "Claim from date: #{@eob.claim_from_date}"
    unless @eob.claim_from_date.blank?
      Output835.log.info "Creating DTM*232 segments"
      elements =   {0 => 'DTM', 1=> '232'} #unless @service_date.blank?
      create_segment 'dtm232', elements
    end
  end

  def statement_from_date
    if @claim && @claim.claim_statement_period_start_date
      Output835.log.info "Statement_from_date :#{@claim.claim_statement_period_start_date}"
      unless @claim.claim_statement_period_start_date.blank?
        Output835.log.info "Creating DTM*232 segments"
        elements =   {0 => 'DTM', 1=> '232'}
        create_segment 'dtm232', elements
      end
    end
  end

  def claim_to_date
    Output835.log.info "Claim_to_date : #{@eob.claim_to_date}"
    unless @eob.claim_to_date.blank?
      elements =   {0 => 'DTM', 1=> '233'}
      Output835.log.info "Creating DTM*233 segments"
      create_segment 'dtm233', elements
    end
  end

  def claim_supplemental_info
    check_amount = @check.check_amount.to_f
    interest = @eob.claim_interest.to_f
    unless (check_amount == interest)
      if @config_835["configurable_segments"]["amti"]
        amount = eval(@amti_config[@config_835['amti_segment']['2']]).to_f if @config_835['amti_segment']
        Output835.log.info "Amount in AMT*I :#{amount}"
      end
      if amount && !amount.zero?
        elements = {0 => 'AMT', 1 => 'I'}
        Output835.log.info "Creating AMT*I segments"
        create_segment 'amti', elements
      end
    end
  end

  def service_payment_info_loop
    segments = []
    @clp_05_amount = 0
    @services.each_with_index do |service, index|
      @service = service
      @paid_amount = 0
      @service_index = index
      @charge_amount = @service.amount('service_procedure_charge_amount')
      @paid_amount = @service.amount('service_paid_amount')
      service_segments = generate_services
      segments += service_segments[0]
      @clp_05_amount += service_segments[1]
    end
    segments
  end

  def generate_services

    is_adjustment_line = @service.adjustment_line_is?
    service_segments = []
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference
    unless is_adjustment_line
      cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, @element_seperator, @eob, @batch, @check)
      service_segments << cas_segments
    else
      pr_amount = 0.0
    end
    #    if !@charge_amount.zero? || !@paid_amount.zero?
    #      # service_segments << service_payment_information
    #      service_segments = [service_payment_information,service_date_reference]
    #    end
    #    cas_segments, pr_amount = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, '*')
    #    service_segments << cas_segments
    service_segments << provider_control_number unless is_adjustment_line
    service_segments << service_supplemental_amount
    #if !@charge_amount.zero? || !@paid_amount.zero?
    service_segments << standard_industry_code_segments(@service)
    # end
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

  def service_payment_information
    Output835.log.info "Creating SVC segments"
    if @config_835[:configurable_segments][:svc_from_code]
      Output835.log.info "SVC from code"
      svc_class = find_class(@facility, @facility_class_type)
      svc_info_details = svc_class.new(@checks, @facility,@facility_config)
      svc_info_details.service_payment_information(@eob,@service,@check,@is_claim_eob,@payer)
    else
      Output835.log.info "SVC using config"
      Output835.log.info "Charge amount: #{@charge_amount} "
      Output835.log.info "Paid amonut :#{@paid_amount}"
      if !@charge_amount.zero? || !@paid_amount.zero?
        @delimiter = @config_835['isa_segment']['16'] if @config_835['isa_segment']
        #      elements = {0 => 'SVC', 1 => composite_med_proc_id, 2 => @charge_amount.to_s,
        #        3 => @paid_amount.to_s, 4=>svc_revenue_code.to_s, 5=>@service.service_quantity.to_f.to_amount.to_s, 6=>svc_procedure_cpt_code.to_s }
        svc01 = []
        svc01_array=[]
        if !@config_835['svc_segment']['1'].blank?
          svc01_array = @config_835['svc_segment']['1'].to_s.split("@")
          svc01_array.each do |svc_element|
            svc01 << eval(@svc_config["#{svc_element}"])
          end
          svc01 = Output835.trim_segment(svc01)
          svc01 = svc01.join(':')
        else
          svc01 = nil
        end
        if !@config_835['svc_segment']['6'].blank?
          svc06 = []
          svc06_array=[]
          svc06_array = @config_835['svc_segment']['6'].to_s.split("@")
          svc06_array.each do |svc_element|
            svc06 << eval(@svc_config["#{svc_element}"])
          end
          svc06 = Output835.trim_segment(svc06)
          svc06 = svc06.join(':')
          elements = {0 => 'SVC',1=>svc01,6=>svc06}

        else
          elements = {0 => 'SVC',1=>svc01}
        end
        create_segment 'svc', elements
      end
    end
  end

  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    @from_date,@to_date = nil,nil
    @from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    @to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (@from_date == @to_date)
    Output835.log.info "Date_of_service_from : #{@from_date}"
    Output835.log.info "Date_of_service_to : #{@to_date}"
    if @from_date && (@to_date.nil? || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      Output835.log.info "Condition satisfied for DTM*472"
      service_date_elements = dtm_472
      service_date_elements unless @from_date.blank?
    else
      if @from_date
        Output835.log.info "Condition satisfied for DTM*150"
        svc_date_segments << dtm_150
      end
      if @to_date
        Output835.log.info "Condition satisfied for DTM*151"
        svc_date_segments << dtm_151
      end
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end

  def dtm_472
    Output835.log.info "Creating DTM*472 segments"
    elements = {0 => 'DTM', 1 => '472' }
    create_segment 'dtm472', elements
  end

  def dtm_150
    Output835.log.info "Creating DTM*150 segments"
    elements = {0 => 'DTM', 1 => '150'}
    create_segment 'dtm150', elements
  end

  def dtm_151
    Output835.log.info "Creating DTM*151 segments"
    elements = {0 => 'DTM', 1 => '151'}
    create_segment 'dtm151', elements
  end

  def provider_control_number
    Output835.log.info "Inside provider control number"
    Output835.log.info "Service_provider_control_number: #{@service.service_provider_control_number}"
    Output835.log.info "Xpediator_documnet_number : #{@claim.xpeditor_document_number}" if @claim
    if((!@service.service_provider_control_number.blank?) ||
          (@claim && !@claim.xpeditor_document_number.blank?))
      elements = {0 => 'REF', 1 => '6R'}
      Output835.log.info "Creating REF*6R segments"
      create_segment 'ref6r', elements
    end
  end

  def service_supplemental_amount
    amount = 0
    Output835.log.info "Inside service supplemental amount"
    if @config_835["configurable_segments"]["amtb6"]
    amount = eval(@amtb6_config[@config_835['amtb6_segment']['2']]).to_f if @config_835['amtb6_segment']
    Output835.log.info "Amount in AMT*B6: #{amount}"
    end
    unless amount.zero?
      elements = amtb6_elements
      Output835.log.info "Creating AMT*B6 segments"
      create_segment 'amtb6', elements
    end
  end

  def provider_adjustment_old
    interest_eobs = @eobs.clone
    interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}

    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (!interest_eobs.empty? && !@facility.details[:interest_in_service_line] )
    @eob = @eobs.first
    code, qual = service_payee_identification
    @plb_code,@plb_qual = code,qual
    job = @check.job
    provider_adjustments = job.provider_adjustments
    plb_array = []
    if !provider_adjustments.empty? || interest_exists_and_should_be_printed
      provider_adjustment_groups = provider_adjustments.group_by{|prov_adj| "#{prov_adj.qualifier}_#{prov_adj.patient_account_number}"}
      provider_adjustment_groups.each do |key, prov_adj_grp|
        @plb_03_1 = prov_adj_grp.first.qualifier.to_s.strip
        if !prov_adj_grp.first.patient_account_number.blank?
          # plb_03 += plb_separator.to_s.strip + prov_adj_grp.first.patient_account_number.to_s.strip
          @plb_03_2 = prov_adj_grp.first.patient_account_number.to_s.strip
          @plb_adjustment_amount = prov_adj_grp.first.amount
        else
          @plb_adjustment_amount = 0
          prov_adj_grp.each do |prov_adj|
            @plb_adjustment_amount = @plb_adjustment_amount.to_f + prov_adj.amount.to_f
          end
        end
      end
      plb_array = @config_835['plb_segment']['3'].to_s.split("@")
      # end
      plb03 = eval(@plb_config[plb_array[0]].to_s)
      plb03_1 = eval(@plb_config[plb_array[1]].to_s)
      if !plb03.blank? and !plb03_1.blank?
        plb03 =   plb03.to_s + @config_835["plb_separator"].to_s.strip + plb03_1.to_s
        elements = {0 => 'PLB', 3 => plb03}
      else
        elements = {0 => 'PLB'}
      end
      create_segment 'plb', elements
    end

  end


  def find_class facility, class_type
    class_name(facility.name.to_file, class_type) || class_name(facility.client.name.to_file, class_type) || "Output835::Template".constantize
  end

  def class_name type, class_type
    type = type.camelize
    if class_type == "single"
      "Output835::#{type}SingleStTemplate".constantize || "Output835::SingleStTemplate".constantize  rescue nil
    else
      "Output835::#{type}Template".constantize  rescue nil
    end
  end

end















