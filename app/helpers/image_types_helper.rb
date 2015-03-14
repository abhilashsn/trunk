module ImageTypesHelper
  def validation_on_patient_name
    if @is_partner_bac
      "validateData(id, '')"
    else
      "validatePatientNameField(id, #{@facility.details[:patient_name_format_validation]})"
    end
  end

end