class PopulateByLockboxCutToFacilityLookupFields < ActiveRecord::Migration
  def up
    FacilityLookupField.create(:name => "By LockBox Cut", :lookup_type => "Output Group")
  end

  def down
  end
end
