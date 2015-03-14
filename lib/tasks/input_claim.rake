require 'claims/transform_clienta837.rb'
require 'claims/transformer'
require 'package/dapackage'

namespace :input do 
  
  task :load_claim, [:file_location,:loading_against_client_or_facility,:name_of_client_or_facility]  => [:environment]  do |t, args|
    include Claims
    puts ">>>>>>>>>>>>>>>>>>>>>"
    puts ENV.inspect
    puts ">>>>>>>>>>>>>>>>>>>>>"
    if File.exist?("#{Rails.root}/lib/claims/yml/#{args[:name_of_client_or_facility]}.yml")
      $CNF = YAML.load(File.read("#{Rails.root}/lib/claims/yml/#{args[:name_of_client_or_facility]}.yml"))
    else
      $CNF = YAML.load(File.read("#{Rails.root}/lib/claims/yml/claim.yml"))
    end
    $EMR = YAML.load(File.read("#{Rails.root}/lib/claims/yml/email_recipient.yml"))
    $CNF['file_location'] = args[:file_location]
    if args[:loading_against_client_or_facility] == "F"
      $CNF['facility_name'] = args[:name_of_client_or_facility]
      facility = Facility.find(:first,:conditions=>"name = '#{args[:name_of_client_or_facility]}'")
      $CNF['client_name']  = facility.client.name
      $CNF['facility_level'] = true
    else
      $CNF['client_name'] = args[:name_of_client_or_facility]
      $CNF['facility_level'] = false
    end
    client_facility = args[:name_of_client_or_facility]
    type = args[:loading_against_client_or_facility]
    inbound_file_info_id = args[:inbound_file_info_id] if args[:inbound_file_info_id] # A quick hack which will be used only for the BAC clients..
    puts "The Inbound File id is ............"
    puts inbound_file_info_id
    claim_name = $CNF['claim_name']
  
    transf = Kernel.const_get(claim_name).new 
    transf.load_claims(inbound_file_info_id,client_facility,type)
    puts "Invoking Sphinx Re indexing.."
    Rake::Task['sphinx:reindex'].invoke
    puts "Sphinx Re indexing completed."

  end

  task :create_da_package => [:environment] do
    include Dapackage
    da = DaPackage.new
    da.generate
  end

  task :load_txt_claims, [:claim] => [:environment]  do |t, args|
    
    # Global $CNF is a support for LogManager code
    $CNF = YAML.load(File.read(args[:claim]))
    
    Transformer.transform args[:claim]
  end

  task :load_claim_file  => [:environment]  do |t, args|
    facility = Facility.find_by_sitecode(ENV["facility_code"])
    facility.inbound_file_informations.create(:name => ENV["file_name"], :size => ENV["size"], :arrival_time => ENV["arrival_time"], :count => ENV["file_count"], :status => "ARRIVED", :file_type => "CLAIM") if facility
    puts "The file is entered into the system"
  end

  task :associate_and_load_claims => [:environment]  do |t, args|
    facility = Facility.find_by_sitecode(ENV["facility_code"])
    ENV['client_name'] = facility.client.name
    ENV['facility_name'] = facility.name
    inbound_file_information = InboundFileInformation.find_by_facility_id_and_arrival_time_and_name(facility.id,ENV["arrival_time"],ENV["actual_file_name"]) if facility
    inbound_file_information.update_attributes(:status => "PROCESSING") if inbound_file_information
    Rake::Task["input:load_claim"].execute({:claim => "claim_a_xml", :file_location => ENV['file_location'], :facility_name => ENV['facility_name'], :client_name => ENV['client_name'], :inbound_file_info_id => inbound_file_information.id, :actual_file_name => ENV["actual_file_name"]})
    inbound_file_information.update_attributes(:status => "COMPLETE")
  end

  task :count_claims, [:xml_path] => [:environment] do |t, args|
    require 'fileutils'

    Dir.glob(args[:xml_path] + '/*') do |file|
      next if File.extname(file) == ".md"
      file_array = File.readlines(file).join.gsub("\r","").gsub("\n","").split("~")
      
      puts "Parsing 837 file: #{file}"

      #split if 837 file is single line with tildes in place of carriage returns
      file_array = file_array[0].split("~") if file_array.length == 1
      
      hl_array = []

      #Get HL 22 loop count
      file_array.each_with_index do |line, index|
        if line[0..1] == "HL" && line.split("*")[3] == "22"
          if hl_array.empty?
            hl_array << index
          else
            hl_array << index - 1
            hl_array << index
          end
        end
        if index == file_array.length - 1
          hl_array << index
        end
      end
      
      total_claims = 0
      total_services = 0

      hl_array.each_index do |index|
        if index.even?
          clm_count = 0
          claims_count = 0
          services_count = 0
          hl_segment = file_array[hl_array[index]..hl_array[index + 1]]
         
          #puts "HL Segment: #{hl_array[index]} - #{hl_array[index + 1]}"
          #Get CLM count for each HL 22 Loop
          hl_segment.each do |line|
            if line[0..2] == "CLM"
              clm_count += 1
            end
          end
          #Claims/Services count if only one CLM segment
          if clm_count == 1
            sbr_count = 0
            sv_count = 0
            hl_segment.each do |line|
              if line[0..2] == "SBR"
                sbr_count += 1
              elsif line[0..2] == "SV1" || line[0..2] == "SV2" || line[0..2] == "SV3"
                sv_count += 1
              end
            end
            claims_count = sbr_count
            services_count = sbr_count * sv_count
          #Claims/Services count if more than one CLM segment
          elsif clm_count > 1
            sv_counts_arr = []
            sbr_counts_arr = []
            claims_count = 0
            services_count = 0

            hl_segment.each_with_index do |line, i|
              if line[0..2] == "CLM"
                sv_count = 0
                sbr_count = 0
                #Parse the CLM Segment, break if another CLM segment starts
                hl_segment[(i + 1)..(hl_segment.length - 1)].each do |clm_seg_line|
                  if clm_seg_line[0..2] == "SV1" || clm_seg_line[0..2] == "SV2" || line[0..2] == "SV3"
                    sv_count += 1
                  elsif clm_seg_line[0..2] == "SBR"
                    sbr_count += 1
                  elsif clm_seg_line[0..2] == "CLM"
                    break
                  end
                end
                sv_counts_arr << sv_count
                sbr_counts_arr << sbr_count
              end
            end
            claims_count = clm_count + sbr_counts_arr.sum
            sv_counts_arr.each_with_index do |sv, j|
              services_count = (sv * sbr_counts_arr[j]) + services_count
            end
            services_count = sv_counts_arr.sum + services_count
          end
          total_claims += claims_count
          total_services += services_count
        end
      end
      puts "The number of claims = #{total_claims}"
      puts "The number of services = #{total_services}"
      filename = File.basename(file)
      if filename.include?(".")
        new_filename = filename.split(".").insert(1, "^#{total_services}^.").insert(1, "^#{total_claims}").join
      else
        new_filename = filename.split(".").insert(1, "^#{total_services}^").insert(1, "^#{total_claims}").join
      end
      FileUtils.mv(file, args[:xml_path] + "/#{new_filename}")
    end
  end

  task :archive_claims => [:environment] do |t, args|
    ClaimInformation.where("facility_id IS NOT NULL AND claim_end_date IS NOT NULL").each do |claim_info|
      facility = Facility.find(claim_info.facility_id)
      unless facility.archive_claims_in.blank? 
        time_diff = ((Time.now.year*12 + Time.now.month) - (claim_info.claim_end_date.year*12 + claim_info.claim_end_date.month)).abs
        if time_diff >= facility.archive_claims_in
          if claim_info.insurance_payment_eob.blank?
            claim_info.claim_service_informations.each { |service_info| service_info.destroy }
            claim_info.destroy
          else
            acct_num = claim_info.patient_account_number
            patient_first_name = claim_info.patient_first_name
            patient_last_name = claim_info.patient_last_name
            member_id = claim_info.patient_identification_number
            service_from_dates = []
            service_to_dates = []
            cpt_hcpcts = []
            revenue_codes = []
            charges = []
            payer_name = claim_info.payer_name
            claim_sequence = claim_info.claim_type
            relationship_to_subscriber = claim_info.individual_relationship_code
            subscriber_first_name = claim_info.subscriber_first_name
            subscriber_last_name = claim_info.subscriber_last_name
           
            claim_info.claim_service_informations.each do |service_info|
              service_from_dates << service_info.service_from_date
              service_to_dates << service_info.service_to_date
              cpt_hcpcts << service_info.cpt_hcpcts
              revenue_codes << service_info.revenue_code
              charges << service_info.charges
              service_info.destroy
            end
            
            hash = "#{acct_num};#{patient_first_name};#{patient_last_name};#{member_id};#{service_from_dates};#{service_to_dates};#{cpt_hcpcts};#{revenue_codes};#{charges};#{payer_name};#{claim_sequence};#{relationship_to_subscriber};#{subscriber_first_name};#{subscriber_last_name}"
            claim_info.insurance_payment_eob.update_attributes(:archived_claim_hash => hash)
            claim_info.destroy
          end
        end
      end
    end
  end

  task :remove_inactive_claims, [:billing_provider_npi] => [:environment] do |t, args|
    raise "Please provide the Billing Provider NPI to identify Claims" if args[:billing_provider_npi].blank?

    ActiveRecord::Base.connection.execute("DELETE FROM claim_service_informations WHERE claim_information_id IN (
      SELECT id FROM claim_informations WHERE billing_provider_npi=#{args[:billing_provider_npi].strip} AND facility_id IS NULL AND active=0)")

    ActiveRecord::Base.connection.execute("DELETE FROM claim_informations WHERE billing_provider_npi=#{args[:billing_provider_npi].strip} AND facility_id IS NULL AND active=0")

    #Equivalent Active Record Query. To use this query, enable :dependent => :destroy in claim_information model.
    #ClaimInformation.destroy_all(:billing_provider_npi => args[:billing_provider_npi], :active => false, :facility_id => nil)
    
  end

  task :map_facility_claims, [:qualifier, :value] => [:environment] do |t, args|
    if args[:qualifier].blank? || args[:value].blank?
      raise "Proivde proper input arguments. Eg., rake input:map_facility_claims['F','FACILITY_NAME'] |OR| rake input:map_facility_claims['N','NPI_NUMBER']"
    end
    if args[:qualifier].strip == 'F'
      facility_id = Facility.find_by_name(args[:value].strip).id
      FacilitiesNpiAndTin.where(:facility_id => facility_id).each do |f|
        count = ClaimInformation.update_all({:facility_id => facility_id, :active => true},{:billing_provider_npi => f.npi, :active => false, :facility_id => nil})
        puts "Total Number of Claims Mapped for NPI #{f.npi} : #{count}"
      end
    elsif args[:qualifier].strip == 'N'
      facility_id = FacilitiesNpiAndTin.find_by_npi(args[:value].strip).try(:facility_id)
      if facility_id
        count = ClaimInformation.update_all({:facility_id => facility_id, :active => true},{:billing_provider_npi => args[:value], :active => false, :facility_id => nil})
        puts "Total Number of Claims Mapped for #{args[:value]} : #{count}"
      else
        puts "Not able to map a facility for the given NPI. Please provide correct Billing Provider NPI value"
      end
    end
  end
  
end
