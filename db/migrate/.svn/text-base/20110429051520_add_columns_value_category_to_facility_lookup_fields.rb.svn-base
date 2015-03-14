class AddColumnsValueCategoryToFacilityLookupFields < ActiveRecord::Migration
  def up
    add_column :facility_lookup_fields, :value, :string
    add_column :facility_lookup_fields, :category, :string
  end

  def down
    remove_column :facility_lookup_fields, :value
    remove_column :facility_lookup_fields, :category
  end
end
