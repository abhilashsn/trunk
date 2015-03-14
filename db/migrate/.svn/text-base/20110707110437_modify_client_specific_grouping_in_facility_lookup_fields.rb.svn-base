class ModifyClientSpecificGroupingInFacilityLookupFields < ActiveRecord::Migration
   def up
    client_group = FacilityLookupField.find_by_name("CLIENT SPECIFIC")
    if client_group.lookup_type == "Output Group"
      client_group.update_attributes(:name => "SITE SPECIFIC")
    end
   end

   def down
    client_group = FacilityLookupField.find_by_name("SITE SPECIFIC")
    if client_group.lookup_type == "Output Group"
      client_group.update_attributes(:name => "CLIENT SPECIFIC")
    end
   end
end
