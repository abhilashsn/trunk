class AddColumnsForNextgenOutputToFacilityOutputConfigs < ActiveRecord::Migration
  def change
    #add_column :facility_output_configs, :nextgen_folder_name, :string
    add_column :facility_output_configs, :nextgen_file_name, :string
    add_column :facility_output_configs, :nextgen_zip_file_name, :string
  end
end
