class AddAlternatePayerNameToInsurancePaymentEob < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs,:alternate_payer_name, :string
  end
end
