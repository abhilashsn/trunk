require 'claims/log_manager'
require 'claims/transformer'
require 'claims/interchange_data_parser'

class TransformClientA837 
      
  attr_reader :trf     
  # This method initializes the respective transformer class based on the file type.
  def initialize
    #create the log directory
    @trf = Transformer.factory getTransType
    if $CNF['facility_name'].blank?
      @archive_location = "Archive/#{Time.now.strftime("%Y%m%d")}/Claim/#{$CNF['client_name'].split(' ').join}"
      @failed_location = "failed_claim_files/#{Time.now.strftime("%Y%m%d")}/Claim/#{$CNF['client_name'].split(' ').join}"
    else
      @archive_location = "Archive/#{Time.now.strftime("%Y%m%d")}/Claim/#{$CNF['facility_name'].split(' ').join}"
      @failed_location = "failed_claim_files/#{Time.now.strftime("%Y%m%d")}/Claim/#{$CNF['facility_name'].split(' ').join}"
    end
    
    system "mkdir -p #{@archive_location}"
    system "mkdir -p #{@failed_location}"
  end
        
  # This method identifies the file type based on the config file.
  def getTransType
    return $CNF['parser_type'].upcase
  end
      
  # This method calls the transform method in the selected file type based class.
  def load_claims(*args)
    case getTransType
    when "XML"
      load_sax_handler(*args) #The inbound file id as a quick fix
    when "CSV"
      load_csv_handler
    when "TXT"
      load_csv_handler
    end
  end

  def check_duplicate_file_meta_hash(file,file_name,size,isa09_isa10_value)
   file_meta_hash = "md5sum #{file}"
	 md5_file_meta_hash = `#{file_meta_hash}`.split(" ")[0]
#   file_meta_hash = file_name.to_s + "_" + size.to_s + "_" + isa09_isa10_value
#   md5_file_meta_hash = Digest::MD5.hexdigest(file_meta_hash)
    claim_file_information = ClaimFileInformation.all(:conditions => "file_meta_hash = '#{md5_file_meta_hash}' AND deleted = #{0}")
    if claim_file_information.blank?
      @old_file = ""
      @file_meta_hash = md5_file_meta_hash
      return false
    else
      @old_file = claim_file_information.first.name.to_s
      @file_meta_hash = ""
      return true
    end
  end

  def send_mail(file_name, client_facility, type, old_file, file_path)
    if type == "F"
      facility_name = client_facility
      facility = Facility.find_by_name(client_facility.to_s)
      client_name = facility.client.name
    elsif type == "C"
      facility_name = "-"
      client_name = client_facility
    end
    subject = "Potential duplicate claim file alert for claim file #{file_name}"
    body_content = "could be"
    recipient = $EMR['recipient']
    RevremitMailer.notify_claim_upload(recipient,subject, file_name,
      facility_name, client_name, file_path, old_file, body_content).deliver
  end

  def load_sax_handler(*args)
    load_status = "SUCCESS"
    md5_hash = ""
    zip_file_name = ""
    begin  
      s = Time.now.to_f
      puts "Parser Start Time : #{Time.now}" 
      
      Dir.glob($CNF['file_location']+"/*.xml").each_with_index do |file,index|
        load_claim = true
        $CNF['type'] ||= args[2]
        if $CNF['type'] == "F"
          facility = Facility.find_by_name($CNF['facility_name'].to_s, :include => :client)
          client_name = facility.client.name
          #Writing this client based checking explicitly because when discussed with the team, its identified that this is a client specific non-generic requirement.So no need of a generic config..
          if client_name.upcase == "QUADAX"
            old_facility_name = args[1].to_s.strip
            file_name = File.basename(file).to_s
            facility_code = file_name[0..3]
            correct_facility_code = FacilitiesCode.find_by_code(facility_code, :include => :facility)
            unless correct_facility_code
              facility_code = File.basename(file).to_s[0..1]
              correct_facility_code = FacilitiesCode.find_by_code(facility_code, :include => :facility)
            end
            if correct_facility_code
              correct_facility = correct_facility_code.facility.name
              $CNF['facility_name'] = correct_facility
              new_facility_name = $CNF['facility_name'].to_s.strip
              if new_facility_name != old_facility_name
                RevremitMailer.notify_wrong_loading($RR_REFERENCES['email']['wrong_837_load']['notification'], file_name, old_facility_name, new_facility_name).deliver
              end
            else
              load_claim = false
              RevremitMailer.notify_absence_of_sitecode($RR_REFERENCES['email']['wrong_837_load']['notification'], file_name).deliver
              puts "The site code associated with the given claim file is not found in the system..You will have to create it in the 'facilities_codes' table"
            end
          end
        end
        if load_claim
          @trf = Transformer.factory getTransType
          parser = XML::SAX::Parser.new(@trf)
          load_start_time = Time.now
          size = File.size?(file)
          basename = File.basename(file).split("^")
          clp_count = basename[1].to_i
          svc_count = basename[2].to_i

          file_837_name = [basename[0],basename[3]].join.gsub(".xml","")

          #Check if 837 is not ANSI compliant
          if svc_count == 0 && clp_count == 0
            system "mv #{file.gsub(".xml","")} #{@failed_location}"
            RevremitMailer.notify_837_not_ansi_compliant(file_837_name, @failed_location).deliver
            next
          end

          @client_facility = $CNF['client_facility'] = args[1]
          @type = $CNF['type'] = args[2]
          $CNF['file_path'] = file
          $CNF['file_name'] = file_837_name

          arg_interchange_data_parser = InterchangeDataParser.new
          interchange_data_parser = XML::SAX::Parser.new(arg_interchange_data_parser)
          interchange_data_parser.parse_file(file.to_s)
          isa09_isa10_value = arg_interchange_data_parser.get_isa09_isa10_values
          st_se_correctness = arg_interchange_data_parser.get_st_se_correctness
          if File.exists? "#{$CNF['file_location']}/837.md"
            zip_file_name,file_arrival_time,csv_file_name,md5_hash = ClaimInformation.get_md_file_contents("#{$CNF['file_location']}/837.md")
          else
            zip_file_name = nil
            file_arrival_time = nil
            csv_file_name = Time.now.strftime('%m%d%Y%H%M%S')
            md5_hash = nil
          end

          raise "No arrival time, please make sure 837.md file is present and correctly formatted" if file_arrival_time.blank?

          if check_duplicate_file_meta_hash(file,file_837_name,size,isa09_isa10_value)
            old_file = @old_file
            send_mail(file_837_name,@client_facility,@type,old_file,file)
            puts "The file #{file_837_name} has failed to load since it is a duplicate of a previously processed claim file #{file_837_name} that arrived on #{file_arrival_time}. The filename, filesize and the file generation date and time match the file #{old_file}\nOld filename - #{old_file}\nOld filesize - #{size}\nOld file generation date/time - #{isa09_isa10_value}"
            system "mv #{file} #{@archive_location}"
          elsif st_se_correctness == false
            puts "The ST/SE count mismatch in the claim file............"
            system "mv #{file} #{@failed_location}"
            RevremitMailer.notify_st_se_mismatch(file_837_name, @failed_location).deliver
          else
          

          puts "File Name : "+file
          puts "Start Time : #{load_start_time}"

          zip_file_name = '' if $CNF['client_name'].eql?("PACIFIC DENTAL SERVICES") || $CNF['facility_name'].eql?("PACIFIC DENTAL SERVICES")

          @trf.claim_file_information_start(size,file_837_name,load_start_time,zip_file_name,file_arrival_time,@file_meta_hash,args[0])
          parser.parse_file(file)

          load_end_time =  Time.now

          # If any one of the XML files from the 837 Zip file fails to load, that will be considered the load status for the entire
          # Zip file.
          if load_status != "SUCCESS"
            @trf.claim_file_information_end(load_end_time, clp_count, svc_count, file, @failed_location)
          else
            load_status = @trf.claim_file_information_end(load_end_time, clp_count, svc_count, file, @failed_location)
          end

          puts "End Time : #{load_end_time}"

          msg = @trf.get_claim_status(load_start_time, load_end_time,file)
          LogManager.log_claim_exception(msg)
          system "mv #{file} #{@archive_location}"
          @trf = nil
          parser = nil
          ObjectSpace.garbage_collect
          end
        end
      end
      
      e = Time.now.to_f
      puts "Parser End Time : #{Time.now}"
      puts e-s
    rescue => err
      load_status = "FAILURE"
      puts err.message
      LogManager.log_ror_exception(err,"message")
      raise err
    ensure
      if $CNF['client_name'].upcase.eql?("QUADAX") && load_status == "SUCCESS"
        AckCreator.create_ack_file("claim",md5_hash,"#{zip_file_name}") unless zip_file_name.blank?
      end
    end
  end
       
  def load_csv_handler
    begin
      s = Time.now.to_f
      puts "Start Time : #{Time.now}"
          
      Dir.glob($CNF['file_location']+"/*.{csv,DAT}").each_with_index do |file,index|
        puts "Processing ...................#{File.basename(file)}"
        size = file.size
        file_837_name = File.basename(file)
        load_start_time = Time.now
         
        if File.exists? "#{$CNF['file_location']}/837.md"
          zip_file_name,file_arrival_time,csv_file_name = ClaimInformation.get_md_file_contents("#{$CNF['file_location']}/837.md")
        else
          zip_file_name = nil
          file_arrival_time = nil
          csv_file_name = Time.now.strftime('%m%d%Y%H%M%S')
        end
        
        zip_file_name = '' if $CNF['client_name'].eql?("PACIFIC DENTAL SERVICES") || $CNF['facility_name'].eql?("PACIFIC DENTAL SERVICES")               

        @trf.claim_file_information_start(load_start_time,size,file_837_name,zip_file_name,file_arrival_time)
            
        @trf.transform(file)
            
        load_end_time =  Time.now
        @trf.claim_file_information_end(load_end_time)
              
        msg = @trf.get_claim_status(load_start_time, load_end_time,file)
        LogManager.log_claim_exception(msg)
              
      end
          
      e = Time.now.to_f
      puts "End Time : #{Time.now}"
      puts e-s
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
    end
  end
  
  def load_txt_handler
    
  end
end
