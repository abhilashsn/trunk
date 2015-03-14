#Below migration will add the payee details to facility_lockbox_mappings table(Feature #24178 MHXP lockbox defaults & processing)
class AddPayeeDetailsToFacilityLockboxMappings < ActiveRecord::Migration
  def change
    add_column :facility_lockbox_mappings, :payee_name, :string
    add_column :facility_lockbox_mappings, :address_one, :string
    add_column :facility_lockbox_mappings, :city, :string
    add_column :facility_lockbox_mappings, :state, :string
    add_column :facility_lockbox_mappings, :zipcode, :string
  end
end
