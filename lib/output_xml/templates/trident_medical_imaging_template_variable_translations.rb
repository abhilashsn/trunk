# This module is meant for translating function calls made in Trident Template.
# This module will be dynamically included in the Document class at processing runtime
module OutputXml::TridentMedicalImagingTemplateVariableTranslations

  #Batch related translations
  def npi
    @image_type_result = ""
    npi = ""
    npi = facility.facility_npi.strip if facility.facility_npi
    @batch.details[:provider_id].rr_blank_or_null? ?  npi : @batch.details[:provider_id]
  end

  def group_id
    @batch.details[:group_id].rr_blank_or_null? ? "TRIDENT" : @batch.details[:group_id]
  end

  def interchange_sender_id
    @batch.details[:interchange_sender_id].rr_blank_or_null? ? "MEDISTREAMS" : @batch.details[:interchange_sender_id]
  end

  
  def interchange_receiver_id
    @batch.details[:interchange_receiver_id].rr_blank_or_null? ? "TRIDENT" : @batch.details[:interchange_receiver_id]
  end
  def group_sender_id
    @batch.details[:group_sender_id].rr_blank_or_null? ? "MEDISTREAMS" : @batch.details[:group_sender_id]
  end
  def group_receiver_id
    @batch.details[:group_receiver_id].rr_blank_or_null? ? "TRIDENT" : @batch.details[:group_receiver_id]
  end
  def transaction_control_number (counter)
    ((counter+1).to_s.rjust(4,'0')).to_s
  end

  def image_type(check)
    @image_type_result = check.job.images_for_jobs.first.transaction_type
    @image_type_result = @image_type_result.gsub(' ', '_') unless @image_type_result.blank?
  end

  # Check related translations
  def payment_method(check)
    if (@image_type_result == "Missing_Check" || @image_type_result == "Correspondence" ||
          ((@image_type_result == "Complete_EOB" || @image_type_result == "Patient_Pay") && check.check_date.to_s == '2000-01-01' &&
            check.check_number.to_i == 0 && check.check_amount == 0.00))
      "NON"
      # Medistreams validation rules implementation. Ticket # 8390

      # The payment method is always CHK other than Missing check and Correspondence image type but
      # just to ensure that the validation - 'CHK' for image type Check_Only must not be missed during
      # future implementations, the below mentioned logic is added
    elsif (@image_type_result == "Check_Only" || (@image_type_result == "Complete_EOB" && check.check_amount > 0))
      "CHK"
    else
      "CHK"
    end
  end

  def check_ABA_number(check)
    check.micr_line_information.aba_routing_number.strip if check.micr_line_information
  end

  def transaction_id(check)
    check.transaction_id.strip unless check.transaction_id.blank?
  end

  def check_account_number(check)
    check.micr_line_information.payer_account_number.strip if check.micr_line_information
  end

  def payer_name(check)
    if check.details[:payer_name].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_name_pat_pay = "#{patient.first_name} #{patient.middle_initial} #{patient.last_name}".gsub(/(\s+)/, " ").strip unless patient.blank?
        payer_name = trim(payer_name_pat_pay,60) unless payer_name_pat_pay.blank?
      else
        payer_name = trim(check.payer.payer,60) unless check.payer.blank?
      end
      validate_payer_details(check, payer_name)
    else
      return check.details[:payer_name]
    end
  end

  def payer_address1(check)
    if check.details[:payer_address1].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_address1 = patient.address_one  unless patient.blank?
      else
        payer_address1 = check.payer.pay_address_one unless check.payer.blank?
      end
      validate_payer_details(check, payer_address1)
    else
      return check.details[:payer_address1]
    end
  end

  def payer_address2(check)
    if check.details[:payer_address2].rr_blank_or_null?
      payer_address2 = ""
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_address2 = patient.address_two unless patient.blank?
      else
        unless check.payer.blank?
          unless check.payer.pay_address_two == "NOT PROVIDED"
            payer_address2 = check.payer.pay_address_two
          end
        end
      end
      validate_payer_details(check, payer_address2)
    else
      return check.details[:payer_address2]
    end
  end
  
  def payer_city(check)
    if check.details[:payer_city].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_city = patient.city unless patient.blank?
      else
        payer_city = check.payer.payer_city unless check.payer.blank?
      end
      validate_payer_details(check, payer_city)
    else
      return check.details[:payer_city]
    end
  end
  
  def payer_state(check)
    if check.details[:payer_state].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_state = patient.state unless patient.blank?
      else
        payer_state = check.payer.payer_state unless check.payer.blank?
      end
      validate_payer_details(check, payer_state)
    else
      return check.details[:payer_state]
    end
  end


  def payer_zip(check)
    if check.details[:payer_zip].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_zip = patient.zip_code unless patient.blank?
      else
        payer_zip = check.payer.payer_zip unless check.payer.blank?
      end
      validate_payer_details(check, payer_zip)
    else
      return check.details[:payer_zip]
    end
  end

  def payer_id(check)
    if check.details[:chk_payer_id].rr_blank_or_null?
      payer_id = check.payer.supply_payid unless check.payer.blank?
      validate_payer_details(check, payer_id)
    else
      return check.details[:chk_payer_id]
    end
  end

  def payer_tax_id(check)
    if check.details[:payer_tax_id].rr_blank_or_null?
      facility = check.job.batch.facility
      if !check.payer.blank? && !check.payer.payer_tin.blank?
        payer_tax_id = check.payer.payer_tin
      else
        if image_type(check) == 'Patient_Pay'
          if (!facility.default_patpay_payer_tin.blank? && facility.details[:payer_tin] )
            payer_tax_id = facility.default_patpay_payer_tin
          end
        else
          if (!facility.default_insurance_payer_tin.blank? && facility.details[:payer_tin] )
            payer_tax_id = facility.default_insurance_payer_tin
          end
        end
      end
      validate_payer_details(check, payer_tax_id)
    else
      return check.details[:payer_tax_id]
    end
  end

  def payee_name
    @batch.details[:payee_name].rr_blank_or_null? ? @facility.name : @batch.details[:payee_name]
  end
  def payee_id
    @batch.details[:payee_id].rr_blank_or_null? ? @facility.facility_npi : @batch.details[:payee_id]
  end
  def payee_address_one
    @batch.details[:payee_address1].rr_blank_or_null? ? @facility.address_one : @batch.details[:payee_address1]
  end

  def payee_address_two
    @batch.details[:payee_address2].rr_blank_or_null? ? @facility.address_two : @batch.details[:payee_address2]
  end

  def payee_city
    @batch.details[:payee_city].rr_blank_or_null? ? @facility.city : @batch.details[:payee_city]
  end

  def payee_state
    @batch.details[:payee_state].rr_blank_or_null? ? @facility.state : @batch.details[:payee_state]
  end

  def payee_zip
    @batch.details[:payee_zip].rr_blank_or_null? ? @facility.zip_code : @batch.details[:payee_zip]
  end

  def check_date(check)
    unless check.details[:chk_date].rr_blank_or_null?
      return check.details[:chk_date]
    end
    check_date_result = ""
    check_date = check.check_date.strftime("%m/%d/%Y") unless check.check_date.blank?
    if @image_type_result == "Missing_Check"
      unless check_date == "01/01/2000"
        check_date_result = check_date
      end
    else
      check_date_result = check_date
    end
    check_date_result
  end
  
  def check_number(check)
    amount = ""
    check_number_result = ""
    total_payment = InsurancePaymentEob.find(:all,:conditions => "check_information_id = #{check.id}",:select => "sum(total_amount_paid_for_claim) amout",:group => "check_information_id")
    if !total_payment.blank?
      total_payment.each do |total|
        amount = total.amout
      end
    else
      amount = ""
    end
    if @image_type_result == "Missing_Check"
      unless check.check_number.to_s == "0"
        check_number_result = check.check_number
      end
      #elsif (@image_type_result == "Complete_EOB" && check.insurance_payment_eobs.first.claim_type == "Denial")
    elsif (@image_type_result == "Complete_EOB" && check.check_number.scan( /\w/ ).uniq.join == "0" && check.check_amount == 0 && amount == "0.00" )
      check_number_result = "000000000"
    else
      check_number_result = check.check_number
    end
    check_number_result
  end

  def check_amount(check)
    check_amount_result = ""
    if @image_type_result == "Missing_Check"
      unless check.check_amount == 0
        check_amount_result = number_precision(check.check_amount,:precision => 2)
      end
    else
      check_amount_result = number_precision(check.check_amount,:precision => 2)
    end
    check_amount_result
  end

  # Method to validate the payer details
  def validate_payer_details(check,payer_info)
    payer_info_result = ""
    payer_name = ""
    
    payer_name = check.payer.payer unless check.payer.blank?
    unless ((payer_name.strip.upcase == "UNKNOWN"))
      payer_info_result = payer_info
    end
    payer_info_result.strip if  payer_info_result
  end
  
  def total_charges_and_interest(check)
    total_charges = 0
    total_interest = 0
    check.insurance_payment_eobs.each do |eob|
      total_charges = total_charges + eob.total_submitted_charge_for_claim unless eob.total_submitted_charge_for_claim.blank?
      total_interest = total_interest + eob.claim_interest unless eob.claim_interest.blank?
    end
    total_charges = nil if total_charges == 0
    total_interest = nil if total_interest == 0
    return total_charges, total_interest
  end

  #Insurance EOB related translations
  # Method to check if the EOB level input value is default based on image type. If default value, the value is replaced with null
  def validate_eob_details(value)
    eob_result = ""
    unless (@image_type_result == "Check_Only" || @image_type_result == "Correspondence")
      eob_result = value
    end
    eob_result.strip if eob_result
  end

  def total_claim_charges(ins_eob)
    number_precision(ins_eob.total_submitted_charge_for_claim,:precision => 2)
  end

  def total_claim_payment(ins_eob)
    number_precision(ins_eob.total_amount_paid_for_claim,:precision => 2)
  end

  def patient_id(ins_eob)
    patient_id = ""
    if ins_eob.patient_identification_code_qualifier == "HIC"
      patient_id = ins_eob.patient_identification_code
    end
    patient_id
  end

  def patient_responsibility_amount(ins_eob)
    patient_responsibility = ins_eob.total_deductible + ins_eob.total_co_pay + ins_eob.total_co_insurance rescue nil
    patient_responsibility
  end

  def social_security_number(ins_eob)
    ss_number_string = ""
    if ins_eob.patient_identification_code_qualifier == "SSN"
      ss_number_string = "\n				<SocialSecurityNumber>#{ins_eob.patient_identification_code}</SocialSecurityNumber>"
    end
    ss_number_string
  end

  def claim_from_date(ins_eob)
    ins_eob.claim_from_date.strftime("%m/%d/%Y") unless ins_eob.claim_from_date.blank?
  end

  def claim_to_date(ins_eob)
    ins_eob.claim_to_date.strftime("%m/%d/%Y") unless ins_eob.claim_to_date.blank?
  end

  #Service payment related translations
  def line_item_charges(service)
    number_precision(service.service_procedure_charge_amount,:precision => 2)
  end

  def line_item_payment(service)
    number_precision(service.service_paid_amount,:precision => 2)
  end

  def service_line_from_date(service)
    service.date_of_service_from.strftime("%m/%d/%Y") unless service.date_of_service_from.blank?
  end

  def service_line_to_date(service)
    service.date_of_service_to.strftime("%m/%d/%Y") unless service.date_of_service_to.blank?
  end

  def line_item_allowed_amount(service)
    number_precision(service.service_allowable,:precision => 2)
  end

  def mapped_code(crosswalked_codes)
    mapped_code = crosswalked_codes[:cas_02]
    if mapped_code.blank? && !crosswalked_codes[:all_reason_codes].blank?
      rc_and_desc = crosswalked_codes[:all_reason_codes].first
      if !rc_and_desc.blank?
        mapped_code = rc_and_desc[0]
      end
    end
    mapped_code
  end

  #method to get late filing charge 
  def claim_level_adjustment_amount(ins_eob)
    number_precision(ins_eob.late_filing_charge,:precision => 2)
  end
  
  def claim_level_adjustment_group_code(ins_eob)
    code =  'CO' if !(ins_eob.late_filing_charge.blank?)
  end
  
  def claim_level_adjustment_reason_code(ins_eob)
    code =  'B4' if !(ins_eob.late_filing_charge.blank?) 
  end
  
  # Restrict users from capturing any special characters other than the below mentioned in the RC description.
  # Valid RC Description - Required Alphabets, numeric, periods, hyphen(-), space ,
  # comma(,), slash(/), ')', '('and underscore(_).
  # RC Description length should be 255 characters only.
  
  def format_reason_code_description(reason_code_description)
    if !reason_code_description.match(/^[A-Za-z0-9\-\.\_\s\,\/\)\(]*$/)
      reason_code_description = reason_code_description.gsub(/[^A-Za-z0-9\-\.\_\s\,\/\)\(]/, "")
    end
    reason_code_description[0..254]
  end
  
  private
  def number_precision(number, *args)
    options = args.extract_options!
    options.symbolize_keys!
    defaults           = I18n.translate('number.format''number.format', :locale => options[:locale], :raise => true) rescue {}
    precision_defaults = I18n.translate('number.precision.format''number.precision.format', :locale => options[:locale],
      :raise => true) rescue {}
    defaults           = defaults.merge(precision_defaults)
    unless args.empty?
      ActiveSupport::Deprecation.warn('number_with_precision takes an option hash ' +
          'instead of a separate precision argument.', caller)
    end
    precision ||= (options[:precision] )
    begin
      rounded_number = (Float(number) * (10 ** precision)).round.to_f / 10 ** precision
      ("%01.#{precision}f" % rounded_number
      )
    rescue
      number
    end
  end
end

