class AddColumnsSubcategoryAndSortOrderToFacilityLookupFields < ActiveRecord::Migration
  def up
    add_column :facility_lookup_fields, :sub_category, :string, :limit => 60
    add_column :facility_lookup_fields, :sort_order, :integer, :limit => 11
  end

  def down
    remove_column :facility_lookup_fields, :sub_category
    remove_column :facility_lookup_fields, :sort_order
  end
end
