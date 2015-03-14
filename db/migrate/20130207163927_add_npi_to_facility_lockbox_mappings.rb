class AddNpiToFacilityLockboxMappings < ActiveRecord::Migration
  def change
    add_column :facility_lockbox_mappings, :npi, :string
  end
end
