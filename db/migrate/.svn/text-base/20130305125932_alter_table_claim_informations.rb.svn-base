class AlterTableClaimInformations < ActiveRecord::Migration
  def up
    execute "ALTER TABLE claim_informations
             ADD (billing_provider_taxonomy_code varchar(50),
             medical_record_number varchar(50)),
             CHANGE taxonomy_code rendering_provider_taxonomy_code varchar (50)"
  end

  def down
    execute "ALTER TABLE claim_informations
             DROP COLUMN billing_provider_taxonomy_code,
	           DROP COLUMN medical_record_number,
             CHANGE rendering_provider_taxonomy_code taxonomy_code varchar (50)"
  end
  
  def connection
        ClaimInformation.connection
  end
end
