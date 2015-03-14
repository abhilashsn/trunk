class RemoveUnusedFieldsFromPayers < ActiveRecord::Migration
  def up
    remove_column :payers, :in_patient_payment_code
    remove_column :payers, :out_patient_payment_code
    remove_column :payers, :in_patient_allowance_code
    remove_column :payers, :out_patient_allowance_code
    remove_column :payers, :in_patient_capitation_code
    remove_column :payers, :out_patient_capitation_code
    remove_column :payers, :in_patient_interest_code
    remove_column :payers, :out_patient_interest_code
    remove_column :payers, :capitation_code
  end

  def down
    add_column :payers, :in_patient_payment_code, :string
    add_column :payers, :out_patient_payment_code, :string
    add_column :payers, :in_patient_allowance_code, :string
    add_column :payers, :out_patient_allowance_code, :string
    add_column :payers, :in_patient_capitation_code, :string
    add_column :payers, :out_patient_capitation_code, :string
    add_column :payers, :in_patient_interest_code, :string
    add_column :payers, :out_patient_interest_code, :string
    add_column :payers, :capitation_code, :string
  end
end
