namespace :era_xml_load do
  
  desc "The task to create the plans for the FM dashboard usage.."
  task :input_era_xmls, [:file_path, :identifier_hash] => [:environment]  do |t, args|
    unless args.file_path || args.identifier_hash
      raise "The file path identifier_hash are mandatory as parameters....An example rake call is given below..\n 'rake era_xml_load:input_era_xmls file_path='VM5', identifier_hash='f816f9582348a415119d89d2fbfa055b' "
    else
      begin
       era=Era.first(:conditions =>{:identifier_hash =>args.identifier_hash})
       raise 'The given Identifier hash is not found. Please provide valid hash.' if era.nil?
       inbound_file_information=era.inbound_file_information
       inbound_file_information.file_path = args.file_path
       xml_present = Dir.glob(args.file_path+"#{inbound_file_information.name}.xml")
       era_present = Dir.glob(args.file_path+"#{inbound_file_information.name}")
       if !xml_present.blank? && !era_present.blank?
         era.xml_conversion_time= Time.now
         era.save
         inbound_file_information.status = "XML_CONVERTED"
         inbound_file_information.save
         error_file = Dir.glob(args.file_path+"#{inbound_file_information.name}.err")
         first_error_code = ""

         if !error_file.blank?
           error_file_name = error_file[0]
           error_exists = false
           File.readlines(error_file_name).each_with_index do |line,index|
             if index == 0
               first_error_code = line.split(":")[1].gsub(/[^0-9A-Za-z]/, '')
             end
             error_exists = true if line.include?("Error code") 
           end
           #error_code_line=File.readlines(args.file_path+"#{inbound_file_information.name}.err")[0]
           #error_code = error_code_line.split(":")[1].gsub(/[^0-9A-Za-z]/, '')
         end
         if error_file.blank? || first_error_code == "000" || !error_exists
          #method to split single era transactions file and XML parsing.
          split_era_singles_and_parse_xml(era.id)
          inbound_file_information.update_attributes(:status => "XML_PARSING_FAILED") if !@balanced
         else
            inbound_file_information.status = "EXCEPTION"
            inbound_file_information.save
         end
       elsif !xml_present.blank? && era_present.blank?
         era.update_attributes(:xml_conversion_time => Time.now)
         inbound_file_information.status = "RAW_ERA_MISSING"
         inbound_file_information.save
       elsif  xml_present.blank? && !era_present.blank?
         era.update_attributes(:xml_conversion_time => Time.now)
         inbound_file_information.status = "XML_CONVERSION_FAILED"
         inbound_file_information.save
       end

      AckCreator.create_ack_file_for_eras(inbound_file_information.file_type, era.file_md5_hash, inbound_file_information.name, era.sftp_location, inbound_file_information.status)

      rescue Exception => e
        puts "The ERA file cannot be loaded as there are some data related issues..."
        puts "The system error which occured is '#{e.message}'"
        Rails.logger.debug "The error occured while creating the ERA today, #{Date.today} was.. \n #{e}"
      end
    end
  end

  def split_era_singles_and_parse_xml(era_id)
    @era = Era.find(era_id, :include => [:inbound_file_information, :era_checks, :era_jobs]) #eager loaded associated tables
    @era.update_attributes(:era_parse_start_time => Time.now, :era_process_start_time => Time.now)
    @era.inbound_file_information.update_attributes(:status => 'ERA_PARSING')
    
    # output file location
    @output_file_path = "Archive/#{Time.now.strftime("%Y%m%d")}/ERA/Singles"
    FileUtils.mkdir_p(@output_file_path)

    raw_era_file = File.open("#{@era.inbound_file_information.file_path}/#{@era.inbound_file_information.name}", 'r')

    first_line = raw_era_file.first
    @single_line_wrap = /^ISA((\*)|(\|)).*P((\*)|(\|)).~$/.match(first_line) ? false : true

    @segments = ''
    IO.foreach(raw_era_file){|segment| @segments += segment}
    @raw_835_segments = @segments.delete("\n").split("~").collect{|line| line.strip+"~\n"}

    @delimiter = (/^ISA\*.*$/.match(first_line) ? '*' : (/^ISA\|.*$/.match(first_line) ? '|' : nil))

    file_count = 1 #counter value appended to newly created single ST-SE files
    transaction_segment = false #boolean to find segment lies with ST-SE transaction loop

    #initialization statements
    segments = ""
    @era_jobs, @era_checks = [], []

    #Iterates over complete era file with multiple ST-SE transactions
    @raw_835_segments.each do |line|
      if /^ST((\*)|(\|)).*$/.match(line) #match start of a transaction
        transaction_segment = true
        segments = segments + line
        @track_number = line.split(@delimiter)[2].chomp.split(/~/).first
      elsif /^SE((\*)|(\|)).*$/.match(line)  #match end of a transaction
        segments = segments + line
        create_single_transaction_file("#{@output_file_path}/#{@era.inbound_file_information.name+'_'+file_count.to_s}", segments)
        transaction_segment = false
        segments = ""
        file_count = file_count + 1
      elsif transaction_segment
        segments = segments + line
      end
    end

    @era.update_attributes(:era_parse_end_time => Time.now)
    @era.inbound_file_information.update_attributes(:status => 'ERA_AND_PARSED')
    
    puts "Seperate files created for every transaction."
    puts "Starting of XML parsing ..."
    #invoke 835 XML file parsing
    parse_xml_content
    @era.update_attributes(:era_process_end_time => Time.now)
  end

  #Create and save Single ST-SE transaction file
  def create_single_transaction_file(file_name, segments)
    segments = segments.delete("\n") if @single_line_wrap
    File.open(file_name, 'w+') do |file|
      file.write(segments.force_encoding("UTF-8"))
    end

    md5_hash = Digest::MD5.hexdigest(File.read(file_name))

    #EraJob model attributes grouped as a hash
    file_options_hash = {
      :era_id => @era.id,
      :tracking_number => @track_number,
      :transaction_hash => md5_hash
      }

    era_job = EraJob.create!(file_options_hash)
    era_check = EraCheck.where(:transaction_hash => era_job.transaction_hash).first
    if era_check.blank?
      era_check = EraCheck.create!(file_options_hash.merge("835_single_location" => @output_file_path))
    end
    era_job.update_attributes(:era_check_id => era_check.id)
    @era_checks << era_check
    puts "Single ST-SE file #{file_name} created successfully."
  end

  def parse_xml_content
    xml_file_with_path = "#{@era.inbound_file_information.file_path}#{@era.inbound_file_information.name}.xml"
    era_client = @era.inbound_file_information.client
    begin
      @era_checks.each do |era_check|
        era_job = era_check.era_jobs.where(:era_id => @era.id).first
        out_of_balance_verification(era_check.tracking_number)
        if @balanced
          parser = XML::SAX::Parser.new(Era::EraXmlParser.new(era_check, era_job, era_client, @delimiter, @single_line_wrap))
          parser.parse_file(xml_file_with_path)
          puts "Transaction #{era_check.tracking_number} is parsed."
        else
          EraException.create(:process => "XML_PARSING", :code => "XML_PARSE_ERROR", :description => "ERA Transaction #{era_check.tracking_number} is out of balance", :era_id => @era.id)
          puts "Transaction #{era_check.tracking_number} is not balanced. Skipped loading this transaction."
        end
      end
      puts "XML contents are parsed and tables are populated."
    rescue => e
      @era.inbound_file_information.update_attributes(:status => 'XML_PARSING_FAILED')
      @era.era_exceptions.create(:process => "XML_PARSING", :code => "XML_PARSE_ERROR", :description => e.message)
      puts e.message
      puts e.backtrace
    end
  end

  def out_of_balance_verification(tracking_number)
    @raw_835_segments.each do |line|
      @current_track_number = line.split(@delimiter)[2].chop.delete('~') if /^ST((\*)|(\|)).*$/.match(line)
      if (@current_track_number == tracking_number)
        if /^BPR((\*)|(\|)).*$/.match(line)
          @actual_provider_payment = line.delete('~').chop.split(@delimiter)[2].to_f
          @total_claim_payment, @payment_amount = 0, nil
        elsif /^CLP((\*)|(\|)).*$/.match(line)
          if @first_claim
            @balanced = check_claim_level_balance
            break if @balanced == false
          end
          @segment_level, @first_claim, @service_count = 'CLP', true, 0
          @claim_cas_amounts, @claim_service_details, @service_segments = [], [], {}
          @claim_charge, @claim_payment = line.delete('~').chop.split(@delimiter).select.with_index{|x, i| [3,4].include?(i)}.map(&:to_f)
          @total_claim_payment = @claim_payment + @total_claim_payment
        elsif /^SVC((\*)|(\|)).*$/.match(line)
          @segment_level, @service_cas_amounts = 'SVC', []
          @service_charge, @service_payment = line.delete('~').chop.split(@delimiter).select.with_index{|x, i| [2,3].include?(i)}.map(&:to_f)
          @service_segments.merge!((@service_count += 1) => [@service_charge, @service_payment, 0])
        elsif /^CAS((\*)|(\|)).*$/.match(line)
          cas_amount = line.delete('~').chop.split(@delimiter).drop(1).select.with_index{|x, i| (i+1) %3 == 0}.map(&:to_f).inject(:+)
          if @segment_level == 'CLP'
            @claim_cas_amounts << cas_amount
          elsif @segment_level == 'SVC'
            @service_segments[@service_count][2] += cas_amount
          end
        elsif /^PLB((\*)|(\|)).*$/.match(line)
          @payment_amount = line.delete('~').chop.split(@delimiter).drop(1).select.with_index{|x, i| (i+1) %4 == 0}.map(&:to_f).inject(:+)
        elsif /^SE((\*)|(\|)).*$/.match(line)
          @first_claim = nil
          @balanced = check_claim_level_balance
          break if @balanced == false
          @balanced = (@actual_provider_payment == (@payment_amount ? (@total_claim_payment.round(2) - @payment_amount) : @total_claim_payment.round(2)) ? true : false)
          break
        end
      end
    end
  end

  def check_claim_level_balance
    total_service_charge = 0
    if @claim_cas_amounts.present?
      return false unless (@claim_charge - @claim_cas_amounts.flatten.map(&:to_f).inject(:+)).round(2) == @claim_payment
    else
      @service_segments.each_pair do |claim_count, service_details|
        service_details[1] == ((service_details[0] - service_details[2]).round(2)) ? (total_service_charge += service_details[0]) : (return false)
      end
      return false if total_service_charge.round(2)  != @claim_charge
    end
    true
  end

end
