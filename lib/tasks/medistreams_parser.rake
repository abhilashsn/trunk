namespace :parse do
  require "nokogiri" # Embedding the Nokogiri gem in to the file
  desc 'Medistreams Parser'

  task :medistreams => :environment do

    # Parsing the claim level information from the medistreams XML and storing it into the claim_informations table.
    begin
      Dir.glob("#{Rails.root}/MedistreamsXml/*.xml").each do |xml_file| # Searching for the XML files in the specified directory.
        doc = Nokogiri::XML.parse(File.open("#{xml_file}")) { |spi| spi.noblanks }  # Using the Nokogiri gem
        claims = doc.xpath('/MediStreams.Claims/Claim')
        client = Client.find_by_name('Medistreams')
        facilities_obj =  client.facilities
        facility_npi_hash = Hash.new
        facility_tin_hash = Hash.new
        facility_ids = facilities_obj.collect {|p| p.id }
        facility_npi_and_tins = FacilitiesNpiAndTin.find(:all, :conditions => ["facility_id in (?)" , facility_ids])
        facility_npi_and_tins.each {|p|
          facility_npi_hash[p.npi] = {:npi => p.npi, :tin => p.tin ,:facility_id => p.facility_id } unless p.npi.blank?
          facility_tin_hash[p.tin] = {:npi => p.npi, :tin => p.tin ,:facility_id => p.facility_id } unless p.tin.blank?
        }
        loaded_claim_count =0
        loaded_svc_count = 0
        svc_count =0
        size = File.size?(xml_file)
        basename = File.basename(xml_file).split("^")
        file_837_name = [basename[0],basename[3]].join.gsub(".xml","")
        load_start_time = Time.now
        claim_count = doc.xpath('/MediStreams.Claims/Claim').length
        #extracting zip file name and arrival time form 837.md file
        zip_file_name,file_arrival_time,csv_file_name = ClaimInformation.get_md_file_contents("#{Rails.root}/MedistreamsXml/837.md")
        client_id = client.id
      claim_file_informtaion =  ClaimFileInformation.create(:client_id => client_id,:size => size,:zip_file_name => zip_file_name,
          :arrival_time => file_arrival_time,:name => file_837_name )
        claims.each do |claim| # Iterating over each claim starts here.
          claim_data = ClaimInformation.new() # A new claim object instantiation occurs here
          claim_data.patient_account_number = claim.xpath("./PatientAccountNumber").inner_text
          claim_data.patient_first_name = claim.xpath("./PatientFirst").inner_text
          claim_data.patient_last_name = claim.xpath("./PatientLast").inner_text
          claim_data.patient_middle_initial = claim.xpath("./PatientMid").inner_text
          claim_data.patient_identification_number = claim.xpath("./PatientID").inner_text
          claim_data.patient_medistreams_id = claim.xpath("./PatientMediStreamsID").inner_text
          billing_provider_organization_name = claim.xpath("./BillingProviderLast").inner_text
          claim_data.billing_provider_organization_name = billing_provider_organization_name
          claim_data.subscriber_last_name = claim.xpath("./SubscriberLast").inner_text
          claim_data.payer_name = claim.xpath("./PayerLast").inner_text
          claim_data.subscriber_first_name = claim.xpath("./SubscriberFirst").inner_text
          claim_data.subscriber_middle_initial = claim.xpath("./SubscriberMid").inner_text
          claim_data.insured_id = claim.xpath("./SubscriberID").inner_text
          claim_data.payer_address = claim.xpath("./PayerAddress1").inner_text
          claim_data.payer_city = claim.xpath("./PayerCity").inner_text
          claim_data.payer_state = claim.xpath("./PayerState").inner_text unless claim.xpath("./PayerState").inner_text == "null"
          claim_data.payer_zipcode = claim.xpath("./PayerZip").inner_text
          claim_data.claim_type = claim.xpath("./ClaimStatusIndicator").inner_text
          claim_data.plan_type = claim.xpath("./ClaimFilingID").inner_text
          claim_data.total_charges = claim.xpath("./TotalClaimCharges").inner_text
          claim_data.facility_type_code = claim.xpath("./FacilityType").inner_text
          claim_data.provider_last_name = claim.xpath("./RenderingProviderLast").inner_text
          claim_data.provider_first_name = claim.xpath("./RenderingProviderFirst").inner_text
          claim_data.provider_middle_initial = claim.xpath("./RenderingProviderMid").inner_text
          claim_data.provider_npi = claim.xpath("./RenderingProviderID").inner_text
          billing_npi_tin = claim.xpath("./BillingProviderID").inner_text
          facility_id = facility_npi_hash["#{billing_npi_tin}"][:facility_id] if facility_npi_hash["#{billing_npi_tin}"]
          facility_id = facility_tin_hash["#{billing_npi_tin}"][:facility_id] if facility_tin_hash["#{billing_npi_tin}"] and facility_id
          claim_data.facility_id = facility_id
          claim_data.client_id = client.id
          claim_data.claim_file_information_id = claim_file_informtaion.id
          claim_status = claim_data.save!
          if(claim_status)
            loaded_claim_count+=1
          end
          #Parsing the service level informations and storing into claim_service_informations table
          svc_count = svc_count + (claim.xpath("./Line").length)
          claim.xpath("./Line").each do |service_line| # Iterating over each service line starts here.
            serv_line = claim_data.claim_service_informations.create() # A new service line object instantiation occurs here
            serv_line.cpt_hcpcts = service_line.xpath("./ProcedureCode").inner_text
            serv_line.modifier1 = service_line.xpath("./ProcedureCodeModifier1").inner_text
            serv_line.modifier2 = service_line.xpath("./ProcedureCodeModifier2").inner_text
            serv_line.modifier3 = service_line.xpath("./ProcedureCodeModifier3").inner_text
            serv_line.modifier4 = service_line.xpath("./ProcedureCodeModifier4").inner_text
            serv_line.charges = service_line.xpath("./LineItemCharges").inner_text
            serv_line.days_units = service_line.xpath("./ServiceUnits").inner_text
            serv_line.service_from_date = service_line.xpath("./ServiceLineFromDate").inner_text
            serv_line.provider_control_number = service_line.xpath("./REF6R").inner_text
            serv_line.service_to_date = service_line.xpath("./ServiceLineToDate").inner_text
            serv_line_status = serv_line.save!
            if(serv_line_status)
              loaded_svc_count+=1
            end
          end # Service line block ends here.
        end # Claim level block ends here.
        status = (((claim_count.to_i + svc_count.to_i) - (loaded_claim_count.to_i + loaded_svc_count.to_i)).eql?(0) ? "SUCCESS" : "FAILURE")
        #saving details of claim file in claim_file_informations
        claim_file_informtaion.update_attributes(:deleted => 0,:total_claim_count => claim_count,:loaded_claim_count =>loaded_claim_count,
          :total_svcline_count => svc_count,:loaded_svcline_count => loaded_svc_count,:load_end_time => Time.now,
         :status =>status,:load_start_time => load_start_time)
        system "mv #{xml_file} #{Rails.root}/MedistreamsXmlArchieve/" # Archieving the already parsed XML files.
     puts "claims loaded sucessfully"
      end # File fetching block ends here.
    rescue Exception => e
      puts "An Exception has occured.The error is.................."
      puts e.message
    end
    puts "Invoking Sphinx Re indexing.."
    Rake::Task['sphinx:reindex'].invoke
    puts "Sphinx Re indexing completed."
  end # Rake task block ends here.

end # NameSpace block ends here.