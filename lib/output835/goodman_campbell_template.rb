class Output835::GoodmanCampbellTemplate < Output835::Template

  def functional_group_header
    payid = payer_id
    gs_elements = ['GS', 'HP', ((!@nextgen || (!@output_version || @output_version == '4010')) ? 'REVMED' : payid.to_s)]
    if @config_835[:payee_name].present?
      gs_03 = (@config_835[:payee_name]).strip.justify(14, 'X')
    else
      gs_03 = payid.to_s.justify(14, 'X')
    end
    gs_elements << [((!@nextgen || (!@output_version || @output_version == '4010')) ? strip_string(gs_03) : strip_string('INDIANAPOLIS NE')),
        Time.now().strftime("%Y%m%d"), Time.now().strftime("%H%M"), '2831', 'X',
        ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
    gs_elements.join(@element_seperator)
  end

  def payer_id
    payid = @config_835[:isa_06]
    if payid == 'Predefined Payer ID'
      payer = @first_check.payer
      job =  @first_check.job
      if payer && job.payer_group == 'PatPay'
        'P9998'
      elsif payer
        (@nextgen ? payer.gcbs_output_payid(@facility): payer.output_payid(@facility))
      end
    else
      payid.to_s
    end
  end

  # Starts and identifies an interchange of zero or more
  # functional groups and interchange-related control segments
  def interchange_control_header
    isa_elements = ['ISA', '00', ( ' ' * 10), '00', ( ' ' * 10), 'ZZ', payer_id.to_s.justify(15), 'ZZ']
    isa_08 = (@config_835[:payee_name].present? ? @config_835[:payee_name].upcase.justify(15) : @facility_name.justify(15))
    isa_elements << ((!@nextgen || (!@output_version || @output_version == '4010')) ? isa_08 : 'INDIANAPOLIS NE')
    isa_elements << [Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),((!@output_version || @output_version == '4010') ? 'U' : '^'),
        ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
        (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record), '0', 'P', ':']
    isa_elements.join(@element_seperator)
  end

  def transactions
    segments = []
    @checks.each_with_index do |check, index|
      @check_grouper.last_check = check
      @check = check
      @check_index = index
      @batch = check.batch
      job = @check.job
      @flag = 0  #for identify if any of the billing provider details is missing
      @eob_type = @check.eob_type
      @check_eobs = get_ordered_insurance_payment_eobs(@check)
      unless job.payer_group == 'PatPay'
        @eobs = (@nextgen ? @check.nextgen_eobs_for_goodman : @check.old_eobs_for_goodman)
      else
        @eobs = @check_eobs
      end
      @micr = @check.micr_line_information
      if @micr && @micr.payer && @facility.details[:micr_line_info]
        @payer = @micr.payer
      else
       @payer = @check.payer
      end
      @check_amount = check_amount
      @facility_output_config = @facility.output_config(job.payer_group)
      @is_correspndence_check = @check.correspondence?
      segments += generate_check
    end
    segments
  end

  def provider_adjustment_old(eobs = nil,facility = nil,payer=nil,check = nil,plb_excel_sheet = nil,facility_output_config = nil)
    @eobs = @eobs.nil?? eobs : @eobs
    @facility = @facility.nil?? facility : @facility
    @payer = @payer.nil?? payer : @payer
    @check = @check.nil?? check : @check
    @plb_excel_sheet = @plb_excel_sheet.nil?? plb_excel_sheet : @plb_excel_sheet
     @facility_output_config = @facility_output_config.nil?? facility_output_config : @facility_output_config
    @check_eobs = @check.insurance_payment_eobs
    if (@check_eobs.length == @eobs.length) || @nextgen
      eob_klass = Output835.class_for("Eob", @facility)
      eob_obj = eob_klass.new(@eobs.first, @facility, @payer, 1, @element_seperator) if @eobs.first

    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.clone
    interest_eobs =  interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (@facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)

    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    code, qual = eob_obj.service_payee_identification
    provider_adjustments = @check.job.get_all_provider_adjustments
    provider_adjustment_groups = provider_adjustment_grouping(provider_adjustments)
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = @client.group_code.to_s.strip
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << code
      provider_adjustment_elements << "#{Date.today.year()}1231"
      plb_separator = @facility_output_config.details["plb_separator"]
      provider_adjustment_groups.each do |key, prov_adj_grp|
        plb_03 = prov_adj_grp.first.qualifier.to_s.strip
        if !prov_adj_grp.first.patient_account_number.blank?
          plb_03 += plb_separator.to_s.strip + captured_or_blank_patient_account_number(prov_adj_grp.first.patient_account_number)
          adjustment_amount = prov_adj_grp.first.amount
        else
          adjustment_amount = 0
          prov_adj_grp.each do |prov_adj|
            adjustment_amount = adjustment_amount.to_f + prov_adj.amount.to_f
          end
        end
        plb_03 = 'WO' if facility_group_code == 'ADC'
        provider_adjustment_elements << plb_03
        provider_adjustment_elements << (format_amount(adjustment_amount) * -1).to_s.to_dollar
      end
      if interest_eobs && interest_eobs.length > 0 && !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        interest_eobs.each do |eob|
          plb05 = 'L6:'+ captured_or_blank_patient_account_number(eob.patient_account_number)
          plb05 = 'L6' if facility_group_code == 'ADC'
          provider_adjustment_elements << plb05
          provider_adjustment_elements << (eob.amount('claim_interest') * -1).to_s.to_dollar
        end
      end
      provider_adjustment_elements = provider_adjustment_elements.trim_segment.join(@element_seperator) unless provider_adjustment_elements.empty?
    end
    end
  end

  def facility_type_code
    @eobs.first.facility_type_code || '13'
  rescue
    '13'
  end

  def check_amount
    exact_eobs = @check_eobs
    amount = (exact_eobs.length > @eobs.length ? computed_check_amount : @check.check_amount.to_f)
    amount = (amount == (amount.truncate)? amount.truncate : amount.to_s.to_dollar)
  end

  def computed_check_amount
    paid_amount =  @eobs.collect{ |c| c.total_amount_paid_for_claim.to_f}.sum
    interest = @eobs.collect{|c| c.claim_interest.to_f}.sum
    provider_adjustment = (@nextgen ? @check.provider_adjustment_amount : 0)
    paid_amount + interest + provider_adjustment
  end

  
end
