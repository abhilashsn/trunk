class AddClaimInformationIdAndRemoveClaimInformationsIdToClaimServiceInformations < ActiveRecord::Migration
 def up
   begin
    remove_column :claim_service_informations, :claim_informations_id
    add_column :claim_service_informations, :claim_information_id,  :integer
   rescue
   end
  end

  def down
    remove_column :claim_service_informations, :claim_information_id
    add_column :claim_service_informations, :claim_informations_id,  :integer
  end
  
  def connection
    ClaimInformation.connection
  end
  def connection
    ClaimServiceInformation.connection
  end
end
