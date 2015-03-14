class AddFieldsToClaimFileInformations < ActiveRecord::Migration
  def up
    if !ClaimFileInformation.column_names.include?"claim_file_type"
     add_column :claim_file_informations, :claim_file_type, :string, :limit => 50
    end
    if ClaimFileInformation.column_names.include?"file_837_name"
     rename_column :claim_file_informations, :file_837_name, :name
    end
  end

  def down
    remove_column :claim_file_informations, :claim_file_type
    rename_column :claim_file_informations, :name, :file_837_name
  end
end
