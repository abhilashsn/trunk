class ChangeExpectedPaymentForServicePaymentEob < ActiveRecord::Migration
  def up
    change_column :service_payment_eobs, :expected_payment, :decimal,:precision => 10, :scale => 2
  end

  def down
    change_column :service_payment_eobs, :expected_payment, :decimal,:precision => 10, :scale => 2
  end
end
