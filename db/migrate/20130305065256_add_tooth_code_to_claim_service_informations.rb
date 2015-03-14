class AddToothCodeToClaimServiceInformations < ActiveRecord::Migration
  def up
    execute "ALTER TABLE claim_service_informations
             ADD tooth_code varchar(50)"
  end

  def down
    execute "ALTER TABLE claim_service_informations
             DROP COLUMN tooth_code"
  end
  
  def connection
        ClaimInformation.connection
  end
  
end
