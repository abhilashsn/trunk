class AssociateBatchesInboundFileInformationAndFacilityCutRelationships < ActiveRecord::Migration
  def up
    execute <<-SQL
      ALTER TABLE batches
        ADD CONSTRAINT fk_inbound_file_information_id
        FOREIGN KEY (inbound_file_information_id)
        REFERENCES inbound_file_informations(id)
    SQL

    add_column :inbound_file_informations, :facility_cut_relationship_id, :integer
  end

  def down
    execute "ALTER TABLE batches DROP FOREIGN KEY fk_inbound_file_information_id"
    remove_column :inbound_file_informations, :facility_cut_relationship_id
  end
end
