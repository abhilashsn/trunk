class AddTrmIndexFileFormatToFacilityLookupFields < ActiveRecord::Migration
  def change
     FacilityLookupField.create(:name => "TRM", :lookup_type => "Index File Format")
  end
end
