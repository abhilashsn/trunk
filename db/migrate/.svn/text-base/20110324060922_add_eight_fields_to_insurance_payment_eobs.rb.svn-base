class AddEightFieldsToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :payer_control_number, :string, :limit => 50
    add_column :insurance_payment_eobs, :marital_status, :string, :limit => 15
    add_column :insurance_payment_eobs, :secondary_plan_code, :string, :limit => 15
    add_column :insurance_payment_eobs, :tertiary_plan_code, :string, :limit => 15
    add_column :insurance_payment_eobs, :state_use_only, :string, :limit => 30
    add_column :insurance_payment_eobs, :fund, :decimal, :precision => 10, :scale => 2 
    add_column :insurance_payment_eobs, :total_retention_fees, :decimal, :precision => 10, :scale => 2
    add_column :insurance_payment_eobs, :total_pbid, :decimal, :precision => 10, :scale => 2
  end

  def down
    remove_column :insurance_payment_eobs, :payer_control_number
    remove_column :insurance_payment_eobs, :marital_status
    remove_column :insurance_payment_eobs, :secondary_plan_code
    remove_column :insurance_payment_eobs, :tertiary_plan_code
    remove_column :insurance_payment_eobs, :state_use_only
    remove_column :insurance_payment_eobs, :fund
    remove_column :insurance_payment_eobs, :total_retention_fees
    remove_column :insurance_payment_eobs, :total_pbid
  end
end
