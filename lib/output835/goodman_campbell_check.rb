class Output835::GoodmanCampbellCheck < Output835::Check

  def initialize(facility, element_seperator, nextgen)
    @facility = facility
    @index = index
    @element_seperator = element_seperator
    @facility_config = facility.facility_output_configs.first
    @flag = 0  #for identify if any of the billing provider details is missing
    @nextgen = nextgen
    @client = @facility.client
  end

  def init_check_info(check)
    @check = check
    @eob_type = check.eob_type
    job = check.job
    unless job.payer_group == 'PatPay'
      @eobs = (@nextgen ? check.nextgen_eobs_for_goodman : check.old_eobs_for_goodman)
    else
      @eobs = check.insurance_payment_eobs
    end
    # Circumventing using Check <-> Payer association because of the existing
    # bug in MICR module where it does not update payer_id in check
    # after identifying the payer for a check, while loading grid
    if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end
    @check_amount = check_amount
    @facility_output_config = facility.output_config(job.payer_group)
  end

  def claim_loop
    segments = []
    Output835.log.info "\n\nCheck has #{@eobs.length} eobs"
    @eobs.each_with_index do |eob, index|
      segments << transaction_set_line_number(index + 1)
      segments << provider_summary_info_bac if index == 0
      segments << transaction_statistics([eob])
      eob_klass = Output835.class_for("Eob", facility)
      eob_obj = eob_klass.new(eob, facility, payer, index, @element_seperator) if eob
      Output835.log.info "Applying class #{eob_klass}" if index == 0
      segments += eob_obj.generate
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end

  def provider_adjustment
    if (check.insurance_payment_eobs.length == @eobs.length) || @nextgen
      eob_klass = Output835.class_for("Eob", facility)
      eob_obj = eob_klass.new(@eobs.first, facility, payer, 1, @element_seperator) if @eobs.first

    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.clone
    interest_eobs =  interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)

    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    code, qual = eob_obj.service_payee_identification
    provider_adjustments = get_provider_adjustment
    provider_adjustment_groups = provider_adjustment_grouping(provider_adjustments)
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = facility.client.group_code.to_s.strip
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << code
      provider_adjustment_elements << year_end_date
      plb_separator = facility_output_config.details["plb_separator"]
      provider_adjustment_groups.each do |key, prov_adj_grp|
        plb_03 = prov_adj_grp.first.qualifier.to_s.strip
        if !prov_adj_grp.first.patient_account_number.blank?
          plb_03 += plb_separator.to_s.strip + prov_adj_grp.first.patient_account_number.to_s.strip
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
      if interest_eobs && interest_eobs.length > 0 && !facility.details[:interest_in_service_line] &&
          facility_output_config.details[:interest_amount] == "Interest in PLB"
        interest_eobs.each do |eob|
          plb05 = 'L6:'+ eob.patient_account_number
          plb05 = 'L6' if facility_group_code == 'ADC'
          provider_adjustment_elements << plb05
          provider_adjustment_elements << (eob.amount('claim_interest') * -1).to_s.to_dollar
        end
      end
      provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
      provider_adjustment_elements.join(@element_seperator) unless provider_adjustment_elements.empty?
    end
    end
  end

  def facility_type_code
    @eobs.first.facility_type_code || '13'
  rescue
    '13'
  end

  def get_facility
    claim = (@eobs.collect {|eob| (eob.claim_information unless eob.claim_information.nil?)}).first

    if claim
      Output835.log.info "\n There's a claim associated with an eob, the claim id : #{claim.id},
     patient account num : #{claim.patient_account_number}"
      (claim.facility = facility)
    end
    claim || facility
  end

  def check_amount
    exact_eobs = check.insurance_payment_eobs
    amount = (exact_eobs.length > @eobs.length ? computed_check_amount : check.check_amount.to_f)
    amount = (amount == (amount.truncate)? amount.truncate : amount.to_s.to_dollar)
  end

  def computed_check_amount
    paid_amount =  @eobs.collect{ |c| c.total_amount_paid_for_claim.to_f}.sum
    interest = @eobs.collect{|c| c.claim_interest.to_f}.sum
    provider_adjustment = (@nextgen ? check.provider_adjustment_amount : 0)
    paid_amount + interest + provider_adjustment
  end

end