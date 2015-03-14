class ChangeCarrierCodeLengthInInsurancePaymentEobs < ActiveRecord::Migration
  def up
    change_column :insurance_payment_eobs, :carrier_code, :string, :limit => 15
  end

  def down
    change_column :insurance_payment_eobs, :carrier_code, :string
  end
end
