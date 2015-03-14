class AddHipaaCodeToFacilityDetails < ActiveRecord::Migration
  def up
    facilities = Facility.all
    facilities.each do |facility|
      client_id = facility.client_id
      client_name = Client.find_by_id(client_id).name
      if client_name.upcase == "MEDASSETS"
        facility.details[:hipaa_code] = false
      elsif client_name.upcase == "MEDISTREAMS"
        facility.details[:hipaa_code] = true
      elsif client_name.upcase == "NAVICURE"
        facility.details[:hipaa_code] = true
      elsif client_name.upcase == "ANODYNE" || client_name.upcase == "AHN"
        facility.details[:hipaa_code] = false
      end
      facility.save!
    end
  end

  def down
  end
end
