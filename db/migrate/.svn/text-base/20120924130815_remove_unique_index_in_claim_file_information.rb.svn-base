class RemoveUniqueIndexInClaimFileInformation < ActiveRecord::Migration
  def up
    remove_index :claim_file_informations, :name => 'file_header_hash' if index_exists?(:claim_file_informations, :file_header_hash, :name => "file_header_hash")
    remove_index :claim_file_informations, :name => 'file_meta_hash' if index_exists?(:claim_file_informations, :file_meta_hash, :name => "file_meta_hash")
  end

  def down
    add_index :claim_file_informations, :name => 'file_header_hash' if !index_exists?(:claim_file_informations, :file_header_hash, :name => "file_header_hash")
    add_index :claim_file_informations, :name => 'file_meta_hash' if !index_exists?(:claim_file_informations, :file_meta_hash, :name => "file_meta_hash")
  end
end
