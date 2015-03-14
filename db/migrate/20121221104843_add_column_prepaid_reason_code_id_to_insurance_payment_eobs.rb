class AddColumnPrepaidReasonCodeIdToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :prepaid_reason_code_id, :integer, :limit => 11
  end
end
