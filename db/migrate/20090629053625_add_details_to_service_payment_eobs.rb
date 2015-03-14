class AddDetailsToServicePaymentEobs < ActiveRecord::Migration
  def up
    begin
    add_column :service_payment_eobs, :details, :text
    rescue
    end
  end

  def down
    remove_column :service_payment_eobs, :details
  end
end
