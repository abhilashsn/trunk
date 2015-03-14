class AddDataToFacilityLookupFields < ActiveRecord::Migration
  def up
    @index_file_parser_types = ["BOA_bank", "Apria_bank", "PNC_bank", "Wachovia_bank", "WellsFargo_bank"]
    @index_file_parser_types.each do |format|
      FacilityLookupField.create(:name => format, :lookup_type => "Index File Parser Type")
    end
  end

  def down
    @index_file_parser_types.each do |format|
      FacilityLookupField.delete(["name = ? and lookup_type = Index File Parser Type", format])
    end
  end
end
