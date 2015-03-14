class PopulateFacilityLookupField < ActiveRecord::Migration
  def up
    image_file_formats = ["TIFF", "JPG", "PDF"]
    index_file_formats = ["CSV", "DAT", "BAK", "XML", "TXT", "Other"]
    claim_file_parsers = ["Standard", "Custom"]
    patient_pay_formats = ["Nextgen Format", "Simplified Format"]
    output_groups = ["By Batch Date", "By Batch", "By Payer", "By Check"]
    output_formats = ["835", "XML", "Delimited", "NSF"]
    image_file_formats.each do |format|
      FacilityLookupField.create(:name => format, :lookup_type => "Image File Format")
    end    
    index_file_formats.each do |format|
      FacilityLookupField.create(:name => format, :lookup_type => "Index File Format")
    end    
    claim_file_parsers.each do |parser|
      FacilityLookupField.create(:name => parser, :lookup_type => "Claim File Parser")
    end    
    patient_pay_formats.each do |format|
      FacilityLookupField.create(:name => format, :lookup_type => "Patient Pay Format")
    end    
    output_groups.each do |group|
      FacilityLookupField.create(:name => group, :lookup_type => "Output Group")
    end    
    output_formats.each do |format|
      FacilityLookupField.create(:name => format, :lookup_type => "Output Format")
    end
  end

  def down
  end
end
