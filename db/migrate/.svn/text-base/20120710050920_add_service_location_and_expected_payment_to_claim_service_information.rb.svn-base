class AddServiceLocationAndExpectedPaymentToClaimServiceInformation < ActiveRecord::Migration
  def change
    add_column :claim_service_informations, :service_location, :string
    add_column :claim_service_informations, :expected_payment, :decimal, :precision => 10, :scale => 2
  end
  def connection
    ClaimServiceInformation.connection
  end
end
