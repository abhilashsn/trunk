module InsurancePaymentEobsHelper
  # The method 'default_payer' provides default Payer details for Transaction type
  def default_payer(payer)
    unless payer.blank?
      ret_text = "<input type = 'hidden' value = '#{payer.id}' id = 'default_payer_id'/>"
      ret_text << "<input type = 'hidden' value = '#{payer.payer}' id = 'default_payer_name'/>"
      ret_text << "<input type = 'hidden' value = '#{payer.pay_address_one}' id = 'default_payer_add_one'/>"
      ret_text << "<input type = 'hidden' value = '#{payer.pay_address_two}' id = 'default_payer_add_two'/>"
      ret_text << "<input type = 'hidden' value = '#{payer.payer_city}' id = 'default_payer_city'/>"
      ret_text << "<input type = 'hidden' value = '#{payer.payer_state}' id = 'default_payer_state'/>"
      ret_text << "<input type = 'hidden' value = '#{payer.payer_zip}' id = 'default_payer_zip'/>"
      ret_text.html_safe
    end
  end

  def denied_label client_name
    if client_name.blank?
      'Denied'
    else
      client_name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER' ? 'Sequestration' :  'Denied'
    end
  end

  def default_npi facility
    record = FacilitiesNpiAndTin.where(:facility_id => facility.id)
    unless record.blank?
      record.first.npi
    end
  end

  def get_parent_job_attribute job, attribute
    unless job.blank?
      parent_job_exists = !job.parent_job_id.blank?
      if parent_job_exists
        job_attribute =  Job.find_by_id(job.parent_job_id).send("#{attribute}".to_sym)
      else
        job_attribute = job.send("#{attribute}".to_sym)
      end
    end
    job_attribute
  end

  def default_tin facility
    record = FacilitiesNpiAndTin.where(:facility_id => facility.id)
    unless record.blank?
      record.first.tin
    end

  end

  def client_name
    hidden_field :client_name, :id ,:value => @client_name.upcase
  end

  #  The method 'micr_line_information' provides hidden values for micr_line_information to be available in javascript.
  def micr_line_information(micr_line_information)
    unless micr_line_information.blank?
      ret_text = ""
      unless micr_line_information.aba_routing_number.blank?
        ret_text += "<input type = 'hidden' value = '#{micr_line_information.aba_routing_number}' id = 'aba_routing_number'/>"
      end
      unless micr_line_information.payer_account_number.blank?
        ret_text += "<input type = 'hidden' value = '#{micr_line_information.payer_account_number}' id = 'payer_account_number'/>"
      end
      ret_text.html_safe
    end
  end

  def tab_type
    unless @eob_type.blank?
      text = "<input type = 'hidden' id = 'tab_type' name = 'tab_type' value = '#{@eob_type}' >"
      text.html_safe
    end
  end

  def commercial_payerid(facility)
    unless facility.commercial_payerid.blank?
      text = "<input type = 'hidden' id = 'commercial_payerid' value = '#{facility.commercial_payerid}' >"
      text.html_safe
    end
  end

  def patient_pay_format(facility)
    unless facility.patient_pay_format.blank?
      text = "<input type = 'hidden' id = 'patient_pay_format' value = '#{facility.patient_pay_format}' >"
      text.html_safe
    end
  end

  # Provides hidden fields that makes these field mandatory in the grid.
  def create_hidden_fields(facility)
    text = "<input type = 'hidden' value = '#{facility.details[:service_date_from]}' id = 'service_date_from_status'/>"
    text += "<input type = 'hidden' value = '#{facility.details[:cpt_or_revenue_code_mandatory]}' id = 'cpt_or_revenue_code_mandatory'/>"
    text += "<input type = 'hidden' value = '#{facility.details[:reference_code_mandatory]}' id = 'reference_code_mandatory_status'/>"
    text += "<input type = 'hidden' value = '#{facility.details[:reference_code]}' id = 'reference_code_status'/>"
    text += "<input type = 'hidden' value = '#{facility.details[:payment_code]}' id = 'payment_code_status'/>"
    text += "<input type = 'hidden' value = '#{facility.details[:allowed_amount_mandatory]}' id = 'allowed_amount_mandatory_status'/>"
    text += "<input type = 'hidden' value = '#{facility.details[:tooth_number]}' id = 'service_tooth_number_status'/>"
    text.html_safe
  end

  # The method creates a hidden field to identify the interest service line.
  # This is to provide client side validation.
  # If the given service line is an interest service line, a hidden field
  # having the DB id of the service line as the field id.
  def interest_service_line?(service)
    if service.interest_service_line?
      "<input type = 'hidden' value = #{service.interest_service_line?} id = 'interest_service_line_#{service.id}'/>".html_safe
    end
  end

  def correspondence_batch(check_information)
    result = "<input type = 'hidden' id = 'correspondence_batch' value = '#{check_information.correspondence?(@batch, @facility)}'>"
    result.html_safe
  end

  def set_page_count(page_count)
    result = "<input type = 'hidden' id = 'page_count' value = '#{page_count}'>"
    result.html_safe
  end

  def set_image_page_numbers_for_job(image_page_numbers_for_job)
    result = "<input type = 'hidden' id = 'image_page_numbers_for_job' value = '#{image_page_numbers_for_job}'>"
    result.html_safe
  end

  def set_image_types_for_job(image_types_for_job)
    result = "<input type = 'hidden' id = 'image_types_for_job' value = '#{image_types_for_job}'>"
    result.html_safe
  end

  def stand_alone_remark_code(facility)
    hidden_field(:ansi, :remark_code, :value => facility.details[:remark_code])
  end

  def balance_record_type(eob)
    hidden_field(:eob, :balance_record_type, :value => eob.balance_record_type)
  end

  # Provides the javascript method that needs to be called while completing a job.
  def validation_on_completing_a_job(parent_job_id, total_eobs_for_job, eob_count_status, client_name, is_partner_bac)
    validation_functions = "return validateSaveOfOcrEos()"
    validation_functions += " && checkCommentForComplete()"
    validation_functions += " && validateTransactionType() && confirmForTransactionType()"

    if @client_name == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
      validation_functions += " && validateUpmcJobComplete('processor')"
    else
      validation_functions += " && validateEobPresence(#{total_eobs_for_job})"
    end

    if parent_job_id.blank?
      validation_functions += " && isCheckBalanced()"
    end
   
    validation_functions += " && setJobButtonValue('COMPLETE')"
    validation_functions += " && confirmationAlert()"
  end

  def validation_on_incompleting_a_job(client_name, eobs_count_on_job)
    validation_functions = "return checkComment()"
    if @facility.details[:eob_must_present_for_job_completion] ||
        (["QUADAX", "GOODMAN CAMPBELL", "INSIGHT IMAGING", "MEDASSETS",
          "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"].include?(client_name.to_s.upcase))
      validation_functions += " && validateEobPresence(#{eobs_count_on_job})"
    end
    validation_functions += " && setJobButtonValue('INCOMPLETE')"
    validation_functions += " && validateIncompleteRejectionComment() && confirmationAlert()"
  end

  # Provides the javascript method that needs to be called while updating a job by QA.
  def validation_on_qa_completing_a_job(parent_job_id)
    validation_functions = "return check_comment()"

    if @client_name == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
      validation_functions += " && validateUpmcJobComplete('qa')"
    elsif @facility.details[:eob_must_present_for_job_completion] ||
        (["QUADAX", "GOODMAN CAMPBELL", "INSIGHT IMAGING", "MEDASSETS",
          "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"].include?(@client.name.to_s.upcase))
      validation_functions += " && validateEobPresence()"
    end

    if parent_job_id.blank?
      validation_functions += " && isCheckBalanced()"
    end    
    validation_functions += " && setSubmitButtonValue('Update Job')"
    validation_functions += " && confirmationAlert()"    
  end

  def colspan_for_modifier(facility, claim_level_eob)
    if claim_level_eob
      col_span = col_span_for_service_date_and_line_item facility
    else
      col_span =  "4"
    end
    col_span = col_span_for_line_item_in_patpay_claim_level_grid col_span, claim_level_eob, facility
    return col_span
  end


  def col_span_for_service_date_and_line_item facility
    if !facility.details[:service_date_from] && facility.details[:line_item]
      col_span = "3"
    elsif !facility.details[:service_date_from]
      col_span =  "2"
    elsif facility.details[:service_date_from] && !facility.details[:line_item]
      col_span = "4"
    elsif facility.details[:service_date_from]
      col_span =  "5"
    else
      col_span =  "4"
    end
    col_span
  end

  def col_span_for_line_item_in_patpay_claim_level_grid col_span, claim_level_eob, facility
    if col_span.present? && facility.details[:line_item] && claim_level_eob && @eob_type == 'Patient'
      col_span = (col_span.to_i) - 1
    end
    col_span
  end

  def readonly_attribute_for_adjustment_amounts
    if (@patient_pay && (@site_code == "S40" || @site_code == "P84" || @site_code == "502"))
      true
    else
      false
    end
  end

  def set_balance_amount_in_dollar_field(field_id, line_count, total_field_id)
    if (@patient_pay && (@site_code == "S40" || @site_code == "P84" || @site_code == "502"))
      set_balane_amount = ""
    else
      set_balane_amount = "setMpiBalancevalue("+field_id+","+line_count.to_s+","+total_field_id+")"
    end
    set_balane_amount
  end

  def readonly_attribute_for_total_adjustment_amounts
    if (@claim_level_eob && @patient_pay && (@site_code == "S40" || @site_code == "P84" || @site_code == "502"))
      true
    elsif @claim_level_eob
      false
    else
      true
    end
  end

  def set_balance_amount_in_total_dollar_field(total_field_id)
    if (@claim_level_eob && @patient_pay && (@site_code == "S40" || @site_code == "P84" || @site_code == "502"))
      set_balane_amount = ""
    elsif @claim_level_eob
      set_balane_amount = "setBalancevalue("+total_field_id+")"
    else
      set_balane_amount = ""
    end
    set_balane_amount
  end

  # Returns the class name to be applied on the charge field.
  def charge_must_be_nonzero(site_code)
    if(site_code == "P84")
      if @claim_level_eob
        validation = "validate-charge_in_claim_level_eob"
      else
        validation = "validate-charge_in_service"
      end
    else
      validation = ""
    end
    validation
  end

  def set_charge_amount_in_denied_flag
    chagre_in_denied_applicable_sitecodes = ['S40', '502', '985', '986', '987', '988', '989', 'K22', 'K23']
    if(@check_information.correspondence?(@batch, @facility) && @insurance_pay &&
          chagre_in_denied_applicable_sitecodes.include?(@site_code))
      true
    else
      false
    end
  end

  def facility_sitecode
    hidden_field_tag :sitecode, @site_code
  end

  def charge_amount_in_denied
    hidden_field_tag :charge_amount_in_denied, set_charge_amount_in_denied_flag
  end

  # This provides read only attribute for payer name field in DC Grid
  # Output :
  # True when payer name is to be made as read only, else false
  def set_payer_name_as_readonly
    accepted_payer = false
    payer_is_attached = false

    if !@payer.blank? && session[:mode] != 'VERIFICATION'
      accepted_payer = @payer.accepted?
      if !@micr_line_information.blank?
        payer_is_attached = @micr_line_information.payer == @payer
      end
    end

    (!@payer.blank? && session[:mode] != 'VERIFICATION' && (is_eob_saved? || accepted_payer || payer_is_attached))

    #readonly_attibute = is_eob_saved? || accepted_payer || payer_is_attached
    #if readonly_attibute.nil?
    #  readonly_attibute = false
    #end
    #readonly_attibute
  end

  # This provides a back ground color for payer name field in DC Grid
  # Input :
  # make_payer_name_readonly : This should be true when payer name is made as read only, else false
  # Output :
  # grey color if the field is read only else white
  def bg_color_attribute_for_payer_name(make_payer_name_readonly)
    if !make_payer_name_readonly.blank?
      'background-color:#A9A9A9'
    else
      ''
    end
  end

  # This provides read only attribute for payer address fields in DC Grid
  # Output :
  # True when payer address fields are to be made as read only, else false
  def readonly_attribute_for_payer_address
    readonly = false
    if is_eob_saved? && !@payer.blank? && session[:mode] != 'VERIFICATION'
      readonly = true
    elsif !@payer.blank?
      readonly = @payer.accepted?
    elsif session[:mode] == 'VERIFICATION'
      readonly = false
    end
    readonly
  end

  # This provides a back ground color for payer address fields in DC Grid
  # Input :
  # make_payer_address_readonly : This should be true when payer address is made as read only, else false
  # Output :
  # grey color if the field is read only else white
  def bg_color_attribute_for_payer_address(make_payer_address_readonly)
    if !make_payer_address_readonly.blank?
      'background-color:#A9A9A9'
    else
      ''
    end
  end

  def readonly_attribute_for_routing_number
    if !@micr_line_information.blank? || (!@micr_line_information.blank? && is_eob_saved?)
      !@micr_line_information.aba_routing_number.blank?    
    end
  end

  def readonly_attribute_for_account_number
    if (!@micr_line_information.blank? || (!@micr_line_information.blank? && is_eob_saved?))
      !@micr_line_information.payer_account_number.blank?
    end
  end

  def bg_color_attribute_for_routing_number
    if !@micr_line_information.blank? || (!@micr_line_information.blank? && is_eob_saved?)
      unless @micr_line_information.aba_routing_number.blank?
        'background-color:#A9A9A9'
      end
    end
  end

  def bg_color_attribute_for_account_number
    if !@micr_line_information.blank? || (!@micr_line_information.blank? && is_eob_saved?)
      unless @micr_line_information.payer_account_number.blank?
        'background-color:#A9A9A9'
      end
    end
  end

  def payer_status
    hidden_field(:payer, :status, :value => '')
  end

  def payer_payid(payid)
    hidden_field(:payer, :payid, :value => payid)
  end

  def payer_from_check_or_micr
    hidden_field(:payer, :from_check_or_micr, :value => !@payer.blank?)
  end

  def payer_name_from_check_or_micr
    if !@payer.blank?
      hidden_field(:payer_name, :from_check_or_micr, :value => @payer.name)
    end
  end

  def hidden_payer_name
    if !@payer.blank?
      payer_name = @payer.name
    else
      payer_name = ''
    end
    hidden_field(:hidden, :payer_name, :value => payer_name)
  end

  def payer_indicator_values(check_information, patient, payer_indicator_hash, default_payer_indicator)
    unless patient.blank?
      unless patient.balance_record_type.blank? || patient.balance_record_type.downcase == 'none'
        payer_indicator_hash = {"ALL" => "ALL"}
      end
    end
    if check_information.correspondence?(@batch, @facility)
      default_payer_indicator = ''
    end
    chosen_payer_indicator = patient.payer_indicator || default_payer_indicator
    return payer_indicator_hash, chosen_payer_indicator
  end

  def payment_amount_validation(service, line_count)    
    "required" if !service.adjustment_line_is? && line_count != 1
  end

  # Returns the class name to be applied on the allowable amount.
  # if its an interest service line or an adjustment line, allow is not mandatory.
  # else it is mandatory.
  def allowable_validation(service)
    "required" unless (!@facility.details[:allowed_amount_mandatory] ||
        service.adjustment_line_is? || service.interest_service_line?)
  end

  def allowable_validation_claim_level()
    "required" if @facility.details[:claim_level_allowed_amount_in_grid] && @claim_level_eob
  end

  # Returns the class name to be applied on the necessary fields.
  def service_column_mandatory(service, column, facility, line_count)
    column_name = column
    column = column.to_sym
    if((facility.details[column]) == true)
      validation = "required"
    else
      validation = ""
    end
    if( line_count == 1 || service.adjustment_line_is? || service.interest_service_line? )
      validation = ""
    end
    if( column_name == "service_procedure_charge_amount" &&
          !(line_count == 1 || service.adjustment_line_is? ))
      validation = "required"
    end
    validation
  end

  # Applies the class name for validating the CPT Code.
  def cpt_mandatory(service, facility, line_count)
    if(facility.details[:cpt_or_revenue_code_mandatory] == true)
      validation = "validate-cpt-or-revenue-code-mandatory validate-cpt_code_length validate-upmc_revenue_code_cpt_code_length"
    else
      validation = "validate-cpt_code_length validate-upmc_revenue_code_cpt_code_length"
    end
    if((line_count == 1 || service.adjustment_line_is? || service.interest_service_line?) && !@patient_pay)
      validation = ""
    end
    validation
  end

  def validate_revenue_code(service, facility, line_count)
    if(facility.details[:cpt_or_revenue_code_mandatory] == true)
      validation = "validate-cpt-or-revenue-code-mandatory validate-revenue-code"
    else
      validation = "validate-revenue-code"
    end
    if((line_count == 1 || service.adjustment_line_is? || service.interest_service_line?) && !@patient_pay)
      validation = ""
    end
    validation
  end

  def validate_tooth_number(service, facility, line_count)
    if(facility.details[:tooth_number] == true && @insurance_pay)
      validation = 'validate-tooth-number'
    end
    if((line_count == 1 || service.adjustment_line_is? || service.interest_service_line?))
      validation = ""
    end
    validation

  end

  def applicable_payer_indicator( payid )
    payer_indicator = {"ALL" => "ALL"}
    default_payer_indicator = "ALL"
    unless payid.blank?
      if payid.upcase == "CMUN1"
        payer_indicator = {"CHK" => "UHC", "PAY" => "UHS", "" => ""}
        default_payer_indicator = "UHC"
      elsif payid == "60054" || payid == "23222"
        payer_indicator = {"" => "", "EOB" => "AET", "PAY" => "APP"}
        default_payer_indicator = ""
      elsif payid == "55247"
        payer_indicator = {"HIP" => "HIP"}
        default_payer_indicator = "HIP"
      end
    end
    return payer_indicator, default_payer_indicator
  end

  def prov_adjustment_details
    prov_adjustment_description_hash =  provider_adjustment_descriptions.inject({}) { |state, (key, val)| state.merge(key => val) }
    return prov_adjustment_description_hash
  end

  def provider_adjustment_descriptions
    prov_adjustment_description = [
      ["AP - ACCELERATION OF BENEFITS", "AP"],
      ["CS - ADJUSTMENT", "CS"],
      ["AM - APPLIED TO BORROWERS ACCOUNT", "AM"],
      ["72 - AUTHORIZED RETURN", "72"],
      ["B3 - RECOVERY ALLOWANCE", "B3"],
      ["BD - BAD DEBT ADJUSTMENT", "BD"],
      ["BN - BONUS", "BN"],
      ["CV - CAPITAL PASSTHRU", "CV"],
      ["CR - CAPITATION INTEREST", "CR"],
      ["CT - CAPITATION PAYMENT", "CT"],
      ["CW - CERT.REG NURSE ANES PASSTHRU", "CW"],
      ["DM - DIRECT MEDICAL EDU PASSTHRU", "DM"],
      ["90 - EARLY PAYMENT ALLOWANCE", "90"],
      ["FB - FORWARDING BALANCE", "FB"],
      ["FC - FUND ALLOCATION", "FC"],
      ["GO - GRAD MEDICAL EDU PASSTHRU", "GO"],
      ["HM - HEMOPHILIA CLOTTING SUPP", "HM"],
      ["IP - INCENTIVE PREMIUM PAYMENT", "IP"],
      ["IR - INT REV SERVICE WITHHOLDING", "IR"],
      ["L6 - INTEREST", "L6"],
      ["51 - INTEREST PENALTY CHARGE", "51"],
      ["IS - INTERIM SETTLEMENT", "IS"],
      ["50 - LATE CLAIM FILING CHARGE", "50"],
      ["LE - LEVY", "LE"],
      ["LS - LUMP SUM", "LS"],
      ["J1 - NONREIMBURSABLE", "J1"],
      ["OB - OFFSET FOR AFF PROVIDERS", "OB"],
      ["OA - ORGAN ACQUISITION PASSTHRU", "OA"],
      ["AH - ORIGINATION FEE", "AH"],
      ["WO - OVERPAYMENT RECOVERY", "WO"],
      ["PL - PAYMENT FINAL", "PL"],
      ["L3 - PENALTY", "L3"],
      ["PI - PERIODIC INTERM PAYMENT", "PI"],
      ["B2 - REBATE", "B2"],
      ["RA - RETRO-ACTIVITY ADJUSTMENT", "RA"],
      ["RE - RETURN ON EQUITY", "RE"],
      ["SL - STUDENT LOAN REPAYMENT", "SL"],
      ["C5 - TEMPORARY ALLOWANCE", "C5"],
      ["TL - THIRD PARTY LIABILITY", "TL"],
      ["WU - UNSPECIFIED RECOVERY", "WU"],
      ["E3 - WITHHOLDING", "E3"]
    ]
    prov_adjustment_description
  end

  def set_reason_code_id(line_number, claim_level_eob, service, eob)
    if service == ""
      value_of_coinsurance = ""
      value_of_contractual = ""
      value_of_copay = ""
      value_of_deductible = ""
      value_of_denied = ""
      value_of_discount = ""
      value_of_noncovered = ""
      value_of_primary_payment = ""
      value_of_prepaid = ""
      value_of_patient_responsibility = ""
      value_of_miscellaneous_one = ""
      value_of_miscellaneous_two = ""
    elsif service.class == ServicePaymentEob
      value_of_coinsurance = service.coinsurance_id
      value_of_contractual = service.contractual_id
      value_of_copay = service.copay_id
      value_of_deductible = service.deductible_id
      value_of_denied = service.denied_id
      value_of_discount = service.discount_id
      value_of_noncovered = service.noncovered_id
      value_of_primary_payment = service.primary_payment_id
      value_of_prepaid = service.prepaid_id
      value_of_patient_responsibility = service.patient_responsibility_id
      value_of_miscellaneous_one = service.miscellaneous_one_id
      value_of_miscellaneous_two = service.miscellaneous_two_id
    end

    if eob == ""
      value_of_claim_coinsurance = ""
      value_of_claim_contractual = ""
      value_of_claim_copay = ""
      value_of_claim_deductible = ""
      value_of_claim_denied = ""
      value_of_claim_discount = ""
      value_of_claim_noncovered = ""
      value_of_claim_primary_payment = ""
      value_of_claim_prepaid = ""
      value_of_claim_patient_responsibility = ""
      value_of_claim_miscellaneous_one = ""
      value_of_claim_miscellaneous_two = ""
    elsif eob.class == InsurancePaymentEob
      value_of_claim_coinsurance = eob.claim_coinsurance_id
      value_of_claim_contractual = eob.claim_contractual_id
      value_of_claim_copay = eob.claim_copay_id
      value_of_claim_deductible = eob.claim_deductible_id
      value_of_claim_denied = eob.claim_denied_id
      value_of_claim_discount = eob.claim_discount_id
      value_of_claim_noncovered = eob.claim_noncovered_id
      value_of_claim_primary_payment = eob.claim_primary_payment_id
      value_of_claim_prepaid = eob.claim_prepaid_id
      value_of_claim_patient_responsibility = eob.claim_patient_responsibility_id
      value_of_claim_miscellaneous_one = eob.claim_miscellaneous_one_id
      value_of_claim_miscellaneous_two = eob.claim_miscellaneous_two_id
    end

    if claim_level_eob
      text = "<input type = 'hidden' id = 'reason_code_id_claim_noncovered#{line_number.to_s}' value = '#{value_of_claim_noncovered}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_denied#{line_number.to_s}' value = '#{value_of_claim_denied}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_discount#{line_number.to_s}' value = '#{value_of_claim_discount}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_coinsurance#{line_number.to_s}' value = '#{value_of_claim_coinsurance}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_deductible#{line_number.to_s}' value = '#{value_of_claim_deductible}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_copay#{line_number.to_s}' value = '#{value_of_claim_copay}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_primary_payment#{line_number.to_s}' value = '#{value_of_claim_primary_payment}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_contractual#{line_number.to_s}' value = '#{value_of_claim_contractual}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_prepaid#{line_number.to_s}' value = '#{value_of_claim_prepaid}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_patient_responsibility#{line_number.to_s}' value = '#{value_of_claim_patient_responsibility}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_miscellaneous_one#{line_number.to_s}' value = '#{value_of_claim_miscellaneous_one}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_claim_miscellaneous_two#{line_number.to_s}' value = '#{value_of_claim_miscellaneous_two}'>"
      text.html_safe
    else
      text = "<input type = 'hidden' id = 'reason_code_id_noncovered#{line_number.to_s}' value = '#{value_of_noncovered}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_denied#{line_number.to_s}' value = '#{value_of_denied}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_discount#{line_number.to_s}' value = '#{value_of_discount}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_coinsurance#{line_number.to_s}' value = '#{value_of_coinsurance}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_deductible#{line_number.to_s}' value = '#{value_of_deductible}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_copay#{line_number.to_s}' value = '#{value_of_copay}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_primary_payment#{line_number.to_s}' value = '#{value_of_primary_payment}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_contractual#{line_number.to_s}' value = '#{value_of_contractual}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_prepaid#{line_number.to_s}' value = '#{value_of_prepaid}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_patient_responsibility#{line_number.to_s}' value = '#{value_of_patient_responsibility}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_miscellaneous_one#{line_number.to_s}' value = '#{value_of_miscellaneous_one}'>"
      text << "<input type = 'hidden' id = 'reason_code_id_miscellaneous_two#{line_number.to_s}' value = '#{value_of_miscellaneous_two}'>"
      text.html_safe
    end
  end

  def set_default_unique_codes(is_partner_bac)
    unless is_partner_bac
      value = @is_facility_horizon_eye? "46" : "23"
      text = "<input type = 'hidden' id = 'default_unique_code_deductible' value = '1'>"
      text += "<input type = 'hidden' id = 'default_unique_code_coinsurance' value = '2'>"
      text += "<input type = 'hidden' id = 'default_unique_code_copay' value = '3'>"
      text += "<input type = 'hidden' id = 'default_unique_code_primary_payment' value = '#{value}'>"
      text += "<input type = 'hidden' id = 'default_id_deductible' value = '#{@hash_with_default_rc_ids["decuctible"]}'>"
      text += "<input type = 'hidden' id = 'default_id_coinsurance' value = '#{@hash_with_default_rc_ids["coinsurance"]}'>"
      text += "<input type = 'hidden' id = 'default_id_copay' value = '#{@hash_with_default_rc_ids["copay"]}'>"
      text += "<input type = 'hidden' id = 'default_id_primary_payment' value = '#{@hash_with_default_rc_ids["primary_payment"]}'>"
      text.html_safe
    end
  end

  def default_service_date(facility, batch, check)
    fc_def_sdate = facility.default_service_date
    def_sdate = case fc_def_sdate
    when 'Batch Date'
      batch.date.strftime '%m/%d/%y'
    when 'Check Date'
      check.date_in_checks(check.check_date)
    else
      fc_def_sdate
    end
  end

  def adjustment_line_to_hide
    hidden_field :hide, :adjustment_line, :value => @hide_adj_line
  end

  def type_of_payer_created_by_admin
    hidden_field :type_of_payer, :created_by_admin, :value => @payer_type
  end

  def is_eob_saved_OLD?
    (!@patient_pay_eobs_saved.blank? || !@insurance_eobs_saved.blank?)
  end

  def is_eob_saved?
    # Earlier is use to return count, now it returns boolean
    (@patient_pay_eobs_saved || @insurance_eobs_saved)
  end

  def is_any_eob_present
    hidden_field :is_any_eob_saved_for, :job, :value => is_eob_saved?
  end

  def is_reason_code_mandatory
    hidden_field :is_reason_code, :mandatory, :value => @facility.details[:reason_code_mandatory]
  end

  def is_adjustment_amount_mandatory
    hidden_field :is_adjustment_amount, :mandatory, :value => @facility.details[:adjustment_amount_mandatory]
  end

  def is_payer_address_mandatory
    if !@payer.blank?
      mapped_payer = (@payer.status.to_s.upcase == 'MAPPED')
    end
    if !@is_partner_bac && !mapped_payer
      'required'
    else
      ''
    end
  end

  def set_submit_button_value
    hidden_field :submit_button, :name, :value => ""
  end

  def svc_line_table_height
    svc_line_length = @service_line.length
    if svc_line_length <= 3
      height = svc_line_length * 10 + 16
    else
      height = 76
    end
    "#{height}px"
  end

  # check date for processor UI
  def check_date
    if (@check_information.check_date).blank?
      "mm/dd/yy"
    else
      @check_information.check_date.strftime("%m/%d/%y")
    end
  end

  def check_date_hidden_field
    if @facility.is_check_date_as_batch_date
      check_date_value = check_date
      hidden_field :checkdate, :id, :value => check_date_value
    end  
  end

  def parent_job_id_of_child_job
    hidden_field :child_job, :parent_job_id, :value => @parent_job_id
  end
  
  def document_classification_list_for_payment
    document_classification_list = {'--' => '--',
      'Roster' => 'Roster',
      'EOB' => 'EOB',
      'Payer Check w/o EOB' => 'Payer Check w/o EOB',
      'Patient Payment' => 'Patient Payment',
      'Patient Payment w/ Updates' => 'Patient Payment w/ Updates',
      'Patient Payment w/o Statement' => 'Patient Payment w/o Statement',
      'Other Payment' => 'Other Payment',
      'EOB w/ EFT' => 'EOB w/ EFT',
      'Total Denial' => 'Total Denial',
      'Financial Aid' => 'Financial Aid',
      'Uncashed Check' => 'Uncashed Check',
      'Credit Card Insurance' => 'Credit Card Insurance',
      'Credit Card Patient Payment' => 'Credit Card Patient Payment'
    }
  end

  def document_classification_list_for_correspondence
    document_classification_list = {'--' => '--',
      'Updates' => 'Updates', 
      'Mail Returns' => 'Mail Returns',
      'Bankruptcy' => 'Bankruptcy',
      'Claim Updates' => 'Claim Updates',
      'Collections' => 'Collections',
      'EOB w/ EFT' => 'EOB w/ EFT',
      'Total Denial' => 'Total Denial',
      'Refunds' => 'Refunds', 
      'Exceptions' => 'Exceptions',
      'Financial Aid' => 'Financial Aid',
      'Uncashed Check' => 'Uncashed Check',
      'Credit Card Insurance' => 'Credit Card Insurance',
      'Credit Card Patient Payment' => 'Credit Card Patient Payment'
    }

    document_classification_list = document_classification_for_quadax document_classification_list

    document_classification_list
  end

  def document_classification_for_quadax document_classification_list
    if @client_name.upcase.strip  == 'QUADAX'
      quadax_document_classification = {'Medical Records' => 'Medical Records',
        'RAC' => 'RAC',
        'W9' => 'W9'}
      document_classification_list.merge!(quadax_document_classification)
    end
    
    document_classification_list
  end
  
  def get_document_classification_list
    if @check_information.payment_method == 'COR' || @check_information.payment_method == 'EFT'
      document_classification_list = document_classification_list_for_correspondence
    else
      document_classification_list = document_classification_list_for_payment
    end
  end
  
  def is_document_classification_mandatory
    if @facility.details[:document_classification] && @facility.details[:document_classification_mandatory]
      'validate-non-blank-drop-down'
    else
      ''
    end
  end

  def double_keying_class field_name
    if ((!(@patient_837_information.blank?)) && (@facility.double_keying_for_837_fields == false))
      if (field_name == 'marital_status') || (field_name == 'line_item_number')
        value_for_marital_status = @patient_837_information.find_key("#{field_name}")
        'disable-double-keying' unless value_for_marital_status.blank?
      else
        'disable-double-keying'  unless (@patient_837_information.send("#{field_name}").blank?)
      end
    end
  end

  def get_twice_keying_class  service, field_name
    if ((!(service.blank?)) && (@facility.double_keying_for_837_fields == false) && (service.class == ClaimServiceInformation))
      "disable-double-keying" unless ((service.send("#{field_name}").blank?))
    end
  end

  def set_patient_name_validation
    if @is_partner_bac
      'validate-patient_account_number'
    else
      if @facility.details[:patient_name_format_validation]
        'validate-alphanum-hyphen-space-period'
      end
    end
  end

  def saved_transaction_type
    hidden_field :transaction_type, :saved, :value => @check_information.get_transaction_type
  end

  def payment_method_values
    (@facility.client.name.upcase == 'ORBOGRAPH' || @facility.client.name.upcase == 'ORB TEST FACILITY' ) ? ['CHK', 'COR', 'ACH', 'OTH'] : ['CHK', 'COR', 'EFT', 'OTH']
  end
  
  def payment_method_hidden_field
    if !@facility.details[:transaction_type]
      payment_method = @check_information.payment_method || payment_method_values.first
      hidden_field :check_information, :payment_method, :value => payment_method
    end
  end

  def bg_color_to_check_number
    if @has_system_generated_check_number
      'background-color:#A9A9A9'
    else
      ''
    end
  end

  def generated_check_number
    if @client_name.upcase == 'QUADAX' && @check_information.check_amount.to_f > 0
      value_for_check_num = @check_information.generated_check_number_without_timestamp_for_quadax_eft(@batch)
    else
      value_for_check_num = @check_information.generated_check_number_without_timestamp(@batch)
    end
    hidden_field :generated, :check_number, :value => value_for_check_num
  end

  def hidden_field_for_account_num_prefix
    hidden_field :details, :account_num_prefix, :value => @facility.details[:account_num_prefix]
  end

  def any_eob_processed(job)
    @any_eob_processed = @check_information.any_eob_processed?
    hidden_field :any_eob, :processed, :value => @any_eob_processed
  end

  def hidden_field_for_transaction_type_config
    hidden_field :transaction_type, :config, :value => @facility.details[:transaction_type]
  end

  def is_role_processor
    hidden_field :user_role_is, :processor, :value => current_user.has_role?(:processor)
  end

  def enable_check_validations
    correspondence = @check_information.check_amount.to_f.zero? && @check_information.check_number.to_f.zero?
    enable_check_validation = !(@facility.details[:transaction_type] && correspondence)
    enable_check_validation
  end

  def class_for_check_number
    if enable_check_validations
      "required validate-nonzero-alphanum"
    end
  end

  def class_for_aba
    if enable_check_validations
      "required validate-aba"
    end
  end

  def class_for_payer_acc_num
    if enable_check_validations
      "required validate-payer-acc-num"
    end
  end

  def class_for_check_amount
    if enable_check_validations
      "required validate-nonzero-checkamount"
    end
  end
  
  def class_for_check_date
    correspondence = @check_information.check_amount.to_f.zero? && @check_information.check_number.to_f.zero?
    if !(@facility.details[:transaction_type] && correspondence)
      "required validate-check-date"
    end
  end  

  def correspondence_check
    correspondence = @check_information.check_amount.to_f.zero? && @check_information.check_number.to_f.zero?
    hidden_field :correspondence, :check, :value => correspondence
  end

  def service_line_serial_numbers
    hidden_field :service_line, :serial_numbers, :value => ''
  end

  def service_lines_to_delete
    hidden_field :service_line, :to_delete, :value => ''
  end

  def service_line_delete_all
    hidden_field :service_line, :delete_all, :value => ''
  end

  def is_adjustment_amount_zero
    hidden_field :is_adjustment_amount, :zero, :value => @facility.details[:adjustment_amount_zero]
  end

  def interest_only_eob_id
    interest_only_eob_id = @check_information.interest_only_eob_id(@client_name)
    if !interest_only_eob_id.blank?
      hidden_field :interest_only, :eob_id, :value => @check_information.interest_only_eob_id(@client_name)
    end
  end

  def does_check_have_interest_eob
    interest_eobs = InsurancePaymentEob.where(:check_information_id => @check_information.id, :balance_record_type => 'INTEREST ONLY')
    hidden_field :check, :have_interest_eob, :value => !interest_eobs.blank?
  end

  def interest_in_service_line
    hidden_field 'interest_in','service_line',:value => @facility.details[:interest_in_service_line]
  end

  def claim_level_service_lines_applicable
    hidden_field :claim_level, :service_lines_applicable, :value => @facility.details[:claim_level_service_lines]
  end

  def hidden_field_for_lockbox_number
    hidden_field :batch, :lockbox_number, :value => @batch.get_lockbox_number
  end

  def hidden_field_for_batch_date
    hidden_field :batch, :date, :value => @batch.date.strftime("%m/%d/%y")
  end

  def hidden_field_for_patient_stmt_flds_present
    hidden_field :patient_stmt_flds, :present, :value => @patient_stmt_flds_present
  end

  def get_value(eob_value,claim_value)
    unless claim_value.blank?
      val = claim_value
    else
      val = eob_value
    end
    val
  end

  def get_class(eob_value,claim_value)
    unless claim_value.blank?
      val = claim_value
    else
      val = eob_value
    end
    val
  end

  def hidden_fields_for_twice_keying_previous_values
    hidden_fields = "<input type = 'hidden' value = '' id = 'twice_keying_prev_values_of_add_row'/> "
    hidden_fields += "<input type = 'hidden' value = '' id = 'twice_keying_prev_values_of_provider_adjustment'/> "
    hidden_fields += "<input type = 'hidden' value = '' id = 'twice_keying_prev_values_of_all_fields'/> "
    hidden_fields += "<input type = 'hidden' value = '' id = 'twice_keying_prev_values_of_random_sampling_fields'/> "
    hidden_fields += "<input type = 'hidden' value = '' id = '837_changed_fields'/> "
    hidden_fields.html_safe
  end

  def hidden_field_for_default_claim_number
    hidden_field :default, :claim_number, :value => @facility.details[:default_claim_number]
  end
  def repricer_values
    document_classification_list = {'--' => '',
      'Beech Street' => 'Beech Street',
      'Beech Street Directly Contracted Payers' => 'Beech Street Directly Contracted Payers',
      'Beech Street Intergroup' => 'Beech Street Intergroup',
      'Beech Street Multiplan' => 'Beech Street Multiplan',
      'Beech Street PPO' => 'Beech Street PPO',
      'Crawford' => 'Crawford',
      'Crawford Health Plan' => 'Crawford Health Plan',
      'Devon' => 'Devon',
      'Devon Health' => 'Devon Health',
      'Flora' => 'Flora',
      'Flora Health Network' => 'Flora Health Network',
      'Great West' =>  'Great West',
      'Health Coalition Partners'=> 'Health Coalition Partners',
      'Health Coalition Partners Directly Contracted Payers' =>  'Health Coalition Partners Directly Contracted Payers',
      'Health Coalition Partners Intergroup' => 'Health Coalition Partners Intergroup',
      'Health Coalition Partners PPO' => 'Health Coalition Partners PPO',
      'HPOUV'=> 'HPOUV',
      'Health Plan of Upper Ohio Valley' => 'Health Plan of Upper Ohio Valley',
      'Humana Choice'=> 'Humana Choice',
      'Intergroup Directly contracted Payers' => 'Intergroup Directly contracted Payers',
      'Intergroup PPO' => 'Intergroup PPO',
      'Intergroup' => 'Intergroup',
      'Kaiser' => 'Kaiser',
      'Kaiser Permanente' => 'Kaiser Permanente',
      'Multiplan' => 'Multiplan',
      'National Provider Network' => 'National Provider Network',
      'One Health Plan/Great West' =>  'One Health Plan/Great West',
      'Penn Highlands Health Plan'  => 'Penn Highlands Health Plan',
      'Preferred Health Care System' => 'Preferred Health Care System',
      'Prime Net' => 'Prime Net',
      'Private Health Care System' => 'Private Health Care System','MISC' => 'MISC'}
  end

  def interest_only_check
    hidden_field :checkinforamation, :interest_only_check, :value => @check_information.interest_only_check
  end

  def set_payer_details
    if @facility.details[:interest_only_835]
      hidden_fields = "<input type = 'hidden' value = '' name = 'payer[payer_id]' id = 'payerId'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[popup]' id = 'payerName'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[pay_address_one]' id = 'payerAddressOne'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[pay_address_two]' id = 'payerAddressTwo'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[payer_city]' id = 'payerCity'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[payer_state]' id = 'payerState'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[payer_zip]' id = 'payerZip'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer[payer_tin]' id = 'payerTin'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'payer_type' id = 'payerType'/> "
      hidden_fields.html_safe
    end
  end

  def set_check_details
    if @facility.details[:interest_only_835]
      hidden_fields = "<input type = 'hidden' value = '' name = 'micr_line_information[aba_routing_number]' id = 'abaRoutingNumber'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'micr_line_information[payer_account_number]' id = 'payerAccountNumber'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[check_date]' id = 'checkDate'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[check_amount]' id = 'checkAmount'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[check_number]' id = 'checkNumber'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[alternate_payer_name]' id = 'alternatePayerName'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[payment_type]' id = 'paymentType'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[payee_tin]' id = 'payeeTin'/> "
      hidden_fields += "<input type = 'hidden' value = '' name = 'checkinforamation[payee_name]' id = 'payeeName'/> "
      hidden_fields.html_safe
    end
  end

  def hipaa_adjustment_codes_field
    hipaa_adjustment_codes = ''
    hipaa_adjustment_codes = @hipaa_adjustment_codes.join(',') if @hipaa_adjustment_codes.present?
    hidden_field_tag :hipaa_adjustment_codes_field, hipaa_adjustment_codes
  end

  def hidden_field_for_multiple_reason_codes_in_adjustment_field
    hidden_field_tag :multiple_reason_codes_in_adjustment_field, @facility.details[:multiple_reason_codes_in_adjustment_field]
  end

  def default_date(default_date_config, batch_date, check_date)
    case default_date_config
    when 'Check Date'
      check_date
    when 'Batch Date'
      batch_date
    else
      default_date_config
    end
  end

  def get_date
    if @facility.details[:service_date_from]
      default_service_date = default_date(@facility.default_service_date,
        @batch.date, @check_information.check_date)
      if default_service_date.blank?
        default_service_date = @batch.date
      end

      if !default_service_date.blank? && !default_service_date.is_a?(String)
        default_service_date = default_service_date.strftime("%m/%d/%y")
      end
    end
    default_service_date
  end


  def get_patient_name(parameters)
    if parameters[:balance_record_config].is_payer_the_patient == true
      payer_name = parameters[:payer_name].split(' ') unless parameters[:payer_name].blank?
      patient_first_name = payer_name[0]
      payer_name.slice!(0)
      payer_last_name = payer_name.join(' ')
      patient_last_name = payer_last_name
      if patient_last_name.blank? && payer_last_name.blank?
        patient_last_name = payer_name[0]
      end
    else
      patient_first_name = parameters[:balance_record_config].first_name
      patient_last_name = parameters[:balance_record_config].last_name
    end
    return patient_first_name, patient_last_name
  end

  def get_charge_and_payment(parameters)
    balance_record_config = parameters[:balance_record_config].source_of_adjustment.to_s.upcase
    if balance_record_config == 'CHECK'
      charge_amount, paid_amount  = parameters[:check_amount], parameters[:check_amount]
    elsif balance_record_config == 'BALANCE'
      charge_amount, paid_amount = parameters[:balance_amount], parameters[:balance_amount]
    end
    return charge_amount, paid_amount
  end

  def condition_to_hide_incomplete_button
    (@facility.details[:hide_incomplete_button_for_non_zero_payment]== "1" && @check_information.check_amount > 0 ) ||
      @facility.details[:hide_incomplete_button_for_all] == "1" ||
      @job.orbograph_correspondence?(@client.name) || hide_incomplete_button_for_correspondence_check
  end

  def hide_incomplete_button_for_correspondence_check
    @facility.details[:hide_incomplete_button_for_correspondance] == "1" &&
      @check_information.check_amount.to_f.zero? && @check_information.check_number.to_f.zero?
  end

  def make_correspondence_fields_readonly
    @facility.name.to_s.upcase == "SOUTH NASSAU COMMUNITY HOSPITAL"
  end

  def set_class_required
    if not make_correspondence_fields_readonly
      "required"
    end
  end

  def make_nextgen_fields_optional
    if not Client.is_client_orbograph?(@client_name)
      "required"
    end
  end

  def client_specific_amount(check_amount)
    amount = ""    
    amount = check_amount if Client.is_client_orbograph?(@client_name)
    amount
  end

  def get_tabindex(readonly, index)
    if readonly
      ""
    else
      index
    end
  end
  
end
