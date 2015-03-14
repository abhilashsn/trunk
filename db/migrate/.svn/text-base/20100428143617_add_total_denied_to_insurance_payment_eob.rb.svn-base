class AddTotalDeniedToInsurancePaymentEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :total_denied, :decimal, :precision => 10, :scale => 2
  end

  def down
    remove_column :insurance_payment_eobs, :total_denied
  end
end
