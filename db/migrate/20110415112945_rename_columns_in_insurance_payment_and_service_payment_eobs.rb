class RenameColumnsInInsurancePaymentAndServicePaymentEobs < ActiveRecord::Migration
  def up
    rename_column :insurance_payment_eobs, :copay_reason_code_mapped_id, :copay_reason_code_id
    rename_column :insurance_payment_eobs, :coinsurance_reason_code_mapped_id, :coinsurance_reason_code_id
    rename_column :insurance_payment_eobs, :contractual_reason_code_mapped_id, :contractual_reason_code_id
    rename_column :insurance_payment_eobs, :deductible_reason_code_mapped_id, :deductible_reason_code_id
    rename_column :insurance_payment_eobs, :denied_reason_code_mapped_id, :denied_reason_code_id
    rename_column :insurance_payment_eobs, :discount_reason_code_mapped_id, :discount_reason_code_id
    rename_column :insurance_payment_eobs, :noncovered_reason_code_mapped_id, :noncovered_reason_code_id
    rename_column :insurance_payment_eobs, :primary_payment_reason_code_mapped_id, :primary_payment_reason_code_id
    rename_column :service_payment_eobs, :copay_reason_code_mapped_id, :copay_reason_code_id
    rename_column :service_payment_eobs, :coinsurance_reason_code_mapped_id, :coinsurance_reason_code_id
    rename_column :service_payment_eobs, :contractual_reason_code_mapped_id, :contractual_reason_code_id
    rename_column :service_payment_eobs, :deductible_reason_code_mapped_id, :deductible_reason_code_id
    rename_column :service_payment_eobs, :denied_reason_code_mapped_id, :denied_reason_code_id
    rename_column :service_payment_eobs, :discount_reason_code_mapped_id, :discount_reason_code_id
    rename_column :service_payment_eobs, :noncovered_reason_code_mapped_id, :noncovered_reason_code_id
    rename_column :service_payment_eobs, :primary_payment_reason_code_mapped_id, :primary_payment_reason_code_id
  end

  def down
    rename_column :insurance_payment_eobs, :copay_reason_code_id, :copay_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :coinsurance_reason_code_id, :coinsurance_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :contractual_reason_code_id, :contractual_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :deductible_reason_code_id, :deductible_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :denied_reason_code_id, :denied_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :discount_reason_code_id, :discount_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :noncovered_reason_code_id, :noncovered_reason_code_mapped_id
    rename_column :insurance_payment_eobs, :primary_payment_reason_code_id, :primary_payment_reason_code_mapped_id
    rename_column :service_payment_eobs, :copay_reason_code_id, :copay_reason_code_mapped_id
    rename_column :service_payment_eobs, :coinsurance_reason_code_id, :coinsurance_reason_code_mapped_id
    rename_column :service_payment_eobs, :contractual_reason_code_id, :contractual_reason_code_mapped_id
    rename_column :service_payment_eobs, :deductible_reason_code_id, :deductible_reason_code_mapped_id
    rename_column :service_payment_eobs, :denied_reason_code_id, :denied_reason_code_mapped_id
    rename_column :service_payment_eobs, :discount_reason_code_id, :discount_reason_code_mapped_id
    rename_column :service_payment_eobs, :noncovered_reason_code_id, :noncovered_reason_code_mapped_id
    rename_column :service_payment_eobs, :primary_payment_reason_code_id, :primary_payment_reason_code_mapped_id
  end
end
