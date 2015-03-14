class AddDeletedToClaimFileInformation < ActiveRecord::Migration
  def change
    add_column :claim_file_informations, :deleted, :integer, :default => 0
  end
end
