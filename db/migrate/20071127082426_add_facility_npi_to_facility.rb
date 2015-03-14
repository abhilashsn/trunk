class AddFacilityNpiToFacility < ActiveRecord::Migration
  def up
   
     add_column :facilities,:facility_npi,:string
  end

  def down
    remove_column :facilities,:facility_npi
  end
end
