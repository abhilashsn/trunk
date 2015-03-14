class AddIndexToClaimServiceInformations < ActiveRecord::Migration
  def up
    add_index :claim_service_informations, :claim_information_id  
  end

  def down
    remove_index :claim_service_informations, :claim_information_id 
  end
  def connection
    ClaimServiceInformation.connection
  end
end
