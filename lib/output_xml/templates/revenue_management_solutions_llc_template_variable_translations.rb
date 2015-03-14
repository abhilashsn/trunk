# This module is meant for translating function calls made in Galen clients Templates.
# This module will be dynamically included in the Document class at processing runtime
module OutputXml::RevenueManagementSolutionsLlcTemplateVariableTranslations

  def initialize
    @parent_tag_space = " "*6
    @child_tag_space = " "*8
    @inner_child_space = " "*10
    @inner_most_child_space = " "*12
  end

  def payer_name(check,payer)
    if check.details[:payer_name].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_name_pat_pay = "#{patient.first_name} #{patient.middle_initial} #{patient.last_name}".gsub(/(\s+)/, " ").strip unless patient.blank?
        payer_name = trim(payer_name_pat_pay,60) unless payer_name_pat_pay.blank?
      else
        payer_name = trim(payer.payer,60) unless payer.blank?
      end
      validate_payer_details(check,payer_name)
    else
      return check.details[:payer_name].xmlize
    end
  end


  def reason_code_present_in_array(service_eob)
    if reason_code_present(service_eob)
      copay_reason_code = reson_code_value_remark_grid(service_eob.copay_reason_code_id) unless service_eob.copay_reason_code_id.blank?
      coinsurance_reason_code = reson_code_value_remark_grid(service_eob.coinsurance_reason_code_id) unless service_eob.coinsurance_reason_code_id.blank?
      contractual_reason_code = reson_code_value_remark_grid(service_eob.contractual_reason_code_id) unless service_eob.contractual_reason_code_id.blank?
      deductible_reason_code = reson_code_value_remark_grid(service_eob.deductible_reason_code_id) unless service_eob.deductible_reason_code_id.blank?
      denied_reason_code = reson_code_value_remark_grid(service_eob.denied_reason_code_id) unless service_eob.denied_reason_code_id.blank?
      discount_reason_code = reson_code_value_remark_grid(service_eob.discount_reason_code_id) unless service_eob.discount_reason_code_id.blank?
      noncovered_reason_code = reson_code_value_remark_grid(service_eob.noncovered_reason_code_id) unless service_eob.noncovered_reason_code_id.blank?
      primary_payment_reason_code = reson_code_value_remark_grid(service_eob.primary_payment_reason_code_id) unless service_eob.primary_payment_reason_code_id.blank?
      prepaid_reason_code = reson_code_value_remark_grid(service_eob.prepaid_reason_code_id) unless service_eob.prepaid_reason_code_id.blank?
      if ((!copay_reason_code.blank? && !@reason_code_array.include?(copay_reason_code))||
            (!coinsurance_reason_code.blank? && !@reason_code_array.include?(coinsurance_reason_code))||
            (!contractual_reason_code.blank? && !@reason_code_array.include?(contractual_reason_code))||
            (!deductible_reason_code.blank? && !@reason_code_array.include?(deductible_reason_code))||
            (!denied_reason_code.blank? && !@reason_code_array.include?(denied_reason_code))||
            (!discount_reason_code.blank? && !@reason_code_array.include?(discount_reason_code))||
            (!noncovered_reason_code.blank? && !@reason_code_array.include?(noncovered_reason_code))||
            (!primary_payment_reason_code.blank? && !@reason_code_array.include?(primary_payment_reason_code))||
            (!prepaid_reason_code.blank? && !@reason_code_array.include?(prepaid_reason_code)))
        
        return true
      else
        return false
      end
    end
  end

  def reason_code_present(service_eob)
    if (!service_eob.copay_reason_code_id.blank? ||
          !service_eob.coinsurance_reason_code_id.blank? ||
          !service_eob.contractual_reason_code_id.blank? ||
          !service_eob.deductible_reason_code_id.blank? ||
          !service_eob.denied_reason_code_id.blank? ||
          !service_eob.discount_reason_code_id.blank? ||
          !service_eob.noncovered_reason_code_id.blank? ||
          !service_eob.primary_payment_reason_code_id.blank? ||
          !service_eob.prepaid_reason_code_id.blank? ||
          !service_eob.copay_hipaa_code_id.blank? ||
          !service_eob.coinsurance_hipaa_code_id.blank? ||
          !service_eob.contractual_hipaa_code_id.blank? ||
          !service_eob.deductible_hipaa_code_id.blank? ||
          !service_eob.denied_hipaa_code_id.blank? ||
          !service_eob.discount_hipaa_code_id.blank? ||
          !service_eob.noncovered_hipaa_code_id.blank? ||
          !service_eob.primary_payment_hipaa_code_id.blank? ||
          !service_eob.prepaid_hipaa_code_id.blank?)
      return true
    else
      return false
    end
  end

  def get_provider_adjustment(check)
    job = check.job
    job.get_all_provider_adjustments
  end


  def get_all_provider_adjustments
    ProviderAdjustment.joins(" INNER JOIN jobs ON jobs.id= provider_adjustments.job_id ").where("jobs.id = #{self.id}  OR jobs.parent_job_id=#{self.id}")
  end

  def code_and_description_string(code, description)
    if code.present? && description.present?
      code.strip.upcase + '@@'+description.to_s.strip.upcase
    end
  end


  def reason_code_record_tag(code,page_number,count, code_and_desc_string, service_line_hash = nil)
    @parent_tag_space = " "*10
    @child_tag_space = " "*12
    @inner_child_space = " "*14
    @inner_most_child_space = " "*16
    tag = ""
    service_count=count+1
    unless code.blank?
      if service_line_hash and service_line_hash.has_key?(code_and_desc_string)
        service_count = service_line_hash[code_and_desc_string]
      end
      tag = "<RemarkCode Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag += "<RemarkCodeMap Grid=\"REMARKS\" ServiceLine=\""+service_count.to_s+"\" Zone=\"RemarkDescriptionInRemarkGrid\"/>\n"
      tag += @inner_child_space
      tag += "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_most_child_space
      tag +=  "<TEXTSTRING WORD=\""+code.to_s.xmlize+"\" />\n"
      tag += @inner_child_space
      tag+= "</DataValue>\n"
      tag += @parent_tag_space
      tag+=  "</RemarkCode>"
    end
  end


  def image_name(img_name)
    return img_name.xmlize if img_name
  end

  def service_remark_code_tag(code, description, page_number, code_and_desc_string, service_line_hash = nil)
    unless code.blank?
      @starting_tag_space = " "*8
      @parent_tag_space = " "*10
      @child_tag_space = " "*12
      @inner_child_space = " "*14
      if service_line_hash and service_line_hash.has_key?(code_and_desc_string)
        service_count = service_line_hash[code_and_desc_string]
      end
      service_number = service_count.to_s
      tag = ""
      tag = "<ServiceLine ServiceLineNumber=\""+ service_number +"\" >\n"
      tag += @parent_tag_space
      tag += "<RemarkCode Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag += "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+code.xmlize+"\" />\n"
      tag += @child_tag_space
      tag +=  "</DataValue>\n"
      tag += @parent_tag_space
      tag +=  "</RemarkCode>\n"
      tag += @parent_tag_space
      tag +=  "<RemarkCodeDescription Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\"  ZoneName=\"RemarkDescriptionInRemarkGrid\">\n"
      tag += @child_tag_space
      tag += "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+description.xmlize+"\" />\n"
      tag += @child_tag_space
      tag += "</DataValue>\n"
      tag += @parent_tag_space
      tag +=  "</RemarkCodeDescription>\n"
      tag += @starting_tag_space
      tag += "</ServiceLine>\n"
      tag += @starting_tag_space
    end
  end


  def reson_code_value(reson_code_id)
    reason_code_record = ReasonCode.find(:first,:conditions=>"id = #{reson_code_id}")
    reason_code_record
  end

  def reson_code_value_remark_grid(reson_code_id)
    reason_code_record = reson_code_value(reson_code_id)
    reason_code_record.reason_code.strip.upcase + '@@'+reason_code_record.reason_code_description.to_s.strip.upcase
  end

  def hipaa_code_string(code_id)
    record = HipaaCode.find(code_id)
    record.hipaa_adjustment_code.strip.upcase + '@@'+record.hipaa_code_description.to_s.strip.upcase
  end
  
  def image_type(check)
    @image_type_result = check.job.images_for_jobs.first.transaction_type
    @image_type_result = @image_type_result.gsub(' ', '_') unless @image_type_result.blank?
  end


  def payer_address1(check,payer)
    if check.details[:payer_address1].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_address1 = patient.address_one  unless patient.blank?
      else
        payer_address1 = payer.pay_address_one unless payer.blank?
      end
      validate_payer_details(check,payer_address1)
    else
      return check.details[:payer_address1].xmlize
    end
  end


  def payer_city(check,payer)
    if check.details[:payer_city].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_city = patient.city unless patient.blank?
      else
        payer_city = payer.payer_city unless payer.blank?
      end
      validate_payer_details(check,payer_city)
    else
      return check.details[:payer_city].xmlize
    end
  end

  def payer_state(check,payer)
    if check.details[:payer_state].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_state = patient.state unless patient.blank?
      else
        payer_state = payer.payer_state unless payer.blank?
      end
      validate_payer_details(check,payer_state)
    else
      return check.details[:payer_state].xmlize
    end
  end

  def payer_zip(check,payer)
    if check.details[:payer_zip].rr_blank_or_null?
      if image_type(check) == 'Patient_Pay'
        patient = check.insurance_payment_eobs.first.patients.first
        payer_zip = patient.zip_code unless patient.blank?
      else
        payer_zip = payer.payer_zip unless payer.blank?
      end
      validate_payer_details(check,payer_zip)
    else
      return check.details[:payer_zip].xmlize
    end
  end

  def payer_aba_number(check)
    check.micr_line_information.aba_routing_number.strip.xmlize if check.micr_line_information
  end

  def payer_account_number(check)
    check.micr_line_information.payer_account_number.strip.xmlize if check.micr_line_information
  end

  def rendering_provider_id(check)
    first_eob = check.eobs.first
    first_eob.rendering_provider_identification_number.xmlize if first_eob
  end

  def validate_eob_details(value)
    eob_result = ""
    unless (@image_type_result == "Check_Only" || @image_type_result == "Correspondence")
      eob_result = value
    end
    eob_result.strip if eob_result
  end

  def provider_tin_tag(tax_id,page_number)
    initialize
    tag = ""
    unless tax_id.blank?
      tag += "<ProviderTaxID Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag += "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag +="<TEXTSTRING WORD=\""+tax_id+"\" />\n"
      tag += @child_tag_space
      tag += "</DataValue>\n"
      tag += @parent_tag_space
      tag +="</ProviderTaxID>"
    end
    return tag unless tag.blank?
  end

  def payer_aba_number_tag(aba_number,page_number)
    tag=""
    initialize
    #  aba_number = payer_aba_number(check)
    unless aba_number.blank?
      tag = "<MICRTransitRouting Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag += "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag+= "<TEXTSTRING WORD=\""+aba_number+"\" />\n"
      tag += @child_tag_space
      tag+="</DataValue>\n"
      tag += @parent_tag_space
      tag+="</MICRTransitRouting>"
    end
    return tag unless tag.blank?
  end

  def to_amount
    truncated_amount = self.truncate
    (self == truncated_amount ? truncated_amount : self)
  end

  def rendering_provider_tag(provider_id,page_number)
    tag=""
    initialize
    unless provider_id.blank?
      tag ="<ServicingProviderNumber Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag +=  "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+provider_id+"\" />\n"
      tag += @child_tag_space
      tag+="</DataValue>\n"
      tag += @parent_tag_space
      tag+= "</ServicingProviderNumber>"
    end
    return tag unless tag.blank?
  end

  def provider_npi_tag(provider_npi,page_number)
    tag=""
    initialize
    unless provider_npi.blank?
      tag ="<NationalProviderID Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag +=  "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+provider_npi+"\" />\n"
      tag += @child_tag_space
      tag+="</DataValue>\n"
      tag += @parent_tag_space
      tag+= "</NationalProviderID>"
    end
    return tag unless tag.blank?
  end

  def check_date_tag(check_date,page_number)
    tag=""
    initialize
    unless check_date.blank?
      tag ="<CheckDate Datatype=\"Date\" DateFormat=\"MM/dd/yyyy\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag +=  "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+check_date+"\" />\n"
      tag += @child_tag_space
      tag+="</DataValue>\n"
      tag += @parent_tag_space
      tag+= "</CheckDate>"
    end
    return tag unless tag.blank?
  end

  def check_number_tag(check_number,page_number)
    tag=""
    initialize
    unless check_number.blank?
      tag ="<CheckNumber Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag +=  "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+check_number+"\" />\n"
      tag += @child_tag_space
      tag+="</DataValue>\n"
      tag += @parent_tag_space
      tag+= "</CheckNumber>"
    end
    return tag unless tag.blank?
  end


  def check_amount_tag(check_amount,page_number)
    tag=""
    check_amount = ("%.2f" %(check_amount.to_f))
    initialize
    unless check_amount.blank?
      tag ="<CheckAmount Datatype=\"Money\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag +=  "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag += "<TEXTSTRING WORD=\""+check_amount.to_s+"\" />\n"
      tag += @child_tag_space
      tag+="</DataValue>\n"
      tag += @parent_tag_space
      tag+= "</CheckAmount>"
    end
    return tag unless tag.blank?
  end

 
  def payer_account_number_tag(account_number,page_number)
    tag=""
    initialize
     
    unless account_number.blank?
      tag = "<MICRAccount Datatype=\"String\" LookedUp=\"False\" Page=\""+page_number.to_s+"\">\n"
      tag += @child_tag_space
      tag += "<DataValue Datatype=\"OCRWord\">\n"
      tag += @inner_child_space
      tag +=  "<TEXTSTRING WORD=\""+account_number +"\" />\n"
      tag += @child_tag_space
      tag += "</DataValue>\n"
      tag += @parent_tag_space
      tag += "</MICRAccount>"
    end
    return tag unless tag.blank?
  end



  def provider_tax_id(check)
    first_eob = check.eobs.first
    first_eob.provider_tin.xmlize if first_eob
  end

  def provider_npi(check)
    first_eob = check.eobs.first
    first_eob.provider_npi.xmlize if first_eob
  end

  def check_date(check)
    check.check_date.strftime("%m/%d/%Y") if check.check_date
  end
  
  def check_number(check)
    check.check_number.xmlize
  end

  def check_amount(check)
    check.check_amount
  end

  def check_adjustment_amount(check)
    check.check_adjustment_amount
  end

  def check_level_interest_amount(check)
    check.check_level_interest_amount
  end

  # Method to validate the payer details
  def validate_payer_details(check,payer_info)
    payer_info_result = ""
    payer_name = ""

    payer_name = check.payer.payer unless check.payer.blank?
    unless ((payer_name.strip.upcase == "UNKNOWN"))
      payer_info_result = payer_info
    end
    payer_info_result ? payer_info_result.strip.xmlize : payer_info_result.xmlize
  end
  
  def calculate_pr_adjustments(provider_adjustments)
    @total_pr_adjustment_amount,@total_pr_interest_amount = 0,0
    provider_adjustments.collect{|pr_adjustment| @total_pr_adjustment_amount += pr_adjustment.amount if pr_adjustment.qualifier!= "L6"}
    provider_adjustments.collect{|pr_adjustment| @total_pr_interest_amount += pr_adjustment.amount if pr_adjustment.qualifier== "L6"}
    return @total_pr_adjustment_amount,@total_pr_interest_amount

  end

  def get_rc_service_line(check)
    @ins_eob_records = check.insurance_payment_eobs
    @rc_service_line_hash = {}
    @service_ref_number = 0

    @reason_code_array=[]
    @ins_eob_records.each do|ins_eob|
      ins_eob.service_payment_eobs.each_with_index do|service_eob,counter3|
        adjustment_reasons.each do |adjustment_reason|
          record_string = nil
          if service_eob.send("#{adjustment_reason}_hipaa_code_id").present?
            record_string = hipaa_code_string(service_eob.send("#{adjustment_reason}_hipaa_code_id"))
          elsif service_eob.send("#{adjustment_reason}_reason_code_id").present?
            record_string = reson_code_value_remark_grid(service_eob.send("#{adjustment_reason}_reason_code_id"))
          end
          if record_string.present?
            unless @reason_code_array.include?(record_string)
              @reason_code_array<<record_string
              @service_ref_number = @service_ref_number + 1
              @rc_service_line_hash[record_string] = @service_ref_number
            end
          end
        end
      end
    end
    return @rc_service_line_hash
  end

  def get_formatted_amount(amount)
    return ("%.2f" %(amount.to_f))
  end

  def check_default_date(date)
    return date if date.blank?
    date == "01/01/2000" ? "12/31/1969" : date
  end

  def print_service_level_reason_code_tag(entity, adjustment_reason, page_count, service_index, rc_service_line_values = nil)
    code, description = get_hipaa_and_reason_code_details(entity, adjustment_reason)
    code_desc_string  = code_and_description_string(code, description)
    if code.present? && description.present? && code_desc_string.present?
      reason_code_record_tag(code, page_count, service_index, code_desc_string, rc_service_line_values)
    end
  end

  def print_all_reason_code_tag(entity, adjustment_reason)
    code, description = get_hipaa_and_reason_code_details(entity, adjustment_reason)
    code_desc_string  = code_and_description_string(code, description)
    return code, description, code_desc_string
  end

  def get_hipaa_and_reason_code_details(entity, adjustment_reason)
    code, description = nil, nil
    hipaa_code_id = entity.send("#{adjustment_reason}_hipaa_code_id")
    reason_code_id = entity.send("#{adjustment_reason}_reason_code_id")
    if hipaa_code_id.present?
      record = HipaaCode.find(hipaa_code_id)
      if record
        code = record.hipaa_adjustment_code
        description = record.hipaa_code_description
      end
    elsif reason_code_id.present?
      record = ReasonCode.find(reason_code_id)
      if record
        code = record.reason_code
        description = record.reason_code_description
      end
    end
    return code, description
  end

  def adjustment_reasons
    ['coinsurance', 'contractual', 'copay', 'deductible', 'denied', 'discount',
      'miscellaneous_one', 'miscellaneous_two', 'noncovered', 'primary_payment', 'pr', 'prepaid']
  end

end

