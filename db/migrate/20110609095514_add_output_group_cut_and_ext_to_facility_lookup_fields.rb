class AddOutputGroupCutAndExtToFacilityLookupFields < ActiveRecord::Migration
  def up
     FacilityLookupField.create(:name => "By Cut And Extension", :lookup_type => "Output Group")
  end

  def down
  end
end
