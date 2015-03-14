class AddTotalPatientResponsibilityToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :total_patient_responsibility, :decimal, :precision => 10, :scale => 2
  end
end
