class AddTotalExpectedPaymentToInsurancePaymentEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :total_expected_payment, :decimal,:precision => 10, :scale => 2
  end

  def down
    remove_column :insurance_payment_eobs, :total_expected_payment
  end
end
