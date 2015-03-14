class AddColumnFolderNameToFacilityOutputConfigs < ActiveRecord::Migration
  def up
    add_column :facility_output_configs, :folder_name, :string
  end

  def down
    remove_column :facility_output_configs, :folder_name
  end
end
