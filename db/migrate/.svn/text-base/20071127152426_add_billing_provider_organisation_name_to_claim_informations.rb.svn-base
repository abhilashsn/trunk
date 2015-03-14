class AddBillingProviderOrganisationNameToClaimInformations < ActiveRecord::Migration
  def up
    add_column :claim_informations,:billing_provider_organization_name,:string
    add_column :claim_informations,:payer_name,:string
    add_column :claim_informations,:payer_address,:string
    add_column :claim_informations,:payer_city,:string
    add_column :claim_informations,:payer_state,:string,:limit =>3
    add_column :claim_informations,:payer_zipcode,:string
    add_column :claim_informations, :subscriber_first_name, :string ,:limit =>35
    add_column :claim_informations, :subscriber_last_name, :string ,:limit =>30
    add_column :claim_informations, :subscriber_middle_initial, :string ,:limit =>20
    add_column :claim_informations, :subscriber_suffix, :string ,:limit =>20
      
  end

  def down
    remove_column :claim_informations,:billing_provider_organization_name
    remove_column :claim_informations,:payer_name
    remove_column :claim_informations,:payer_address
    remove_column :claim_informations,:payer_city
    remove_column :claim_informations,:payer_state
    remove_column :claim_informations,:payer_zipcode
    remove_column :claim_informations, :subscriber_first_name
    remove_column :claim_informations, :subscriber_last_name
    remove_column :claim_informations, :subscriber_middle_initial
    remove_column :claim_informations, :subscriber_suffix
    

  end
  def connection
    ClaimInformation.connection
  end
end
