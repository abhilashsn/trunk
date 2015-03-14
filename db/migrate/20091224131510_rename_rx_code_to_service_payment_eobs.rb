class RenameRxCodeToServicePaymentEobs < ActiveRecord::Migration
  def up
    rename_column :service_payment_eobs, :rx_code, :rx_number
  end

  def down
    rename_column :service_payment_eobs, :rx_code, :rx_number
  end
end
