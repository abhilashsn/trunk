class AddFourFieldsToServicePaymentEobs < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :retention_fees, :decimal, :precision => 10, :scale => 2
    add_column :service_payment_eobs, :line_item_number, :string, :limit => 40
    add_column :service_payment_eobs, :pbid, :decimal, :precision => 10, :scale => 2
    add_column :service_payment_eobs, :payment_status_code, :string, :limit => 15
  end

  def down
    remove_column :service_payment_eobs, :retention_fees
    remove_column :service_payment_eobs, :line_item_number
    remove_column :service_payment_eobs, :pbid
    remove_column :service_payment_eobs, :payment_status_code
  end
end
