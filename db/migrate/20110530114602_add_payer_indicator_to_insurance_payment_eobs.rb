class AddPayerIndicatorToInsurancePaymentEobs < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :payer_indicator, :string, :limit => 10
  end

  def down
    remove_column :insurance_payment_eobs, :payer_indicator
  end
end
