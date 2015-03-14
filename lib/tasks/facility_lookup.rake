namespace :facility_lookup do
  
  task :fill => :environment do # populates facility lookup with index file parser types
    index_file_parser_types = ["Client-A Type", "Client-B Type", "Client-C Type", "Client-D Type", "Client-E Type", "Client-F Type"]
    index_file_parser_types.each do |parser_type|
      facility_lookup = FacilityLookupField.find(:all, :conditions => {:name => parser_type, :lookup_type => "Index File Parser Type"})
      if facility_lookup.blank?
        FacilityLookupField.create(:name => parser_type, :lookup_type => "Index File Parser Type")
      end
    end
  end

  desc "Inserts the Output Grouping 'By Payer Id' to the Facility Lookup Field"
  task :output_grouping => :environment do
    FacilityLookupField.find_or_create_by_name_and_lookup_type("By Payer Id By Batch","Output Group")
    FacilityLookupField.find_or_create_by_name_and_lookup_type("By Output Payer Id By Batch Date","Output Group")
    FacilityLookupField.find_or_create_by_name_and_lookup_type("Nextgen Grouping","Output Group")
  end

end