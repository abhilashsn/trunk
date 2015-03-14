module Admin::PayerHelper
  
  def view_select_options(clients)
    html = "<option value=''>--Select--</option>"
    unless clients.blank?
      clients.each {|client|
        html << "<option value='#{client[1]}'>#{client[0]}</option>"
      }      
    end
    html.html_safe
  end

  def select_options(objects)
    html = "<option value=''>--Select--</option>"
    unless objects.blank?
      objects.each {|object|
        html << "<option value='#{object[0]}'>#{object[0]}</option>"
      }
    end
    html.html_safe
  end
  
  def readonly_payid_conditions_for_payer_approval
    (@is_partner_bac || @payer.status == "MAPPED")
  end

  def readonly_payid_conditions_for_payer_administarion
    @is_partner_bac
  end

  def payer_type_list
    payer_type_list = ['', 'Automobile Medical-AM', 'Champus-CH', 'Commercial-CI', 'DMO-17',
      'HMO Medicare Risk-16', 'HMO-HM', 'Medicaid-MC', 'Medicare A-MA',
      'Medicare B-MB', 'POS-13', 'PPO including BCBS-12', 'Veteran Administration plan-VA',
      'Workers Compensation-WC']
    payer_type_list
  end
  
  def hidden_fields_for_onbase_name
    text = "<input type = 'hidden' id = 'serial_numbers_for_adding_onbase_name' name = 'serial_numbers_for_adding_onbase_name' value = ''>"
    text << "<input type = 'hidden' id = 'fac_micr_info_ids_to_delete' name = 'fac_micr_info_ids_to_delete' value = ''>"
    text << "<input type = 'hidden' id = 'onbase_name_client_and_facility_ids' value = '#{@onbase_name_client_and_facility_ids}'>"
    text.html_safe
  end

  def hidden_fields_for_output_payid
    text = "<input type = 'hidden' id = 'serial_numbers_for_adding_output_payid' name = 'serial_numbers_for_adding_output_payid' value = ''>"
    text << "<input type = 'hidden' id = 'fac_payer_info_ids_to_delete_for_output_payid' name = 'fac_payer_info_ids_to_delete_for_output_payid' value = ''>"
    text << "<input type = 'hidden' id = 'output_payid_client_and_facility_ids' value = '#{@output_payid_client_and_facility_ids}'>"
    text.html_safe
  end

  def hidden_fields_for_payment_or_allowance_codes
    text = "<input type = 'hidden' id = 'payment_or_allowance_details_last_serial_num' value = 0>"
    text << "<input type = 'hidden' id = 'facility_ids_for_payment_or_allowance_codes' value = '#{@facilty_ids_of_payment_or_allowance_codes}'>"
    text << "<input type = 'hidden' id = 'serial_numbers_for_adding_payment_or_allowance_codes' name = 'serial_numbers_for_adding_payment_or_allowance_codes' value = ''>"
    text << "<input type = 'hidden' id = 'fac_payer_info_ids_to_delete' name = 'fac_payer_info_ids_to_delete' value = ''>"
    text.html_safe
  end

  def hidden_fields_for_payer
    text = "<input type = 'hidden' id = 'payers_id' value = '#{@payer.id}'>"
    text << "<input type = 'hidden' id = 'payer_status' value = '#{@payer.status}'>"
    text << "<input type = 'hidden' id = 'is_partner_bac' value = '#{@is_partner_bac}'>"
    text.html_safe
  end

  # Returns the color for the legend for new payer list
  def legend_color_new_payer_list
    if @payer_ids_under_processing.include?@new_payer
      color = 'red'
    else
      color = 'white'
    end
    color
  end
end
