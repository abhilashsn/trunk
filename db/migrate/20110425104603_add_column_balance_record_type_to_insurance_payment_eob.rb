class AddColumnBalanceRecordTypeToInsurancePaymentEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :balance_record_type, :string, :limit => 25
  end

  def down
    remove_column :insurance_payment_eobs, :balance_record_type
  end
end
