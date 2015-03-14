class AddPatientTypeToInsuraceeobPaymentcodePaymentCodeAllowanceCapitatationToServiceLine < ActiveRecord::Migration
  def up
      add_column :insurance_payment_eobs,:patient_type, :string
      add_column :service_payment_eobs,:inpatient_code, :string
      add_column :service_payment_eobs,:outpatient_code, :string
      
  end

  def down
      remove_column :insurance_payment_eobs,:patient_type
      remove_column :service_payment_eobs,:inpatient_code
      remove_column :service_payment_eobs,:outpatient_code
      
  end
end
