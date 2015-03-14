class AddDrgAmountToServicePaymentEobs < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :drg_amount, :decimal, :precision => 9, :scale => 2 
  end

  def down
    remove_column :service_payment_eobs, :drg_amount
  end
end
