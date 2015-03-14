class AddProviderNpiToClaimInformations < ActiveRecord::Migration
  def up
     add_column :claim_informations, :provider_npi,:string,:limit =>15
  end

  def down
     remove_column :claim_informations, :provider_npi
  end
  def connection
    ClaimInformation.connection
  end
end
