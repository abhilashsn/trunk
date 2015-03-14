class Output835::QuadaxTemplate < Output835::Template

  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
   # claim_segments = [claim_payment_loop, claim_allowed_amount, include_claim_dates]
   claim_segments = [claim_payment_loop, include_claim_dates]
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
    claim_segments << claim_level_allowed_amount 
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments <<  service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

   def claim_level_allowed_amount
     claim_eob = false
     eob_total_allowable = @eob.total_allowable
     if @is_claim_eob && eob_total_allowable.present?
       claim_eob = true
       unless eob_total_allowable.to_f.zero?
         return ['AMT', 'AU', "%g" % @eob.total_allowable].join(@element_seperator)
       end
     elsif @facility_output_config.details[:claim_level_allowed_amt] &&  claim_eob == false
      claim_payment_amt = @eob.payment_amount_for_output(@facility, @facility_output_config)
      unless claim_payment_amt.to_f.zero?
        claim_level_supplemental_amount = @eob.claim_level_supplemental_amount
        unless claim_level_supplemental_amount.to_f.zero?
        return  ["AMT", "AU", claim_level_supplemental_amount].join(@element_seperator)
        end
      end
    end
    end
  

#  def claim_allowed_amount
#    if @is_claim_eob && @eob.total_allowable.present?
#      return ['AMT', 'AU', "%g" % @eob.total_allowable].join(@element_seperator)
#    end
#  end



  def transaction_set_line_number(index)
    ['LX', index.to_s].join(@element_seperator)
  end


  def provider_adjustment(eobs = nil,facility = nil,payer=nil,check = nil,plb_excel_sheet = nil,facility_output_config =nil,xml_flag= nil)
    @eobs = @eobs.nil?? eobs : @eobs
    @facility = @facility.nil?? facility : @facility
    @payer = @payer.nil?? payer : @payer
    @check = @check.nil?? check : @check
    @plb_excel_sheet = @plb_excel_sheet.nil?? plb_excel_sheet : @plb_excel_sheet
    @facility_output_config = @facility_output_config.nil?? facility_output_config : @facility_output_config
    eob_klass = Output835.class_for("Eob", @facility)
    eob_obj = eob_klass.new(@eobs.first, @facility, @payer, 1, @element_seperator)

    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
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
    provider_adjustment_group_keys = provider_adjustment_groups.keys
    provider_adjustment_group_values = provider_adjustment_groups.values
    start_index = 0
    array_length = 6
    provider_adjustment_to_print = []
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = @client.group_code.to_s.strip
      provider_adjustment_group_length = provider_adjustment_group_keys.length
      remaining_provider_adjustment_group = provider_adjustment_group_length % array_length
      total_number_of_plb_seg = (remaining_provider_adjustment_group == 0)?
        (provider_adjustment_group_length / array_length):
        ((provider_adjustment_group_length / array_length) + 1)
      plb_seg_number = 0
      provider_adjustment_final = []

      while(plb_seg_number < total_number_of_plb_seg)
        provider_adjustment_groups_new = provider_adjustment_group_values[start_index,array_length]
        unless provider_adjustment_groups_new.blank?
          plb_seg_number += 1
          start_index = array_length * plb_seg_number
          provider_adjustment_elements = []
          provider_adjustment_elements << 'PLB'
          provider_adjustment_elements << (['AVITA HEALTH SYSTEMS','METROHEALTH SYSTEM' ].include?(@facility_name) ?  identify_service_payee : code)
          provider_adjustment_elements << "#{Date.today.year()}1231"
          plb_separator = @facility_output_config.details["plb_separator"]
          provider_adjustment_groups_new.each do |prov_adj_grp|
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
            provider_adjustment_elements << (format_amount(adjustment_amount) * -1)
          end
          provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
          provider_adjustment_final << provider_adjustment_elements
        end
      end
      
      interest_eob_length = interest_eobs.length
      if provider_adjustment_final && interest_eobs && interest_eob_length > 0 && !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        last_provider_adjsutment_segment = provider_adjustment_final.last
        if last_provider_adjsutment_segment
          length_of_elements = last_provider_adjsutment_segment.length
          if length_of_elements < 15
            segment_elements = last_provider_adjsutment_segment[3, length_of_elements]
            more_segment_elements_to_add = 6 - (segment_elements.length / 2) if segment_elements
          elsif length_of_elements % array_length == 3
            create_new_plb_segment = true
            more_segment_elements_to_add = 0
          end
        end
        if more_segment_elements_to_add && more_segment_elements_to_add > 0
          interest_eobs_to_be_added_in_last_incomplete_plb_segemnt = interest_eobs[0, more_segment_elements_to_add]
          if interest_eobs_to_be_added_in_last_incomplete_plb_segemnt
            interest_eobs_to_be_added_in_last_incomplete_plb_segemnt.each do |eob|
              if eob
                adjustment_identifier = 'L6:'+ captured_or_blank_patient_account_number(eob.patient_account_number)
                adjustment_identifier = 'L6' if facility_group_code == 'ADC'
                last_provider_adjsutment_segment << adjustment_identifier
                last_provider_adjsutment_segment << (eob.amount('claim_interest') * -1)
              end
            end
          end
        end
      end

      provider_adjustment_final.each do |prov_adj_final|
        prov_adj_final_string = prov_adj_final.join(@element_seperator)
        provider_adjustment_to_print << prov_adj_final_string
      end
      
      if interest_eobs && interest_eob_length > 0 && ((more_segment_elements_to_add && more_segment_elements_to_add > 0) || create_new_plb_segment ) &&
        !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        remaining_interest_eobs = interest_eobs[more_segment_elements_to_add, interest_eob_length]
        if remaining_interest_eobs && remaining_interest_eobs.length > 0
          provider_adjustment_to_print << plb_segment_with_interest_amount(remaining_interest_eobs,
            code, array_length, provider_adjustment_to_print)
        end
      end
    end

    if provider_adjustment_to_print.empty? && interest_exists_and_should_be_printed && interest_eobs &&
        @facility_output_config.details[:interest_amount] == "Interest in PLB"
      plb_segment_with_interest_amount(interest_eobs, code, array_length, provider_adjustment_to_print)
    end
    provider_adjustment_to_print
  end

  def plb_segment_with_interest_amount(interest_eobs, code, array_length, provider_adjustment_to_print)
    provider_adjustment_header = ['PLB',code,"#{Date.today.year()}1231"]
    interest_eobs.each_slice(array_length) do |eobs_with_interest|
      provider_adjustment_elements = []
      provider_adjustment_elements << provider_adjustment_header
      eobs_with_interest.each do |interest_eob|
        if interest_eob
          provider_adjustment_elements << 'L6:'+ captured_or_blank_patient_account_number(interest_eob.patient_account_number)
          provider_adjustment_elements << (interest_eob.amount('claim_interest') * -1)
        end
      end
      provider_adjustment_elements = provider_adjustment_elements.flatten
      provider_adjustment_to_print << provider_adjustment_elements.join(@element_seperator)
    end
  end

  def claim_supplemental_info
    check_amount = @check.check_amount.to_f
    interest = @eob.claim_interest.to_f
    total_balance = @eob.total_service_balance.to_f
    unless interest.zero?
      unless (check_amount == interest) # segment is not needed for interest only checks
        ["AMT", "I", @eob.amount('claim_interest')].join(@element_seperator)
      end
    end
  end

  def patient_name
    member_id, qualifier = @eob.member_id_and_qualifier
    patient_name_elements = ['NM1', 'QC', '1', captured_or_blank_patient_last_name(@eob.patient_last_name),
      captured_or_blank_patient_first_name(@eob.patient_first_name), @eob.patient_middle_initial,'', @eob.patient_suffix,
      qualifier, member_id]
    patient_name_elements = Output835.trim_segment(patient_name_elements)
    return nil if patient_name_elements == [ 'NM1', 'QC', '1']
    patient_name_elements.join(@element_seperator)
  end

  # For Quadax if there is Remark code MA07 or MA18 or N89 or N367 available in an EOB,
  #  then we need to set the claim type 19 in the output module only.
  #  (if LQ*HE is cheked with ANSI)
  def claim_type_weight
    is_industry_code_configured = @facility.industry_code_configured?
    remark_codes = []
    rcc = ReasonCodeCrosswalk.new(@payer, nil, @client, @facility)
    if @is_claim_eob
      crosswalked_codes = rcc.get_all_codes_for_entity(@eob, true)
      remark_codes << crosswalked_codes[:remark_codes]
    else
      unless @services.empty?
        @services.each do |svc_line|
          crosswalked_codes = rcc.get_all_codes_for_entity(svc_line, true)
          remark_codes << crosswalked_codes[:remark_codes]
          remark_codes << svc_line.get_remark_codes
        end
      end
    end
    remark_codes = remark_codes.flatten.compact.uniq
    condition_to_print_claim_type_19 = is_industry_code_configured && !remark_codes.blank? &&
      @eob.check_validity_of_ansi_code(remark_codes)
    if condition_to_print_claim_type_19
      '19'
    else
      @eob.claim_type_weight
    end
  end

  def claim_from_date
    from_date = @eob.claim_from_date
    unless from_date.blank?
      from_date = from_date.strftime("%Y%m%d")
      from_date = '99999999' if (from_date == '20000101' || from_date == '99990909')
      can_print_date = (from_date == '99999999') ? true : can_print_service_date(from_date)
      ['DTM', '232', from_date].join(@element_seperator) if can_print_date
    end
  end

  def claim_to_date
    to_date = @eob.claim_to_date
    unless to_date.blank?
      to_date = to_date.strftime("%Y%m%d")
      to_date = '99999999' if (to_date == '20000101' || to_date == '99990909')
      can_print_date = (to_date == '99999999') ? true : can_print_service_date(to_date)
      ['DTM', '233', to_date].join(@element_seperator) if can_print_date
    end
  end

  def claim_payment_information
    claim_weight = claim_type_weight
    total_charge, total_payment = total_charge_and_payment
    if @facility_name == 'AVITA HEALTH SYSTEMS' && @check.job.payer_group == 'PatPay'
      clp_07 = "RM"
    else
      clp_07 = @eob.claim_number
    end
    clp_elements = ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, total_charge,
      total_payment, ( claim_weight== 22 ? "" : @eob.patient_responsibility_amount.to_amount),
      plan_type,clp_07, eob_facility_type_code, claim_freq_indicator, nil,
      (@eob.drg_code unless @eob.drg_code.blank?)]
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
    unless @clp_pr_amount.blank?
      @clp_05_amount += @clp_pr_amount
    end
    clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? @clp_05_amount.to_f.to_amount_for_clp : "")
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end

  #The DTM segment in the SVC loop is to be used to express dates and date
  #ranges specifically related to the service identified in the SVC segment
  # If service from and to dates are same, only print one segment with qual 472
  # Else print one segment each for the two dates
  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (from_date == to_date)
    if !from_date.nil? && (to_date.nil? || from_eqls_to_date)
      if from_date == '20000101' || from_date == '99990909'
        from_date = '99999999'
      end
      can_print_date = (from_date == '99999999') ? true : can_print_service_date(from_date)
      if can_print_date
        service_date_elements << 'DTM'
        service_date_elements << '472'
        service_date_elements << from_date
        service_date_elements.join(@element_seperator)
      end
    else
      if can_print_service_date(from_date)
        service_date_elements << 'DTM'
        service_date_elements << '150'
        service_date_elements << from_date
        svc_date_segments << service_date_elements.join(@element_seperator)
      end
      if can_print_service_date(to_date)
        service_date_elements = []
        service_date_elements << 'DTM'
        service_date_elements << '151'
        service_date_elements << to_date
        svc_date_segments << service_date_elements.join(@element_seperator)
      end
      svc_date_segments unless svc_date_segments.blank?
    end
  end

  def service_line_item_control_num
    xpeditor_document_number = @claim.xpeditor_document_number if @claim
    unless xpeditor_document_number.blank? || xpeditor_document_number == "0"
      service_index_number = (@service_index + 1).to_s.rjust(4 ,'0')
      ['REF', '6R', (xpeditor_document_number+service_index_number)].join(@element_seperator)
    end
  end

  def payee_identification(payee,check = nil,claim = nil,eobs = nil)
    @check =  @check.nil?? check : @check
    @claim = @claim.nil?? claim : @claim
    @eobs = @eobs.nil?? eobs : @eobs
    elements = []
    if has_default_identification
      elements = ['N1', 'PE']
      elements << facility_lockbox.payee_name.upcase
      elements << 'XX'
      elements << facility_lockbox.npi.strip.upcase
    else
      elements = ['N1', 'PE', payee_name(payee,@eobs)]
      if @check.payee_npi.present?
        elements << 'XX'
        elements << @check.payee_npi.strip.upcase
        #      elsif @claim && !@claim.npi.blank?
        #        elements << 'XX'
        #        elements << @claim.npi.strip.upcase
        #      elsif !payee.npi.blank?
        #        elements << 'XX'
        #        elements << payee.npi.strip.upcase
      elsif @check.payee_tin.present?
        elements << 'FI'
        elements << @check.payee_tin.strip.upcase
        #      elsif @claim && !@claim.tin.blank?
        #        elements << 'FI'
        #        elements << @claim.tin.strip.upcase
        #      elsif !payee.tin.blank?
        #        elements << 'FI'
        #        elements << payee.tin.strip.upcase
        #      elsif !@facility.tin.blank?
        #        elements << 'FI'
        #        elements << @facility.tin.strip.upcase
      end
    end
    elements.join(@element_seperator)
  end

  def service_prov_name(eob = nil,claim = nil)
    @eob =  @eob.nil?? eob : @eob
    @claim =  @claim.nil?? claim : @claim
    if has_default_identification
      elements = []
      elements = ['NM1', '82']
      if @eob.rendering_provider_last_name.to_s.blank? and @eob.rendering_provider_first_name.to_s.blank?
        elements << ['2', facility_lockbox.payee_name.upcase,'','','','']
      else
        elements << ['1', prov_last_name_or_org, @eob.rendering_provider_first_name, @eob.rendering_provider_middle_initial, '', @eob.rendering_provider_suffix]
      end
      elements << 'XX'
      @eob.provider_npi.present? ? elements << @eob.provider_npi : elements << facility_lockbox.npi.strip.upcase
      elements.flatten.trim_segment.join(@element_seperator)
    else
      prov_id, qualifier = service_prov_identification
      ['NM1', '82', (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
        prov_last_name_or_org, @eob.rendering_provider_first_name,
        @eob.rendering_provider_middle_initial, '', @eob.rendering_provider_suffix,
        qualifier, prov_id].trim_segment.join(@element_seperator)
    end
  end


  def payee_name payee,eobs
    facility_list = ["TATTNALL HOSPITAL COMPANY LLC","ORTHOPEDIC SURGEONS OF GEORGIA",
      "OPTIM HEALTHCARE","OPTIM HEALTHCARE-WF", "HOUSTON MEDICAL CENTER"]
    if facility_list.include?(@facility_name)
      eob_type = @check.eob_type
      lockbox_number = @batch.get_lockbox_number.to_s
      conditions = "facility_id = #{@facility.id} AND payer_type = '#{eob_type}'"
      conditions += " AND lockbox = '#{lockbox_number}'" if !lockbox_number.blank?

      facility_payees = FacilitySpecificPayee.where(conditions).order("weightage desc")
      if facility_payees
        payee_name = nil
        eob = eobs.first
        facility_payees.each do|facility_payee|
          identifier_position = eob.patient_account_number.upcase.index("#{facility_payee.db_identifier}")
          if (facility_payee.match_criteria.to_s == 'like' && identifier_position.present? && identifier_position >= 1 )
            @facility_payee = facility_payee
            break
          elsif (facility_payee.match_criteria.to_s == 'start_with' && identifier_position.present? && identifier_position == 0 )
            @facility_payee = facility_payee
            break
          elsif facility_payee.db_identifier == 'Other'
            @facility_payee = facility_payee
            break
          elsif 'all_numeric'
            if eob.patient_account_number.match(/^[0-9]*$/)
              @facility_payee = facility_payee
              break
            end
          end
        end
        @facility_payee.try(:payee_name).try(:upcase)
      end
    else
      if @check.payee_name?
      @check.payee_name.strip.upcase
    elsif @config_835[:payee_name].present?
      @config_835[:payee_name].strip.upcase
    else
      get_payee_name(payee)
    end
  #    (@config_835[:payee_name].present? ? @config_835[:payee_name].strip.upcase : payee.name.strip.upcase)
    end
  end

  def identify_service_payee
    if has_default_identification
      facility_lockbox_value = facility_lockbox.npi.presence || facility_lockbox.tin.presence
      return facility_lockbox_value.strip.upcase if facility_lockbox_value
    end
    service_payee = @check.payee_npi.presence || (@claim && @claim.npi.presence) || @facility.npi.presence || @check.payee_tin.presence || (@claim && @claim.tin.presence) || @facility.tin.presence
    service_payee.strip.upcase if service_payee
  end

  #supplies payment and control information to a provider for a particular service
  def service_payment_information(eob = nil,service = nil,check = nil,is_claim_eob = nil,payer = nil)
    @service =  @service.nil?? service : @service
    @eob =  @eob.nil?? eob : @eob
    @payer =  @payer.nil?? payer : @payer
    @check =  @check.nil?? check : @check
    @is_claim_eob =  @is_claim_eob.nil?? is_claim_eob : @is_claim_eob
    if !@is_claim_eob && is_discount_more?(@service.contractual_amount.to_f)
      ['SVC', composite_med_proc_id, @check.check_amount.to_f.to_amount, @check.check_amount.to_f.to_amount, svc_revenue_code,
        @service.service_quantity.to_f.to_amount, svc_procedure_cpt_code].trim_segment.join(@element_seperator )
    else
      super
    end
  end

  def total_charge_and_payment
    if is_discount_more?(@eob.total_contractual_amount.to_f)
      return @check.check_amount.to_f.to_amount, @check.check_amount.to_f.to_amount
    else
      return @eob.amount('total_submitted_charge_for_claim'), @eob.payment_amount_for_output(@facility, @facility_output_config)
    end
  end

  def is_discount_more?(discount)
    @facility_name == 'AVITA HEALTH SYSTEMS' && @eob.multiple_statement_applied == false &&
      @check.check_amount.to_f.round(2) < discount.to_f.round(2) && @payer.payer_type == 'PatPay'
  end

  def statement_to_date
    claim_from_date, claim_to_date = claim_start_date, claim_end_date
    formatted_claim_to_date = claim_to_date.strftime("%Y%m%d") if claim_to_date

    different_date = if claim_from_date && claim_to_date
      claim_from_date.strftime("%Y%m%d") != formatted_claim_to_date
    elsif claim_to_date
      true
    end
    
    if claim_to_date &&  can_print_service_date(formatted_claim_to_date) && different_date
      ['DTM', '233', formatted_claim_to_date].join(@element_seperator)
    end
  end

end