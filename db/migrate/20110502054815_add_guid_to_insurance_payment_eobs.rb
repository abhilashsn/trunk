class AddGuidToInsurancePaymentEobs < ActiveRecord::Migration
 def up
    add_column :insurance_payment_eobs, :guid, :string, :limit => 36
  end

  def down
    remove_column :insurance_payment_eobs, :guid
  end
end
