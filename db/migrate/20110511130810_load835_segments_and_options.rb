class Load835SegmentsAndOptions < ActiveRecord::Migration
 
  def up
  FacilityLookupField.reset_column_information  
  records = File.open(File.join(File.dirname(__FILE__), "../data/config_835.csv"), "r").read
  records.split("\n").each do |record|
    name, lookup_type, value, category = record.split(',')
    FacilityLookupField.create!(:name => name, :lookup_type => lookup_type, :value=>value, :category=>category.chomp)
  end
  end

  def down
     FacilityLookupField.delete_all("lookup_type like '%835%'")
  end

end
