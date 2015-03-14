
class Unified835Output::QuadaxGenerator < Unified835Output::Generator

 
  # Start of AMT AU Segment Details #
  def coverage_amount(*options)
    claim_eob = false
    eob_total_allowable = @eob.total_allowable
    if @classified_eob.is_claim_eob? && eob_total_allowable.present?
      claim_eob = true
      return eob_total_allowable_amount(eob_total_allowable)
    elsif @output_config.details[:claim_level_allowed_amt] &&  claim_eob == false
      claim_payment_amt = @eob.payment_amount_for_output(@facility, @output_config)
      return claim_level_amount(claim_payment_amt )
    end
  end
  
  def claim_level_amount(claim_payment_amt)
    unless claim_payment_amt.to_f.zero?
      claim_level_supplemental_amount = @eob.claim_level_supplemental_amount
      return  claim_level_supplemental_amount if !claim_level_supplemental_amount.to_f.zero?
    end
  end

  def eob_total_allowable_amount(eob_total_allowable)
    unless eob_total_allowable.to_f.zero?
      return  "%g" % @eob.total_allowable
    end
  end
  #  # End of AMT_AU Segment Details

  #Start of LX Segment Details #
    def assigned_number(*options)
      @claim_level_details[:index].to_s
    end
  #End of LX Segment Details #


  # Start of AMT_I Segment Details #
  def interest_amount(*options)
    check_amount = @check.check_amount.to_f
    interest = @eob.claim_interest.to_f
    unless interest.zero?
      get_claim_interest_amount(check_amount,interest)
    end
  end
  
  
  def get_claim_interest_amount(check_amount,interest)
    unless (check_amount == interest) # segment is not needed for interest only checks
      @eob.amount('claim_interest')
    end
  end
  # End of AMT_I Segment Details #

  # Start of NM1_QC Segment Details #
  def patient_identification_code_qualifier(*options)
    @claim_level_details[:subscriber_code_qualifier]
  end


  def patient_identifier(*options)
    @claim_level_details[ :subscriber_id]
  end
  # End of NM1_QC Segment Details #

  # For Quadax if there is Remark code MA07 or MA18 or N89 or N367 available in an EOB,
  #  then we need to set the claim type 19 in the output module only.
  #  (if LQ*HE is cheked with ANSI)
 # Start of CLP Segment Details #
  def claim_status_code(*options)
    is_industry_code_configured = @facility.industry_code_configured?
    remark_codes = []
    rcc = ReasonCodeCrosswalk.new(@payer, nil, @client, @facility)
    remark_codes = get_all_remark_codes(@classified_eob,@eob,@services,rcc)
    remark_codes = remark_codes.flatten.compact.uniq
    condition_to_print_claim_type_19 = is_industry_code_configured && !remark_codes.blank? &&
      @eob.check_validity_of_ansi_code(remark_codes)
    get_calim_type_weight_value(condition_to_print_claim_type_19,@eob)
    
  end

  def get_all_remark_codes(classified_eob,eob,services,rcc)
    remark_codes = []
    if classified_eob.is_claim_eob?
      crosswalked_codes = rcc.get_all_codes_for_entity(eob, true)
      remark_codes << crosswalked_codes[:remark_codes]
    else
      remark_codes = get_service_remark_codes(services,rcc,remark_codes)
    end
    return remark_codes
  end

  def get_service_remark_codes(services,rcc,remark_codes)
    unless services.empty?
      services.each do |svc_line|
        crosswalked_codes = rcc.get_all_codes_for_entity(svc_line, true)
        remark_codes << crosswalked_codes[:remark_codes]
        remark_codes << svc_line.get_remark_codes
      end
    end
    return remark_codes
  end

  def get_calim_type_weight_value(condition_to_print_claim_type_19,eob)
    if condition_to_print_claim_type_19
      '19'
    else
      eob.claim_type_weight
    end
  end
   
  # def patient_responsibility_amount(*options)
  #   (claim_status_code == 22) ? "" : @eob.patient_responsibility_amount
  # end

  def payer_claim_control_number(*options)
    (@facility_name == 'AVITA HEALTH SYSTEMS' && @check.job.payer_group == 'PatPay')? "RM" : super #@eob.claim_number.to_s
  end

  def total_claim_charge_amount(*options)
    return  (discount_more_eob_contractual_amount ? @check.check_amount.to_f.to_amount: super)
  end

  def claim_payment_amount(*options)
    return (discount_more_eob_contractual_amount ? @check.check_amount.to_f.to_amount: super)
  end

  def discount_more_eob_contractual_amount
    is_discount_more?(@eob.total_contractual_amount.to_f)
  end
  # End of CLP Segment Details #

  # Start of DTM_232 Segment Details #
  def claim_statement_period_start(*options)
    claim_start_date = @classified_eob.get_start_date(@claim)
    to_print_claim_dates(claim_start_date)
  end
  # End of DTM_232 Segment Details #

 
  # Start of DTM_233 Segment Details #
  def claim_statement_period_end(*options)
    claim_end_date = @classified_eob.get_end_date(@claim)
    to_print_claim_dates(claim_end_date)
  end

  def to_print_claim_dates(claim_date)
    return nil if claim_date.nil?
    claim_date = '99999999' if (claim_date == '20000101' || claim_date == '99990909')
    can_print_date = (claim_date == '99999999') ? true : can_print_service_date(claim_date)
    claim_date if can_print_date
  end
  # End of DTM_233 Segment Details #

  # Start of DTM_472 Segment Details #
  def can_print_dtm_472_segment

      if @service_level_details[:from_date] && (@service_level_details[:to_date].blank? ||
          @service_level_details[:service_in_one_day]) &&
        ( @service_level_details[:from_date] == '20000101' ||  @service_level_details[:from_date] == '99990909')
      @service_level_details[:from_date] = '99999999'
         end
      # can_print_date =
      (@service_level_details[:from_date] == '99999999') ? true : can_print_service_date(@service_level_details[:from_date])
  end
  # End of DTM_472 Segment Details #

  #Start of REF BB Segment
  def authorization_number(*options)
      @eob.uid if @eob.uid.present?
    end

  #End of REF BB Segment
 
  # Start of REF_6R Segment Details #
  def verify_ref_6r_condition
    @xpeditor_document_number = @claim.xpeditor_document_number if @claim
    if !@service.adjustment_line_is? && (@xpeditor_document_number.present? || @xpeditor_document_number == "0")
      yield
    else
      Unified835Output::BenignNull.new
    end
  end

  def line_item_control_number(*options)
    service_index_number = (@service_level_details[:index]).to_s.rjust(4 ,'0')
    @xpeditor_document_number+service_index_number
  end
  # End of REF_6R Segment Details #

  # Start of N1_PE Segment Details #
  def payee_name(*options)
    has_default_identification ?  facility_lockbox.payee_name.upcase : payee_name_quadax(@payee,@eobs)
  end

  def identification_code_qualifier(*options)
    if has_default_identification
      qualifier = 'XX'
    else
      qualifier =  (@check.payee_npi.present?)?  'XX' : (@check.payee_tin.present?)? 'FI' : nil
    end
    qualifier
  end

  def identification_code(*options)
    if has_default_identification
      code = facility_lockbox.npi.strip.upcase
    else
      code =  (@check.payee_npi.present?)? @check.payee_npi.strip.upcase : (@check.payee_tin.present?)? @check.payee_tin.strip.upcase : nil
    end
    code
  end

  def get_payee_name(payee)
    payee.name.strip.upcase
  end

  def payee_name_quadax payee,eobs
    facility_list = ["TATTNALL HOSPITAL COMPANY LLC","ORTHOPEDIC SURGEONS OF GEORGIA","OPTIM HEALTHCARE","OPTIM HEALTHCARE-WF"]
    if facility_list.include?(@facility_name)
      eob_type = @check.eob_type
      facility_payees = FacilitySpecificPayee.where(:facility_id => @facility.id,  :payer_type => eob_type).order("weightage desc")
      get_payee_from_facility_specific_payee(facility_payees,eobs)
    else
      get_payee_name_from_check_or_fcui(payee)
    end
  end

  def get_payee_name_from_check_or_fcui(payee)
    if @check.payee_name?
      @check.payee_name.strip.upcase
    elsif @output_config.details[:payee_name].present?
      @output_config.details[:payee_name].strip.upcase
    else
      get_payee_name(payee)
    end
  end

  def get_payee_from_facility_specific_payee(facility_payees,eobs)
    if facility_payees
      eob = eobs.first
      facility_payees.each do|facility_payee|
        identifier_position = eob.patient_account_number.upcase.index("#{facility_payee.db_identifier}")
        # find_facility_specific_payee(facility_payee,identifier_position)
        if (facility_payee.match_criteria.to_s == 'like' && identifier_position.present? && identifier_position >= 1 )
          @facility_payee = facility_payee
          break
        elsif (facility_payee.match_criteria.to_s == 'start_with' && identifier_position.present? && identifier_position == 0 )
          @facility_payee = facility_payee
          break
        elsif facility_payee.db_identifier == 'Other'
          @facility_payee = facility_payee
          break
        end
      end
      @facility_payee.try(:payee_name).try(:upcase)
    end
  end

  def has_default_identification
    facilities = ['AVITA HEALTH SYSTEMS','METROHEALTH SYSTEM' ]
    @facility_lockboxes.map(&:lockbox_number).include?(@batch.lockbox) if facilities.include?(@facility_name)
  end

  def facility_lockbox
    @facility_lockboxes.where(:lockbox_number => @batch.lockbox).first if has_default_identification
  end
  # End of N1_PE Segment Details #

 # Start of NM1_82 Segment Details #
  def check_provider_last_name_first_name_blank
    (@eob.rendering_provider_last_name.to_s.blank? and @eob.rendering_provider_first_name.to_s.blank?)
  end

  def entity_type_qualifier(*options)
    if has_default_identification
      check_provider_last_name_first_name_blank ?  '2' : '1'
    else
      super
    end
  end

  def rendering_provider_last_or_organization_name(*options)
    if has_default_identification
      check_provider_last_name_first_name_blank ? facility_lockbox.payee_name.to_s.upcase : super
    else
      super
    end
  end

  def rendering_provider_first_name(*options)
    if has_default_identification
      check_provider_last_name_first_name_blank ? '': super
    else
      super
    end
  end

  def rendering_provider_middle_name_or_initial(*options)
    #print_provider_first_name_middle_initial_and_suffix
    if has_default_identification
      check_provider_last_name_first_name_blank ? '': super
    else
      super
    end
  end

  def rendering_provider_name_suffix(*options)
    # print_provider_first_name_middle_initial_and_suffix
    if has_default_identification
      check_provider_last_name_first_name_blank ? '': super
    else
      super
    end
  end

  def rendering_provider_identification_code_qualifier(*options)
    if has_default_identification
      'XX'
    else
      super
      # @claim_level_details[:rendering_provider_qualifier]
    end
  end

  def rendering_provider_identifier(*options)
    if has_default_identification
      @eob.provider_npi.present? ? @eob.provider_npi :  facility_lockbox.npi.strip.upcase
    else
      super
    end
    #    @claim_level_details[:rendering_provider_id]
  end
  # End of NM1_82 Segment Details #

  #  def print_provider_first_name_middle_initial_and_suffix
  #    if has_default_identification
  #      check_provider_last_name_first_name_blank ? '': super
  #      else
  #      super
  #    end
  #  end


  # Start of SVC Segment Details #
  def is_not_claim_eob_and_service_discount_more
    # !@is_claim_eob && is_discount_more?(@service.contractual_amount.to_f)
    !@classified_eob.is_claim_eob? && is_discount_more?(@service.contractual_amount.to_f)
  end

  def line_item_charge_amount(*options)
    is_not_claim_eob_and_service_discount_more ?  @check.check_amount.to_f.to_amount : super
  end

  def line_item_provider_payment_amount(*options)
    is_not_claim_eob_and_service_discount_more ? @check.check_amount.to_f.to_amount : super
  end

  
  def is_discount_more?(discount)
    @facility_name == 'AVITA HEALTH SYSTEMS' && @eob.multiple_statement_applied == false &&
      @check.check_amount.to_f.round(2) < discount.to_f.round(2) && @payer.payer_type == 'PatPay'
  end
  # End of SVC Segment Details #

  # Start of DTM_233 Segment Details #
  def claim_statement_period_end(*options)
    claim_end_date = @classified_eob.get_end_date(@claim)
    claim_start_date = @classified_eob.get_start_date(@claim)
    different_date = if claim_end_date && claim_start_date
      claim_start_date != claim_end_date
    elsif claim_end_date
      true
    end
    (claim_end_date &&  can_print_service_date(claim_end_date) && different_date) ? claim_end_date : nil
  end
  # End of DTM_233 Segment Details #
end