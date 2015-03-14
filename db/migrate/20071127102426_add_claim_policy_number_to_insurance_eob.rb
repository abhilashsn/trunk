class AddClaimPolicyNumberToInsuranceEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs,:insurance_policy_number,:string
  end

  def down
    remove_column :insurance_payment_eobs,:insurance_policy_number
  end
end
