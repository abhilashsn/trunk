class AddAccountTypeToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :account_type, :string
  end
end
