class AddClaimServiceInformationIdToServicePaymentEobs < ActiveRecord::Migration
  def up
    add_column :service_payment_eobs, :claim_service_information_id, :integer
  end

  def down
    remove_column :service_payment_eobs, :claim_service_information_id
  end
end
