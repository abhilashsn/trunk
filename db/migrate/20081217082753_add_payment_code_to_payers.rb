class AddPaymentCodeToPayers < ActiveRecord::Migration
  def up
      add_column :payers,:in_patient_payment_code, :string
      add_column :payers,:out_patient_payment_code, :string
      add_column :payers,:in_patient_allowance_code, :string
      add_column :payers,:out_patient_allowance_code, :string
      add_column :payers,:in_patient_capitation_code, :string
      add_column :payers,:out_patient_capitation_code, :string
      add_column :payers,:in_patient_interest_code, :string
      add_column :payers,:out_patient_interest_code, :string
  end

  def down
  end
end
