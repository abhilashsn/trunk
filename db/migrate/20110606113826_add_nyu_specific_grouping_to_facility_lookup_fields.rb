class AddNyuSpecificGroupingToFacilityLookupFields < ActiveRecord::Migration
  def up
    FacilityLookupField.create(:name => "NYU SPECIFIC", :lookup_type => "Output Group")
  end

  def down
  end
end
