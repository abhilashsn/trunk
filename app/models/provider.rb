class Provider < ActiveRecord::Base
  belongs_to :facility
  def self.provider_name_details(provider_last_name)
    provider_details = {}
    provider = Provider.find(:first,:conditions => "provider_last_name = '#{provider_last_name}' ")
    provider_details["provider_npi_number"] =  provider.provider_npi_number
    provider_details["provider_last_name"] = provider.provider_last_name
    provider_details["provider_first_name"] = provider.provider_first_name
    provider_details["provider_middle_initial"] = provider.provider_middle_initial
    provider_details["provider_suffix"] = provider.provider_suffix
    provider_details["provider_tin_number"] = provider.provider_tin_number
    return provider_details.to_json
  end
  
  def self.save_provider(parsed_file)
    count = 0
    parsed_file.each  do |row|
      provider = self.new
      provider.provider_last_name = row[0]
      provider.provider_first_name = row[1]
      if not (row[2].blank?)
        provider.provider_suffix = row[2]
      end
      if not (row[3].blank?)
        provider.provider_middle_initial = row[3]
      end
      provider.provider_npi_number = row[4]
      provider.provider_tin_number = row[5]
      if (count >= 1)
        facility_id = Facility.find_by_name(row[6]).id
        provider.facility_id = facility_id
        provider.save
      end
      count = count + 1 
    end
  end
  
  def self.provider_details(provider_npi)
    provider_details = nil
    provider = Provider.find(:first,:conditions => "provider_npi_number = '#{provider_npi}' ")
    if provider
      provider_details = {}
      provider_details["provider_npi_number"] =  provider.provider_npi_number
      provider_details["provider_last_name"] = provider.provider_last_name
      provider_details["provider_first_name"] = provider.provider_first_name
      provider_details["provider_middle_initial"] = provider.provider_middle_initial
      provider_details["provider_suffix"] = provider.provider_suffix
      provider_details["provider_tin_number"] = provider.provider_tin_number
    end
    return provider_details.to_json
  end
  
end
