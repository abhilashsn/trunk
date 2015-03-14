class LoadNpiAndTin < ActiveRecord::Migration
  def up
    facilities = Facility.find(:all)
    facilities.each {|facility|
      facility_npi_and_tin = FacilitiesNpiAndTin.new
      facility_npi_and_tin.facility_id = facility.id
      facility_npi_and_tin.npi = facility.facility_npi
      facility_npi_and_tin.tin = facility.facility_tin
      facility_npi_and_tin.save!
    }
  end

  def down
  end
end
