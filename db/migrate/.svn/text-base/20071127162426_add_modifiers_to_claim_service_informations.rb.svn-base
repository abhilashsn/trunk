class AddModifiersToClaimServiceInformations < ActiveRecord::Migration
  def up
    add_column :claim_service_informations, :modifier1, :string,:limit =>2
    add_column :claim_service_informations, :modifier2, :string,:limit =>2
    add_column :claim_service_informations, :modifier3, :string,:limit =>2
    add_column :claim_service_informations, :modifier4, :string,:limit =>2
      
  end

  def down
    remove_column :claim_service_informations, :modifier1
    remove_column :claim_service_informations, :modifier2
    remove_column :claim_service_informations, :modifier3
    remove_column :claim_service_informations, :modifier4
    
  end
  def connection
    ClaimServiceInformation.connection
  end
end
