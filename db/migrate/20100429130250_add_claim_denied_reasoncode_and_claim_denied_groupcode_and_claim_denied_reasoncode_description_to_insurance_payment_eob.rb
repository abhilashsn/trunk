class AddClaimDeniedReasoncodeAndClaimDeniedGroupcodeAndClaimDeniedReasoncodeDescriptionToInsurancePaymentEob < ActiveRecord::Migration
  def up
    add_column :insurance_payment_eobs, :claim_denied_reasoncode, :string
    add_column :insurance_payment_eobs, :claim_denied_groupcode, :string
    add_column :insurance_payment_eobs, :claim_denied_reasoncode_description, :string
  end

  def down
    remove_column :insurance_payment_eobs, :claim_denied_reasoncode
    remove_column :insurance_payment_eobs, :claim_denied_groupcode
    remove_column :insurance_payment_eobs, :claim_denied_reasoncode_description
  end
end





