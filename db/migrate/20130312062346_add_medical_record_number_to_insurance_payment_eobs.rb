class AddMedicalRecordNumberToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :medical_record_number, :string, :limit => 50
  end
end
