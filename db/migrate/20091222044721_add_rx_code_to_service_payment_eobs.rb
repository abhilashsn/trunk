class AddRxCodeToServicePaymentEobs < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :rx_code, :string
  end

  def down
    remove_column :service_payment_eobs, :rx_code
  end
end
