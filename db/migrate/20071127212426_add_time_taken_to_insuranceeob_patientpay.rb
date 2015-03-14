class AddTimeTakenToInsuranceeobPatientpay < ActiveRecord::Migration
  def up
     add_column :insurance_payment_eobs,:time_taken,:string
     add_column :patient_pay_eobs,:time_taken,:string
  end

  def down
    remove_column :insurance_payment_eobs,:time_taken
    remove_column :patient_pay_eobs,:time_taken,:string
  end
end
