class AddByCutAndPayeridToFacilityLookupFields < ActiveRecord::Migration
  def up
    FacilityLookupField.create(:name => "By Cut And Payerid", :lookup_type => "Output Group")
  end

  def down
  end
end
