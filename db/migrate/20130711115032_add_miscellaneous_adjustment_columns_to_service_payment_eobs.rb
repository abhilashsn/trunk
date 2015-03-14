class AddMiscellaneousAdjustmentColumnsToServicePaymentEobs < ActiveRecord::Migration
  def change
    add_column :service_payment_eobs, :miscellaneous_one_adjustment_amount, :decimal,:precision => 10, :scale => 2
    add_column :service_payment_eobs, :miscellaneous_one_reason_code_id, :integer
    add_column :service_payment_eobs, :miscellaneous_two_adjustment_amount, :decimal,:precision => 10, :scale => 2
    add_column :service_payment_eobs, :miscellaneous_two_reason_code_id, :integer
    add_column :service_payment_eobs, :miscellaneous_balance, :decimal,:precision => 10, :scale => 2
  end
end
