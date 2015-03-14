class AddPrReasonCodeIdToServicePaymentEobs < ActiveRecord::Migration
  def change
    add_column :service_payment_eobs, :pr_reason_code_id, :integer, :limit => 11
  end
end
