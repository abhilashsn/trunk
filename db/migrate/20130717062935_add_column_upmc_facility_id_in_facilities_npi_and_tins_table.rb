class AddColumnUpmcFacilityIdInFacilitiesNpiAndTinsTable < ActiveRecord::Migration
  def change
    add_column :facilities_npi_and_tins, :upmc_facility_id, :integer
  end
end
