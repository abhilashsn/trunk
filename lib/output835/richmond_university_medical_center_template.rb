class Output835::RichmondUniversityMedicalCenterTemplate < Output835::Template

  def functional_group_header
    ['GS', 'HP', payer_id, strip_string(gs_03), @batch.date.strftime("%Y%m%d"), Time.now.strftime("%H%M"),
      '2831', 'X', ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].trim_segment.join(@element_seperator)
  end

  def payer_id
    payer = @first_check.payer
    payid = @facility.output_config(@first_check.job.payer_group).details[:isa_06]
    if payid == 'Predefined Payer ID'
      if @facility.index_file_parser_type == 'Barnabas'
        payer.output_payid(@facility) if payer
      else
        payer.supply_payid if payer
      end
    else
      payid.to_s
    end
  end

  def transactions
    segments = []
    @check_nums = @checks.collect{|check| check.check_number}
    @checks.each_with_index do |check, index|
      @check_grouper.last_check = check
      @check = check
      @check_index = index
      @batch = check.batch
      @job = check.job
      @flag = 0  #for identify if any of the billing provider details is missing
      @eob_type = @check.eob_type
      @eobs =  get_ordered_insurance_payment_eobs(@check)
      @micr = @check.micr_line_information
      if @micr && @micr.payer && @facility.details[:micr_line_info]
        @payer = @micr.payer
      else
        @payer = @check.payer
      end
      @check_amount = check_amount
      @facility_output_config = if @output_configs_hash.has_key?(@job.payer_group)
        @output_configs_hash[@job.payer_group]
      else
        @output_configs_hash['Insurance']
      end
      @is_correspndence_check = @check.correspondence?
      segments += generate_check
    end
    segments
  end

  # In TRN02 segment, usually check number comes. For RUMC, For Patpay it should be
  # "Check Number+Batch date". If check number duplicates add sequential number.
  #  For ex: "Check Number_1+Batch date"
  def reassociation_trace
    trn_elements = ['TRN', '1']
    check_num = "#{@check.check_number.to_i}"
    if @payer
      if @check.job.payer_group == "PatPay"
        # checking whether the check_number is duplicated
        # in the whole check number array
        if Output835.element_duplicates?(check_num, @check_nums)
          # get all indexes at which duplicate elements are present
          # then check at what position the current element resides
          # that gives the duplication index as one moves from first to last elem of the array
          # For Ex : array = [a, b, c, c, d, e, f, e, g]
          # all_indices for 'c' would return [2, 3]
          # comparing the current element's index with that, we would get either '0' or '1' depending on
          # whether we're dealing with 'c' in 2nd place or at 3rd place, couting starts from 0th place
          # all_indices for 'e' would return [5, 7]
          counter = Output835.all_indices(check_num, @check_nums).index(@check_index)
          # since counter starts from zero, adding 1 to get the correct count
        end
        add_date_to_check_num(check_num) unless check_num.blank?
        check_num << "#{counter+1}" if counter
      end
    end
    trn_elements << (check_num.blank? ? "0" : check_num)
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      unless @facility.facility_tin.blank?
        trn_elements <<  '1' + @facility.facility_tin
      end
    else
      trn_elements <<  '1999999999'
    end
    trn_elements.trim_segment.join(@element_seperator)
  end

  #adding date to check number
  def add_date_to_check_num(check_num)
    check_num << "#{@batch.date.strftime("%m%d%y")}"
  end

  # Adding health remark code segment for RUMC i.e. LQ*RX segment
  def generate_services
    is_adjustment_line = @service.adjustment_line_is?
    service_segments = []
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference
    unless is_adjustment_line
      cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, @element_seperator)
      service_segments << cas_segments
    else
      cas_segments, pr_amount = nil,0.0
    end
    service_segments << service_line_item_control_num
    service_segments << health_remark_code_segments
    service_segments << provider_control_number unless is_adjustment_line
    supp_amount = supplemental_amount
    service_segments << service_supplemental_amount(supp_amount) unless supp_amount.blank?
    service_segments << patpay_specific_lq_segment
    service_segments << standard_industry_code_segments(@service)
    [service_segments.compact.flatten, pr_amount]
  end

  # Computing Health Remark Code segments
  def health_remark_code_segments
    health_remark_code_segments = [compute_lq("in"), compute_lq("out")]
    if @facility.details[:interest_in_service_line] && @service.interest_service_line?
      health_remark_code_segments << lq_rx_segments("109975") if @eob.claim_interest.to_f > 0.0
    end
    health_remark_code_segments << lq_rx_segments("109702") if @eob.hcra.to_f > 0.0
    health_remark_code_segments.compact.flatten
  end

  # Computing LQ*RX segments according to the Patient Type(InPatient or OutPatient)
  def compute_lq(patient_type)
    segments = []
    patient_code = @service.send("#{patient_type}patient_code")
    facility_payer_information = FacilitiesPayersInformation.find_by_payer_id_and_facility_id(@payer.id, @facility.id) if @payer
    if facility_payer_information
      capitation_code = facility_payer_information.capitation_code
      if(patient_type == "in")
        allowance_code = facility_payer_information.in_patient_allowance_code
        payment_code = facility_payer_information.in_patient_payment_code
      else
        allowance_code = facility_payer_information.out_patient_allowance_code
        payment_code = facility_payer_information.out_patient_payment_code
      end

    end
    unless patient_code.blank?
      patient_code_array = patient_code.split(",")
      segments << (lq_rx_segments(allowance_code) if patient_code_array.include?("1") and !allowance_code.blank?)
      segments << (lq_rx_segments(capitation_code) if patient_code_array.include?("2") and !capitation_code.blank?)
    end
    serv_amt = @service.service_paid_amount.to_f
    pat_type = @eob.patient_type.downcase rescue nil

    if serv_amt > 0 and pat_type == "#{patient_type}patient"
      segments << (lq_rx_segments(payment_code) unless payment_code.blank?)
    end
    segments
  end

  # Returns one LQ*RX line for the corresponding code(allowance, capitation, payment etc.)
  def lq_rx_segments(code)
    [ 'LQ', 'RX', code.to_s.strip].trim_segment.join(@element_seperator)
  end

  def patpay_specific_lq_segment
    [ "LQ", "RX", "202614"].join(@element_seperator) if @check.eob_type == 'Patient'
  end

   
end
