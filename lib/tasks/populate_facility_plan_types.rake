namespace :populate do

  desc "Task to populate facility_lockbox_mappings table for facilities"
  task :default_facility_plan_types => [:environment] do |t, args|
    Facility.all.each do |facility|
      facility.details[:default_plan_type] = 'ZZ'
      facility.save
    end
    puts "All the facilities are given defalut plan type as 'ZZ'"
  end

end
