class AddClaimFromDateClaimToDateInsuraceEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs,:claim_from_date,:date
    add_column :insurance_payment_eobs,:claim_to_date,:date
  end

  def down
    remove_column :insurance_payment_eobs,:claim_from_date
    remove_column :insurance_payment_eobs,:claim_to_date
  end
end
