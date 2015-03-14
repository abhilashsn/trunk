require 'csv'

namespace :one_time_rakes do

  desc "Task to initialize UPMC client with transaction count"
  task :initialize_transaction_count_for_upmc => [:environment] do |t, args|
    client = Client.find_by_name('UNIVERSITY OF PITTSBURGH MEDICAL CENTER')
    raise 'Not able to find the client in System...Please Verify' unless client
    client.custom_fields[:transaction_count] = 0
    if client.save
      puts "Transaction Count for UPMC Client has been initialized with value 0"
    end
  end

  desc "Task to initialize reference number for TRN02 segment of UPMC Client"
  task :initialize_reference_number => [:environment] do |t, args|
    ActiveRecord::Base.connection.execute("insert into sequences(name, value) values ('UPMC_REF_NUMBER', '11111')")
    puts "Transaction reference number is initialized to '-11111'"
  end

  desc "Populate Facility With Batch Upload Parser Value"
  task :populate_batch_upload_parser_value_for_facility => [:environment] do |t, args|
    facility_parser_lists = CSV.read("#{Rails.root}/private/configs/facility_parser_class_list.csv", {:headers => :true})
    facility_parser_lists.each do |facility_parser_list|
      facility = Facility.find_by_name(facility_parser_list[0].try(:strip))
      batch_upload_parser = BatchUploadParser.find_by_name(facility_parser_list[1].try(:strip))
      if facility && batch_upload_parser
        facility.update_column(:batch_upload_parser_id, batch_upload_parser.id)
      else
        puts "Not Loaded For - <#{facility_parser_list[0]} - #{facility_parser_list[0]}> --- <#{facility.try(:name)} - #{batch_upload_parser.try(:name)}>"
      end
    end
  end
end