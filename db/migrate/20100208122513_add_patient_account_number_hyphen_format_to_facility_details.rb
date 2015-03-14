class AddPatientAccountNumberHyphenFormatToFacilityDetails < ActiveRecord::Migration
  def up
    facilities = Facility.all
    facilities.each do |facility|
      if facility.name.upcase == "OKLAHOMA CARDIOVASCULAR ASSOC" || facility.name.upcase == "LIBERTY HEALTHCARE PHARMACY"
        facility.details[:patient_account_number_hyphen_format] = true
      end
      facility.save!
    end    
  end

  def down
  end
end
