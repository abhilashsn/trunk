class AddColumnQuotesConfigurationToFacilityOutputConfigs < ActiveRecord::Migration
  def up
    add_column :facility_output_configs,:quotes_configuration,:boolean, :default => false
  end

  def down
    remove_column :facility_output_configs,:quotes_configuration
  end
end
