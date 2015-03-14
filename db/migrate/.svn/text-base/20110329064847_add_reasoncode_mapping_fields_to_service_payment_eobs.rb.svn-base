class AddReasoncodeMappingFieldsToServicePaymentEobs < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :copay_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :coinsurance_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :contractual_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :deductible_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :denied_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :discount_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :noncovered_reason_code_mapped_id, :integer, :limit => 11
    add_column :service_payment_eobs, :primary_payment_reason_code_mapped_id, :integer, :limit => 11
  end

  def down
    remove_column :service_payment_eobs, :copay_reason_code_mapped_id
    remove_column :service_payment_eobs, :coinsurance_reason_code_mapped_id
    remove_column :service_payment_eobs, :contractual_reason_code_mapped_id
    remove_column :service_payment_eobs, :deductible_reason_code_mapped_id
    remove_column :service_payment_eobs, :denied_reason_code_mapped_id
    remove_column :service_payment_eobs, :discount_reason_code_mapped_id
    remove_column :service_payment_eobs, :noncovered_reason_code_mapped_id
    remove_column :service_payment_eobs, :primary_payment_reason_code_mapped_id
  end
end
