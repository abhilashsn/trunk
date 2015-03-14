class AddDrgAmountAndContactInformationIdToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :contact_information_id, :integer
    add_column :insurance_payment_eobs, :drg_amount, :decimal, :precision => 9, :scale => 2 
  end

  def down
    remove_column :insurance_payment_eobs, :contact_information_id
    remove_column :insurance_payment_eobs, :drg_amount
  end
end
