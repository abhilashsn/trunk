class CreateFacilityLockboxMappings < ActiveRecord::Migration
  def up
  create_table :facility_lockbox_mappings do |t|
  t.column :facility_id, :integer
  t.column :lockbox_number, :string
  t.column :lockbox_name, :string
  t.column :created_at, :datetime
  t.column :updated_at, :datetime
  t.timestamps
  end
  end

  def down
  drop_table :facility_lockbox_mappings
  end
end
