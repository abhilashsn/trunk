class AddStartTimeEndTimeToInsurancePatietpayeob < ActiveRecord::Migration
  def up
    remove_column :insurance_payment_eobs,:time_taken
    remove_column :patient_pay_eobs,:time_taken
    add_column :insurance_payment_eobs,:start_time,:datetime
    add_column :insurance_payment_eobs,:end_time,:datetime
    add_column :patient_pay_eobs,:start_time,:datetime
    add_column :patient_pay_eobs,:end_time,:datetime
  end

  def down
    remove_column :insurance_payment_eobs,:start_time
    remove_column :insurance_payment_eobs,:end_time
    remove_column :patient_pay_eobs,:start_time
    remove_column :patient_pay_eobs,:end_time
  end
end
