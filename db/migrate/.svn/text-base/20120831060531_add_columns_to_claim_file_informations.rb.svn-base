class AddColumnsToClaimFileInformations < ActiveRecord::Migration
  def up
    attributes = ["file_header_hash", "file_meta_hash","file_interchange_date","file_interchange_time","client_id"]
    if !(attributes - ClaimFileInformation.column_names).empty?
      execute "ALTER TABLE claim_file_informations
     ADD (file_header_hash  VARCHAR(255),
          file_meta_hash  VARCHAR(255),
          file_interchange_date DATE,
          client_id INT(11),
          file_interchange_time TIME),
      ADD UNIQUE INDEX (file_header_hash),
      ADD UNIQUE INDEX (file_meta_hash);"
    end
  end

  def down
    execute "ALTER TABLE claim_file_informations
      DROP INDEX file_header_hash, DROP INDEX file_meta_hash,
      DROP COLUMN file_header_hash, DROP COLUMN file_meta_hash, 
      DROP COLUMN file_interchange_date,DROP COLUMN file_interchange_time,
      DROP COLUMN  client_id;"
  end  
end
