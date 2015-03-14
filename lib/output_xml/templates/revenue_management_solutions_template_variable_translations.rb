# To change this template, choose Tools | Templates
# and open the template in the editor.

module OutputXml::RevenueManagementSolutionsTemplateVariableTranslations
  def priority(check)
    check.batch.meta_batch_information.priority
  end
   
  def due_time(check)
    check.batch.meta_batch_information.due_time.strftime("%Y-%m-%d %H:%M:%S")
  end

  def provider_id(check)
    check.batch.meta_batch_information.provider_code
  end

  def image_name(check)
    check.job.initial_image_name
  end

  def pages(check)
    check.job.pages_to
  end

  
  def image_type(check)
    @image_type_result = check.job.images_for_jobs.first.transaction_type
    @image_type_result = @image_type_result.gsub(' ', '_') unless @image_type_result.blank?
  end
  
  def payer_name(check)
    if image_type(check) == 'Patient_Pay'
      patient = check.insurance_payment_eobs.first.patients.first
      payer_name_pat_pay = "#{patient.first_name} #{patient.middle_initial} #{patient.last_name}".gsub(/(\s+)/, " ").strip unless patient.blank?
      payer_name = trim(payer_name_pat_pay,60) unless payer_name_pat_pay.blank?
    else
      payer_name = trim(check.payer.payer,60) unless check.payer.blank?
    end
    validate_payer_details(check,payer_name)
  end

  def payer_address1(check)
    if image_type(check) == 'Patient_Pay'
      patient = check.insurance_payment_eobs.first.patients.first
      payer_address1 = patient.address_one  unless patient.blank?
    else
      payer_address1 = check.payer.pay_address_one unless check.payer.blank?
    end
    validate_payer_details(check,payer_address1)
  end

  def payer_address2(check)
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
    validate_payer_details(check,payer_address2)
  end

  def payer_city(check)
    if image_type(check) == 'Patient_Pay'
      patient = check.insurance_payment_eobs.first.patients.first
      payer_city = patient.city unless patient.blank?
    else
      payer_city = check.payer.payer_city unless check.payer.blank?
    end
    validate_payer_details(check,payer_city)
  end

  def payer_state(check)
    if image_type(check) == 'Patient_Pay'
      patient = check.insurance_payment_eobs.first.patients.first
      payer_state = patient.state unless patient.blank?
    else
      payer_state = check.payer.payer_state unless check.payer.blank?
    end
    validate_payer_details(check,payer_state)
  end

  def payer_zip(check)
    if image_type(check) == 'Patient_Pay'
      patient = check.insurance_payment_eobs.first.patients.first
      payer_zip = patient.zip_code unless patient.blank?
    else
      payer_zip = check.payer.payer_zip unless check.payer.blank?
    end
    validate_payer_details(check,payer_zip)
  end

  #provider details
  def provider_name(check)
    ins_eob = check.insurance_payment_eobs.first
    provider_name = "#{ins_eob.rendering_provider_first_name} #{ins_eob.rendering_provider_middle_initial} #{ins_eob.rendering_provider_last_name}".gsub(/(\s+)/, " ").strip unless ins_eob.blank?
  end

  def provider_address1(check)
    provider = check.insurance_payment_eobs.first.contact_information
    provider.address_line_one
  end

  def provider_address2(check)
    provider_address2 = ""
    provider = check.insurance_payment_eobs.first.contact_information
    provider_address2 = provider.address_line_two if provider.address_line_two
    provider_address2
  end

  def provider_city(check)
    provider = check.insurance_payment_eobs.first.contact_information
    provider.city
  end

  def provider_state(check)
    provider = check.insurance_payment_eobs.first.contact_information
    provider.state
  end

  def provider_zip(check)
    provider = check.insurance_payment_eobs.first.contact_information
    provider.zip
  end

  def remark_code(remark)
    code = ""
    code = remark.adjustment_code
    code
  end

  def remark_description(remark)
    description = ""
    description = remark.adjustment_code_description
    description
  end


  # Method to validate the payer details
  def validate_payer_details(check,payer_info)
    payer_info_result = ""
    payer_name = ""
    payer_name = check.payer.payer unless check.payer.blank?
    unless ((payer_name.strip.upcase == "UNKNOWN"))
      payer_info_result = payer_info
    end
    payer_info_result ? payer_info_result.strip : payer_info_result
  end

  def count(checks)
    checks.length
  end

  def doc_type(check)
    check.batch.meta_batch_information.document_format.strip
  end

  def service_from_date(service_eob)
    service_eob.date_of_service_from.strftime("%Y%m%d")
  end

  def check_date(check)
    check.check_date.strftime("%Y%m%d")
  end

  def check_number(check)
    check.check_number.strip
  end

  def check_amount(check)
    check.check_amount
  end

  def transaction_control_number(counter)
    (counter+1)
  end
  
end
