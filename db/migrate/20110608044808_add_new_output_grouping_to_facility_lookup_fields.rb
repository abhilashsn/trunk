class AddNewOutputGroupingToFacilityLookupFields < ActiveRecord::Migration
  def up
    change_payer_values = FacilityLookupField.find_all_by_name("By Payer")
    change_payer_id_values = FacilityLookupField.find_all_by_name("By Payer Id")

    change_payer_values.each do |change_payer_value|
      if change_payer_value.lookup_type == "Output Group"
        change_payer_value.update_attributes(:name => "By Payer By Batch")
      end
    end
    change_payer_id_values.each do |change_payer_value|
      if change_payer_value.lookup_type == "Output Group"
        change_payer_value.update_attributes(:name => "By Payer Id By Batch")
      end
    end

    new_facility_output_groups = ["By Payer By Batch Date", "By Payer Id By Batch Date"]
    new_facility_output_groups.each do |group|
      FacilityLookupField.create(:name => group, :lookup_type => "Output Group")
      FacilityLookupField.create(:name => group, :lookup_type => "Supplemental Output Group")
    end
  end

  def down

    change_payer_values = FacilityLookupField.find_all_by_name("By Payer By Batch")
    change_payer_id_values = FacilityLookupField.find_all_by_name("By Payer Id By Batch")

    change_payer_values.each do |change_payer_value|
      if change_payer_value.lookup_type == "Output Group"
        change_payer_value.update_attributes(:name => "By Payer")
      end
    end
    change_payer_id_values.each do |change_payer_value|
      if change_payer_value.lookup_type == "Output Group"
        change_payer_value.update_attributes(:name => "By Payer Id")
      end

    end

    new_facility_output_groups = ["By Payer By Batch Date", "By Payer Id By Batch Date"]
    new_facility_output_groups.each do |group|
      output_group = FacilityLookupField.find_by_name_and_lookup_type("group","Output Group")
      supplemental_output_group = FacilityLookupField.find_by_name_and_lookup_type("group","Supplemental Output Group")
      output_group.delete unless output_group.blank?
      supplemental_output_group.delete unless supplemental_output_group.blank?
    end
  end
end
