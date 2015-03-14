module DatacapturesHelper

   #  The method 'micr_line_information' provides hidden values for micr_line_information to be available in javascript.
  def micr_line_information(micr_line_information)
    unless micr_line_information.blank?
      ret_text = ""
      unless micr_line_information.aba_routing_number.blank?
        ret_text << "<input type = 'hidden' value = '#{micr_line_information.aba_routing_number}' id = 'aba_routing_number'/>"
      end
      unless micr_line_information.payer_account_number.blank?
        ret_text << "<input type = 'hidden' value = '#{micr_line_information.payer_account_number}' id = 'payer_account_number'/>"
      end
      ret_text
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
    text << "<input type = 'hidden' value = '#{facility.details[:cpt_or_revenue_code_mandatory]}' id = 'cpt_or_revenue_code_mandatory'/>"
    text << "<input type = 'hidden' value = '#{facility.details[:reference_code_mandatory]}' id = 'reference_code_mandatory_status'/>"
    text << "<input type = 'hidden' value = '#{facility.details[:reference_code]}' id = 'reference_code_status'/>"
    text << "<input type = 'hidden' value = '#{facility.details[:payment_code]}' id = 'payment_code_status'/>"
    text << "<input type = 'hidden' value = '#{facility.details[:tooth_number]}' id = 'service_tooth_number_status'/>"
    text.html_safe
  end

  # The method creates a hidden field to identify the interest service line.
  # This is to provide client side validation.
  # If the given service line is an interest service line, a hidden field
  # having the DB id of the service line as the field id.
  def interest_service_line?(service)
    if service.interest_service_line?
      text = "<input type = 'hidden' value = #{service.interest_service_line?} id = 'interest_service_line_#{service.id}'/>"
      text.html_safe
    end
  end

  def correspondence_batch(check_information)
    text = "<input type = 'hidden' id = 'correspondence_batch' value = '#{check_information.correspondence?}'>"
    text.html_safe
  end
  
  def get_options_for_criteria criteria
    options_for_select(['All','Text','Errors','ScreenShots', 'Others'], criteria)
  end
end
