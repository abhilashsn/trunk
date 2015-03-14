class AddOutputFormatCsvAndTxtToFacilityLookupFields < ActiveRecord::Migration
  def up
    FacilityLookupField.create(:name => "CSV", :lookup_type => "Output Format")
    FacilityLookupField.create(:name => "TXT", :lookup_type => "Output Format")    
  end

  def down
  end
end
