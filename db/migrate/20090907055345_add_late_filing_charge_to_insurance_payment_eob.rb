class AddLateFilingChargeToInsurancePaymentEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs,:late_filing_charge ,:decimal,:precision => 10, :scale => 2
  end

  def down
    remove_column :insurance_payment_eobs,:late_filing_charge
  end
end

