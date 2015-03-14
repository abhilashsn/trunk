class AddIndexFileParserTypeToFacilityLookupFields < ActiveRecord::Migration
  def up
    index_file_parser_types = ["BOA", "Apria", "PNC", "Wachovia", "WellsFargo"]
    index_file_parser_types.each do |format|
      FacilityLookupField.create(:name => format, :lookup_type => "Index File Parser Type")
    end
  end

  def down
  end
end
