class ModifyNyuSpecificGroupingInFacilityLookupFields < ActiveRecord::Migration
  def up
    nyu_group = FacilityLookupField.find_by_name("NYU SPECIFIC")
    if nyu_group.lookup_type == "Output Group"
      nyu_group.update_attributes(:name => "CLIENT SPECIFIC")
    end
  end

  def down
    nyu_group = FacilityLookupField.find_by_name("CLIENT SPECIFIC")
    if nyu_group.lookup_type == "Output Group"
      nyu_group.update_attributes(:name => "NYU SPECIFIC")
    end
  end
end
