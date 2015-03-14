class Output835::ConfigSingleStTemplate < Output835::ConfigTemplate

  include Output835ConfigSingleStHelper
 
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

  def transactions
    segments = []
    @check = @checks.first
    @check_grouper.last_check = @check
    @eob_type = @check.eob_type
    if @eob_type == "Insurance"
      @config_835 = @insurance_config_details
    else
      @config_835 = @patpay_config_details
    end
    @eobs =  @checks.collect(&:insurance_payment_eobs).flatten
    @micr = @check.micr_line_information
    @check_amount = check_total_amount
    if @micr && @micr.payer && @facility.details[:micr_line_info]
      @payer = @micr.payer
    else
      @payer = @check.payer
    end
    @facility_output_config = @facility.output_config(@payer.payer_type)
    @is_correspndence_check = @check.correspondence?
    segments += generate_check
    segments
  end

  def functional_group_trailer
    ['GE', '0001', '2831'].join(@element_seperator)
  end

  def generate_check
    @eob_type = @check.eob_type
    @payer_tin = (@payer && @payer.payer_tin) ? '1' + @payer.payer_tin : '1' + @facility.facility_tin
    @payerid =  @payer.payer_identifier(@micr)
    @default_payer_address = @payer.default_payer_address(@facility, @check)
    @svc_procedure_cpt_code = true
    @composite_med_proc_id = true
    @is_correspndence_check = correspondence_check?
    transaction_segments = [ transaction_set_header, financial_info, reassociation_trace]
    transaction_segments << date_time_reference
    transaction_segments << payer_identification_loop
    transaction_segments << payee_identification_loop
    transaction_segments << claim_loop
    transaction_segments << provider_adjustment
    transaction_segments = transaction_segments.flatten.compact
    @transaction_count = transaction_segments.length + 1
    transaction_segments << transaction_set_trailer
  end

  def transaction_set_header
    ['ST', '835', '0001'].join(@element_seperator)
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
      segments += generate_eobs
    end
    segments.flatten.compact
  end

  def provider_adjustment
    interest_eobs = @eobs.clone
    interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}

    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (!interest_eobs.empty? && !@facility.details[:interest_in_service_line] )
    @eob = @eobs.first
    write_provider_adjustment_excel  if @plb_excel_sheet
    code, qual = service_payee_identification
    @plb_code,@plb_qual = code,qual
    provider_adjustments = get_provider_adjustment
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

  def write_provider_adjustment_excel
    @excel_index = @plb_excel_sheet.last_row_index + 1
    @whole_checks.each do |check|
      job = check.job
      provider_adjustments = job.get_all_provider_adjustments
      provider_adjustments.each do |prov_adj|
        current_job = prov_adj.job
        current_job = Job.find(current_job.parent_job_id) if current_job.parent_job_id
        excel_row = [current_job.batch.date.strftime("%m/%d/%Y"), current_job.batch.batchid, current_job.check_number, prov_adj.qualifier,
          prov_adj.patient_account_number, format_amount(prov_adj.amount).to_s.to_dollar
        ]
        @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
        @excel_index += 1
      end
    end
  end


  def financial_info
    Output835.log.info "Creating BPR segments"
    check_amount = check_total_amount_truncate
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


  def get_provider_adjustment
    ids_of_all_jobs = []
    @checks.each do |check|
      job = check.job
      ids_of_all_jobs += job.get_ids_of_all_child_jobs if job.eob_count == 0
      ids_of_all_jobs << job.id
    end
    conditions = "provider_adjustments.job_id IN (#{ids_of_all_jobs.uniq.join(',')})"
    provider_adjustments = ProviderAdjustment.find(:all, :conditions => conditions)
    provider_adjustments.flatten.compact
  end

  def transaction_set_trailer
    ['SE', @transaction_count, '0001'].join(@element_seperator)
  end

  def check_total_amount
    @checks.inject(0) {|sum, c| sum = sum + c.check_amount.to_f}.to_s.to_dollar
  end

  def get_micr_condition
    @facility.details[:micr_line_info] && @facility_output_config.grouping == 'By Payer'
  end

  def payer_id
    payer = @first_check.payer
    payer_type = payer.payer_type if payer
    output_config = @facility.output_config(payer_type)
    @payid = case output_config.grouping
    when 'By Check'
      @first_check.supply_payid if @first_check
    when 'By Payer','By Payer Id'
      payer_wise_payer_id(output_config)
    when 'By Batch', 'By Batch Date', 'By Cut'
      generic_payer_id(output_config)
    end
  end

  def generic_payer_id(output_config)
    case output_config.eob_type
    when 'Insurance EOB'
      if @facility.commercial_payerid
        @facility.commercial_payerid
      else
        raise "Commercial Payer ID must be configured to generate Single ST 835 for Insurance EOBs"
      end
    when 'Patient Payment'
      if @facility.patient_payerid
        @facility.patient_payerid
      else
        raise "Patient Payer ID must be configured to generate Single ST 835 for Patient EOBs"
      end
    end
  end

  def payer_wise_payer_id(output_config)
    case output_config.eob_type
    when 'Insurance EOB'
      @payer.supply_payid if @payer
    when 'Patient Payment'
      if @facility.patient_payerid
        @facility.patient_payerid
      else
        raise "Patient Payer ID must be configured to generate Single ST 835 for Patient EOBs"
      end
    end
  end

end