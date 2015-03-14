class AddSingleDailyMergedCutToFacilityLookupFields < ActiveRecord::Migration
  def up
    FacilityLookupField.create(:name => "Single Daily Merged Cut", :lookup_type => "Output Group")
  end

  def down
  end
end
