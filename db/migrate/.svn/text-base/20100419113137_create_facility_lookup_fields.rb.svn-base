class CreateFacilityLookupFields < ActiveRecord::Migration
  def up
    create_table :facility_lookup_fields do |t|
      t.column :name, :string
      t.column :lookup_type, :string
    end
  end

  def down
    drop_table :facility_lookup_fields
  end
end
