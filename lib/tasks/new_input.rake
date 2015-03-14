namespace :new_input do
  desc "rake task for new input module which takes in zip file path and facility name as parameters"
  task :import_batch_file, [:file_path, :file_name, :facility, :arrival_time] => [:environment]  do |t, args|
    begin
      parameters = ['file_path','file_name','facility','arrival_time']
      missing_parameters = parameters.select {|i| args[i].blank?}
      raise "Should pass all #{parameters.join(',')} in sequence and #{missing_parameters.join(',')} should not be blank" unless missing_parameters.blank?
      batch_arrival_time= args.arrival_time || ENV["arrived_at"]
      rms_ack_arrival_time =  batch_arrival_time
      #time conversion
      zonestr = nil
      informat =  "%Y-%m-%d %H:%M:%S"
      outformat = "%Y-%m-%d %H:%M:%S"
      if batch_arrival_time
        batch_arrival_time = Time.strptime( (batch_arrival_time + " #{zonestr}"), informat).strftime(outformat)
      end
      load_start_time = Time.now
      batch_name =""
      batch_size = ""
      zip = Dir.glob("#{args.file_path}/#{args.file_name}").first
      if File.exists?(args.file_path)
        raise "No zip file  #{args.file_name} in '#{args.file_path}'" if zip.blank?
      else
        raise "No such directory '#{args.file_path}'"
      end
      batch_name= File.basename(zip)
      batch_size = File.size(zip)

      inbound_detail = args.file_name.split('.').last
      inbound_id = inbound_detail.split('_').last if inbound_detail.match(/^.*\_.*$/)

      inbound_info = if inbound_id
        InboundFileInformation.find(inbound_id)
      else
        InboundFileInformation.find_or_create_by_name_and_arrival_time(batch_name, Time.parse(batch_arrival_time).utc)
      end
      inbound_info = nil if inbound_info && inbound_info.status == InboundStatus::BATCH_LOADED

      if inbound_info
        inbound_info.update_attributes({:file_type=>"LOCKBOX", :status=>"ARRIVED", :load_start_time=>load_start_time, :size=>batch_size})
        #        inbound_info.update_estimates
        inbound_info.update_batch_loading_estimates
      end

      InputBatch.create_zip_for_dayton(args.file_path,args.facility) if (args.facility == "DAYTON PHYSICIANS")

      if zip
        InputBatch::Log.setup_log File.basename(zip), args.facility
        #        zip_index = InputBatch::IndexExtractor.new(args.facility, zip)
        zip_index = InputBatch::IndexExtractor.new(args.facility, zip,'', inbound_info, args.arrival_time)

        if args.facility.upcase == "ST BARNABAS"
          client_name = "BARNABAS"
        elsif args.facility.upcase == "PDS"
          client_name = "PACIFIC DENTAL SERVICES"
        elsif args.facility.upcase == "BENEFIT RECOVERY"
          client_name = "BENEFIT RECOVERY"
        else
          facility = Facility.find_by_name(args.facility)
          client_name = facility.client.name
        end
        if client_name.upcase == "QUADAX"
          md5_hash = Digest::MD5.hexdigest(File.read("#{args.file_path}/#{File.basename(zip)}"))
        end
        zip_index.extract_file
        ack_status = zip_index.is_ack_generate

        # Create ACK file for confirmation of batch loading
        if ack_status
          if client_name.upcase == "QUADAX"
	    AckCreator.create_ack_file("batch",md5_hash,"#{File.basename(zip)}")
	 elsif !facility.blank? && facility.name.upcase == "REVENUE MANAGEMENT SOLUTIONS LLC"
	    AckCreator.create_ack_file_for_rmkfi("#{File.basename(zip)}",rms_ack_arrival_time)
          end
        end
      end
      InputBatch::Log.status_log.info "Batch loading ends at #{Time.now}"
    rescue Exception => e
      puts e.message
        InputBatch::Log.error_log.error "Batch loading failed with following error"
        InputBatch::Log.error_log.error e.message
        InputBatch::Log.error_log.error e.backtrace.join("\n")
    ensure
      unless batch_arrival_time.blank?
        #        inboundfile_info = InputBatch::IndexExtractor.new(args.facility,'')
        #load_end_time = Time.now
        # assuming only one zip file
        #inboundfile_info.save_inbound_file_info(batch_name,batch_arrival_time,load_start_time,load_end_time,batch_size)
        #        inboundfile_info.update_inbound_information(inbound_info) if inbound_info
      end
    end
  end

  desc "rake task to execute ruby script in import_batch_file.rb, which takes file_name, file_apth, file_size,arrival_time,facility_name as parameters"
  task :execute_import_batch_file_script, [:file_name, :file_path, :file_size, :arrival_time, :facility] => [:environment]  do |t, args|
    begin
     system "ruby script/import_batch_file.rb -z '#{args.file_name}' -l '#{args.file_path}' -s '#{args.file_size}' -t '#{args.arrival_time}' -f '#{args.facility}'"
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
    end
  end

  desc "rake task for new input module which takes in zip file path and facility name as parameters for a test batch"
  task :import_test_batch_file, [:file_path , :facility] => [:environment]  do |t, args|
    begin
      InputBatch.log.info "\n\nA test batch is received."
      InputBatch.log.info "\n\nBatch loading starts at #{Time.now}"
      if File.exists?(args.file_path)
        puts "No zip file in '#{args.file_path}'" if Dir.glob("#{args.file_path}/*.[Z,z][I,i][P,p]").size == 0
      else
        puts "No such directory '#{args.file_path}'"
      end
      Dir.glob("#{args.file_path}/*.[Z,z][I,i][P,p]").each do |zip|
        zip_index = InputBatch::IndexExtractor.new(args.facility, zip, 'test_batch')
        zip_index.extract_file
      end
      InputBatch.log.info "Batch loading ends at #{Time.now}"
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")
      Dir.glob("#{Rails.root}/BatchTempFiles/*").each{|file| FileUtils.rm_rf file}
      InputBatch.log.error e.message
      InputBatch.log.error e.backtrace.join("\n")
    end
  end

  task :post_ocr_sent_activity, [:file_name, :file_sent_time] => [:environment]  do |t, args|
    begin
      ocr_tat = EnvironmentVariable.find_by_name("OcrTat")
      batch = Batch.find_by_ocr_zip_file_name(args.file_name, :include => [{:jobs => [:check_informations]}])
      expected_arrival_time = DateTime.parse(args.file_sent_time) + ocr_tat.value.hours
      batch.jobs.each do |job|
        check = job.check_informations.first
        is_ocr_job = check.micr_line_information.is_ocr if check.micr_line_information
        if is_ocr_job
          job.update_attributes(:ocr_status => "OCR SENT", :ocr_file_sent_time =>  args.file_sent_time, :ocr_expected_arrival_time => expected_arrival_time)
        end
      end
      puts "OCR sent parameters(ocr_status,ocr_file_sent_time,ocr_expected_arrival_time) are recorded.."
    rescue Exception => e
      puts e.message
    end
  end

  task :post_ocr_received_activity, [:file_name, :file_arrived_time] => [:environment]  do |t, args|
    begin
      job_id = args.file_name.split("_")[0]
      job = Job.find(job_id)
      job.update_attributes(:ocr_status => "OCR ARRIVED", :ocr_file_arrived_time =>  args.file_arrived_time)
      puts "OCR reveived parameters(ocr_status, ocr_file_arrived_time) are recorded.."
    rescue Exception => e
      puts e.message
    end
  end

  task :import_837_file, [:file_path,:facility]  => [:environment]  do |t, args|
    puts "Please use the new rake 'rake input:load_claim[]'..."
    #  include Input
    #    obj = Reader.create_file "837"
    #    obj.load_file args.file_path,args.facility
    #    puts "Invoking Sphinx Re indexing.."
    #    Rake::Task['sphinx:reindex'].invoke
    #    puts "Sphinx Re indexing completed."
  end

  desc "Import Reconciliation CSV (which conatins metadata of batches in a cut) for wellsfargo lockboxes"
  task :import_reconciliation_csv, [:file_path] => [:environment] do |t, args|
    begin
      csv_files = Dir.glob("#{args.file_path}/*.[c,C][s,S][v,V]")
      csv_files.each do |file|
        lockbox_number = File.basename(file).split('_').first
        csv_array = CSV.read(file)
        csv_array.shift(1)                                                      #removing header
        deposit_date = Date.parse(csv_array[0][2].strip)
        batch_ids = csv_array.collect{|row| row[1]}.uniq
        existing_record = ReconciliationInformation.find_by_deposit_date_and_lockbox_number(deposit_date, lockbox_number)
        unless existing_record
          batch_ids.each do |id|
            ReconciliationInformation.create(:index_batch_number => id, :deposit_date => deposit_date, :lockbox_number => lockbox_number )
          end
        else
          puts "The reconciliation file #{file} has already loaded"
        end
      end
      raise "ERROR >>> CSV file not found in location #{args.file_path}. Please check the loaction" if csv_files.blank?
    rescue Exception => e
      puts e.message
    else
      puts "loading CSV files completed"
    end

  end

end