class RemoveDrgAmountFromInsurancePaymentEobs < ActiveRecord::Migration
  def up
    remove_column :insurance_payment_eobs, :drg_amount
  end

  def down
    add_column :insurance_payment_eobs, :drg_amount, :decimal, :precision => 9, :scale => 2 
  end
end
