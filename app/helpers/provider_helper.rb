module ProviderHelper
  def validations_for_account_number(allow_special_characters, facility_name)
    validations = "changeToCapital(id);"
    if facility_name.upcase == "MOUNT NITTANY MEDICAL CENTER"
      validations << " vallidateMoxpAccountNumber();"
    elsif allow_special_characters.to_s == "true"
      if @is_partner_bac
        validations << " validateData(id, 'Patient Acc#');"
      else
        validations << " validateAlphanumericHyphenPeriodForwardSlash(id);"
      end
    else
      validations << " validateAlphaNumeric(id);"
    end
    
    validations
  end
end
