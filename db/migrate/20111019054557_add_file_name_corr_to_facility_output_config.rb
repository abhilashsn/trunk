class AddFileNameCorrToFacilityOutputConfig < ActiveRecord::Migration
  def change
    add_column :facility_output_configs, :file_name_corr, :string
  end
end
