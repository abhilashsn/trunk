class AddColumnsAdjustmentHipaaCodeIdsToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :coinsurance_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :contractual_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :copay_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :deductible_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :denied_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :discount_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :miscellaneous_one_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :miscellaneous_two_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :noncovered_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :pr_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :prepaid_hipaa_code_id, :integer
    add_column :insurance_payment_eobs, :primary_payment_hipaa_code_id, :integer
  end
end
