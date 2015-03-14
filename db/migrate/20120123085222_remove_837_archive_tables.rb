class Remove837ArchiveTables < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.table_exists?(:archived_claim_service_informations)
      drop_table :archived_claim_service_informations
    end
    if ActiveRecord::Base.connection.table_exists?(:archived_claim_informations)
      drop_table :archived_claim_informations
    end    
  end

  def down
    create_table :archived_claim_service_informations
    create_table :archived_claim_informations
  end
end
