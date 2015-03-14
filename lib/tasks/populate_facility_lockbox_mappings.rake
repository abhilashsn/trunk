require 'yaml'
namespace :populate do
  
  desc "Task to populate facility_lockbox_mappings table for facilities"
  task :facility_lockbox_mappings, [:facility] => [:environment] do |t, args|
    facility = Facility.select('id, name').find_by_name(args.facility)
    cnf_file = "#{Rails.root}/lib/yml/#{facility.name.downcase.gsub(' ','_')}_defaults.yml"
    if cnf_file
      default_cnf = YAML::load(File.open("#{Rails.root}/lib/yml/#{facility.name.downcase.gsub(' ','_')}_defaults.yml"))
      default_lockboxes = default_cnf['Lockbox_Array'].split(',')
      facility.facility_lockbox_mappings.where('lockbox_number not in (?)', default_lockboxes).delete_all
      default_lockboxes.each do |lockbox_number|
        lockbox_mapping = FacilityLockboxMapping.find_or_create_by_lockbox_number(lockbox_number)
        lockbox_mapping.payee_name = default_cnf["Lockbox_#{lockbox_number}"]['Facility_Name']
        lockbox_mapping.npi = default_cnf["Lockbox_#{lockbox_number}"]['NPI']
        lockbox_mapping.tin = default_cnf["Lockbox_#{lockbox_number}"]['TIN']
        lockbox_mapping.address_one = default_cnf["Lockbox_#{lockbox_number}"]['Address_one']
        lockbox_mapping.city = default_cnf["Lockbox_#{lockbox_number}"]['City']
        lockbox_mapping.state = default_cnf["Lockbox_#{lockbox_number}"]['State']
        lockbox_mapping.zipcode = default_cnf["Lockbox_#{lockbox_number}"]['Zip_code']
        lockbox_mapping.facility_id = facility.id
        puts lockbox_mapping.save ? lockbox_number : lockbox_mapping.errors
      end
    else
      puts "file #{facility.name.downcase.gsub(' ','_')}_defaults.yml not found"
    end
  end

end

