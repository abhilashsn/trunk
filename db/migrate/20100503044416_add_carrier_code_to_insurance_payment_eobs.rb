class AddCarrierCodeToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :carrier_code, :string
  end

  def down
    remove_column :insurance_payment_eobs, :carrier_code
  end
end
