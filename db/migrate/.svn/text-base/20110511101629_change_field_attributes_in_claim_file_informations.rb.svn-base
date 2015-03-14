class ChangeFieldAttributesInClaimFileInformations < ActiveRecord::Migration
  def up
    change_column :claim_file_informations, :size, :float, :default => 0
    change_column :claim_file_informations, :status, :string, :default => "FAILURE"
    change_column :claim_file_informations, :total_claim_count, :integer, :default => 0
    change_column :claim_file_informations, :loaded_claim_count, :integer, :default => 0
    change_column :claim_file_informations, :total_svcline_count, :integer, :default => 0
    change_column :claim_file_informations, :loaded_svcline_count, :integer, :default => 0
  end

  def down
    change_column :claim_file_informations, :size, :float, :default => nil
    change_column :claim_file_informations, :status, :string, :default => nil
    change_column :claim_file_informations, :total_claim_count, :integer, :default => nil
    change_column :claim_file_informations, :loaded_claim_count, :integer, :default => nil
    change_column :claim_file_informations, :total_svcline_count, :integer, :default => nil
    change_column :claim_file_informations, :loaded_svcline_count, :integer, :default => nil
  end
end
