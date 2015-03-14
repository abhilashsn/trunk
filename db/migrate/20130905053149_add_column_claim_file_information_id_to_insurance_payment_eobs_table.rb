class AddColumnClaimFileInformationIdToInsurancePaymentEobsTable < ActiveRecord::Migration
  def change
        add_column :insurance_payment_eobs, :claim_file_information_id, :integer
  end
end
