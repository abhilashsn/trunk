class AddColumnPayeeTypeFormatToInsurancePaymentEobs < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :payee_type_format, :char, :limit => 1
  end
end
