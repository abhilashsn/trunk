class AddArchivedClaimHashToInsurancePaymentEob < ActiveRecord::Migration
  def change
    add_column :insurance_payment_eobs, :archived_claim_hash, :string
  end
end
