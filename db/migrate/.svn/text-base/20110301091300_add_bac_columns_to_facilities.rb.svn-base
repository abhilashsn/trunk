class AddBacColumnsToFacilities < ActiveRecord::Migration
  def up
    add_column :facilities, :lockbox_location_code, :string, :limit=>5
    add_column :facilities, :lockbox_location_name, :string, :limit=>255
    add_column :facilities, :group_code, :string, :limit=>10
    add_column :facilities, :enable_crosswalk, :boolean
    
  end

  def down
    remove_column :facilities, :lockbox_location_code
    remove_column :facilities, :lockbox_location_name
    remove_column :facilities, :group_code
    remove_column :facilities, :enable_crosswalk
  end
end