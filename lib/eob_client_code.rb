# Responsible for obtaining the EOB specific client code from InsurancePaymentEob EOB and ProviderAdjustment EOB
# This module is included in classes InsurancePaymentEob and ProviderAdjustment to use the method client_code

module EobClientCode

  def get_client_code(facility, batch, payer_type)
    format = nil
    if payer_type == 'PatPay'
      payer_type = 'Patient'
    else
      payer_type = 'Insurance'
    end
    lockbox_number = batch.lockbox.to_s if facility.name == 'HOUSTON MEDICAL CENTER'
    lockbox_number = batch.get_lockbox_number.to_s if facility.name == 'AVITA HEALTH SYSTEMS'
    format ||= payee_type_format if attributes.include?('payee_type_format')
    
    conditions = "facility_id = #{facility.id} AND payer_type = '#{payer_type}'"
    conditions += " AND (payee_type_format = '#{format}' OR payee_type_format is NULL)" if !format.blank?
    conditions += " AND lockbox = '#{lockbox_number}'" if !lockbox_number.blank?

    facility_specific_payees = FacilitySpecificPayee.where(conditions).order("weightage desc")
    compute_client_code(facility_specific_payees, facility)
  end
  
  # Returns the client code, this is a column in the Operation Log
  # Output :
  # client_code : client code 
  def compute_client_code(facility_specific_payees, facility)
    client_code = nil
    unless patient_account_number.blank?
      unless facility_specific_payees.blank?
        facility_specific_payees.each do |payee|
          identifier_index = patient_account_number.upcase.index("#{payee.db_identifier}")
          case payee.match_criteria
          when 'like'
            if identifier_index && identifier_index >= 1
              client_code = payee.xpeditor_client_code
              break
            end
          when 'start_with'
            if identifier_index && identifier_index == 0
              client_code = payee.xpeditor_client_code
              break
            end
          when 'equals'
            if payee.db_identifier == patient_account_number
              client_code = payee.xpeditor_client_code
              break
            end
          when 'length'
            if payee.db_identifier.to_i == patient_account_number.length
              client_code = payee.xpeditor_client_code
              break
            end
          when 'start_with_and_length_8'
            if identifier_index && identifier_index == 0 && patient_account_number.length == 8
              client_code = payee.xpeditor_client_code
              break
            end
          when 'all_numeric'
            if patient_account_number.match(/^[0-9]*$/)
              client_code = payee.xpeditor_client_code
              break
            end
          else
            client_code = payee.xpeditor_client_code
            break
          end
        end
      else
        client_code = facility.sitecode
      end
    end

    client_code
  end

end
