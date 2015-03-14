class ChangeTypeOfPatientIdentificationCodeQualifier < ActiveRecord::Migration
  def up
     change_column :insurance_payment_eobs, :patient_identification_code_qualifier,:string,:limit=>20
  end

  def down
    change_column :insurance_payment_eobs, :patient_identification_code_qualifier, :integer ,:limit =>2
  end
end
