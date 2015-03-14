require 'zip/zipfilesystem'
require 'input_batch'
require 'yaml'

CNF_PATH = "#{Rails.root}/lib/yml"
ARCHIVE_PATH = "#{Rails.root}/BatchArchive"
TEMP_UNZIP_PATH = "#{Rails.root}/BatchTempFiles"
CHOC_BATCH_PATH = "#{Rails.root}/BatchFor835Zip"

class InputBatch::IndexExtractor
  attr_accessor :facility_name, :zip, :unzip_loc, :zip_name, :batch_type

  def initialize(facility, zip, batch_type = nil, inbound_file_information = nil, arrival_time = nil)
    @facility_name = facility.strip
    @zip = zip
    @zip_name = File.basename(zip)
    @arrival_time = arrival_time
    # temporay location to where zip file is unzipped
    folder = File.basename(zip, File.extname(zip))
    @unzip_loc = "#{TEMP_UNZIP_PATH}/#{Time.now.strftime("%Y%m%d_%H%M%S")}_#{Process.pid}/#{folder}"
    FileUtils.mkdir_p(@unzip_loc)
    @batch_type = batch_type
    @inbound_file_information = inbound_file_information
    @facility = find_facility
    @is_ack_generate = false
    @nonlockbox_orbo = false
  end

  def import_batch
    case facility_name
    when 'STANFORD UNIVERSITY MEDICAL CENTER' then
      rename_shc_reference_laboratory
    when 'HORIZON LABORATORY LLC' then
      change_image_type("HORIZON LABORATORY LLC",0)
    when 'MERIT MOUNTAINSIDE' then
      change_image_type("MERIT MOUNTAINSIDE",0)
    end
    unless Facility.find_by_name("SHC REFERENCE LABORATORY").blank?
      rename_shc_reference_laboratory
    end
    message = $IS_PARTNER_BAC ? "" : ", Did you run task 'clients:create_clients_and_facilities' ?"
    if @facility.blank?
      raise "Couldn't find Facility for #{facility_name}" + message
    elsif @facility.client.blank?
      raise "Couldn't find Client for Facility #{facility_name}" + message
    elsif @facility.client.partner.blank?
      raise "Couldn't find Partner for client #{@facility.client.name}" + message
    end
    # to_file is a method defined in input_batch file
    folder = nil
    @fac_sym = @facility.name.to_file
    # archiving the batch zip files to BatchArchive folder in the application
    archive_loc = "#{ARCHIVE_PATH}/#{@fac_sym}"
    FileUtils.mkdir_p(archive_loc)
    # finding index file format of the facility
    raise "Please set Index file format for the facility" if @facility.index_file_format.blank?
    @index_ext = @facility.index_file_format.to_file
    @index_parser = @facility.index_file_parser_type ? @facility.index_file_parser_type.gsub('_bank', '') : nil
    excluded_facility = ['GENOPTIX MEDICAL LABORATORY','METROHEALTH SYSTEM','FRONT LINE'].include?(@facility.name.upcase)
    if @index_parser and !excluded_facility
      # getting configuration yml file of the parser
      InputBatch::Log.status_log.info "Parser Type            : #{@index_parser}"
      cnf_file = InputBatch.cnf_parser_file(@index_ext, @index_parser)
    else
      # getting configuration yml file of the facility, client
      cnf_file = InputBatch.config_file(@index_ext, @facility)
    end
    @client_sym = @facility.client.name.to_file
    InputBatch::Log.status_log.info "Configuration YML File : #{cnf_file}"
    if File.exists?(cnf_file)
      @cnf = YAML::load(File.open(cnf_file))
      klass = "InputBatch::#{@facility.batch_upload_parser.class_name}".constantize rescue nil
      if @index_parser
        lockbox = $IS_PARTNER_BAC ? '' : @index_parser+'_'
        klass = InputBatch.class_for_parser(lockbox, @cnf['PARSER']) unless klass
      else
        klass = InputBatch.class_for(@index_ext, @facility) unless klass
        rename_file_method = "file_rename_#{@fac_sym}"
        if self.methods.include?(rename_file_method.to_sym)
          send(rename_file_method)
        end
      end
      InputBatch::Log.status_log.info "Parser class           : #{klass}"
      InputBatch::Log.status_log.info "----------------------------------------------"
      unless batch_type.blank?
        parser = klass.new(cnf_file, @facility, unzip_loc, zip_name, batch_type, @inbound_file_information)
      else
        parser = klass.new(cnf_file, @facility, unzip_loc, zip_name, @inbound_file_information)
      end

      @directory = Dir.glob("#{unzip_loc}/**/*", File::FNM_CASEFOLD)
      @index_files =  get_index_files
      @idx_file_hash = get_combined_index_files_meta_hash
      parser.file_meta_hash = @idx_file_hash
      if @facility_name == "MOUNT NITTANY MEDICAL CENTER"
        @index_files.sort!
        @index_files.delete_at(0)
      elsif @facility_name == "PARTNERS IN INTERNAL MEDICINE"
        @index_files.sort!
        @index_files.delete_at(0)
        @index_files.delete_at(1)
      end
      raise "No index file #{@index_ext} found" if @index_files.empty?
      if $IS_PARTNER_BAC && zero_batch_file?
        parser.load_zero_byte_batch
      else
        @index_files.sort.reverse.each_with_index do |file, index|
          InputBatch::Log.write_log "Index file #{File.basename(file)} found"
          @duplicate_batch = false
          @nonlockbox_orbo = false
          check_batch_duplication if index == 0
          break if @duplicate_batch
          unless @duplicate_batch
            #Converting single images into multi page check image for Quadax HX
            if @facility_name == "HORIZON LABORATORY LLC" or @facility_name == "LAKE HEALTH REFERENCE LAB"
              puts "Converting single images to multi page check image"
              images = Dir.glob("#{unzip_loc}/**/*")
              dir_name = File.dirname(images.last)

              index_file = File.readlines(file)
              temp_list =[]
              tif_list = []
              index_file.each do |row|
                current_job = row[25..30]
                if  @facility_name == "LAKE HEALTH REFERENCE LAB"
                  image = row[62..73] unless row.blank?

                else
                  unless row.split(" ")[1].nil?
                    row.split(" ")[1].include?("C") ? image = row.split(" ")[2].slice(3..14) : image = row.split(" ")[3].slice(3..14)
                  end
                end
                temp_list << "#{dir_name}/#{image} " unless image.blank?

                index = index_file.index(row)
                next_row = index_file[index+1]

                unless next_row.nil?
                  if @facility_name == "LAKE HEALTH REFERENCE LAB"
                    next_image = row[16] != " " ? next_row.split(" ")[0] : next_row.split(" ")[1]
                    next_job = next_row[25..30]
                  else
                    next_image = next_row.split(" ")[1]
                    next_job = next_row[25..30]
                  end
                  if @facility_name == "LAKE HEALTH REFERENCE LAB"
                    next_image.nil? ? condition = true : condition = ((next_image.include?("C")) || (current_job != next_job) )
                  else
                    next_image.nil? ? condition = true : condition = ((next_image.include?("C")) || (current_job != next_job) )
                  end
                end

                if condition || next_row.nil?
                  tif_list << temp_list unless temp_list.blank?
                  temp_list = []
                end
              end
              pages = []
              tif_list.each do |list|
                pages << list.length
                first_image = list.first
                system("tiffcp -a #{list.push(list.shift).join}") if list.count > 1
                list.each do |l|
                  img = l.split(" ").first
                  FileUtils.rm("#{img}") unless l == first_image
                end
              end
              puts "Multi page check image conversion completed"
              parser.transform(file, pages) #also passes number of pages in the converted multipage
            else
              folder =  parser.transform(file)# parsing the index file starts here
            end
            loaded_batch = parser.instance_variable_get(:@bat)

            batch = loaded_batch || parser.instance_variable_get(:@batch)
            client_name = @facility.client.name.gsub("'", "")
             if client_name  == "CHILDRENS HOSPITAL OF ORANGE COUNTY"
              @batch_obj_array = Batch.find(:all,:conditions=>"file_name = '#{batch.file_name}'") unless batch.blank?
             end
              set_batch_type batch
            if loaded_batch.blank?
              @is_ack_generate = false
              @nonlockbox_orbo = true
            else
              @is_ack_generate = true
            end
          end
        end
      end

    else
      puts "Index File Format of Facility '#{@facility.name}' wrong in the FC UI."
    end
    unless (@duplicate_batch or @nonlockbox_orbo)
      client_name = @facility.client.name.gsub("'", "")
       if client_name.upcase  == "CHILDRENS HOSPITAL OF ORANGE COUNTY"
        choc_index_file = nil
        choc_batch_loc = "#{CHOC_BATCH_PATH}/#{client_name.to_file}/#{@zip_name.gsub(".zip","").gsub(".ZIP","")}"
        FileUtils.rm_rf(choc_batch_loc) 
        FileUtils.mkdir_p(choc_batch_loc)
        system "unzip \"#{zip}\" -d \"#{choc_batch_loc}\""
        @index_base_name_choc = nil
         @new_choc_csv_data = []
         if @batch_obj_array.present?
        @batch_obj_array.each do |batch_obj|

           Dir.glob("#{choc_batch_loc}/**/*.txt").each do |file|
          if File.basename(file).downcase == "index.txt"
            @index_base_name_choc = File.basename(file)
            choc_index_file =  CSV.open(file,"r",:headers=> false)
          end
        end
        batchid_list = batch_obj.batchid.split('_') unless batch_obj.batchid.blank?
        deposit_date = Date.strptime batchid_list[1], "%y%m%d" unless batchid_list.blank?
        deposit_date = (deposit_date.blank? ? '' : deposit_date.strftime("%Y%m%d"))
        bank_batch_number = (batchid_list[2].blank? ? '' : batchid_list[2].gsub(/^[0]*/,""))
        batch_lockbox = batch_obj.lockbox
        choc_checks = batch_obj.check_informations
        unless choc_index_file.blank?
           choc_index_file.each do |row|
            image_name_from_index = nil
            @row = row
            image_name_from_index = @row[7].strip.split("\\").last unless @row[7].blank?
            check_image =  nil
            choc_checks.each do |choc_check|
              @new_image_name = batch_lockbox.to_s + deposit_date.to_s+ bank_batch_number.to_s+ choc_check.transaction_id.to_s
              check_image = choc_check.job.initial_image_name
              ext_name = check_image.split(".").last
              @new_image_name = @new_image_name+"."+ext_name
              new_choc_image = Dir.glob("#{choc_batch_loc}/**/#{check_image}")[0]
              File.rename("#{new_choc_image}", "#{choc_batch_loc}/#{@new_image_name}") if new_choc_image.present?
              if(image_name_from_index.casecmp(check_image) == 0)
                @row[7] = @new_image_name
                @new_choc_csv_data << @row
              end
            end
          end
        end
        end
        @new_choc_csv_data.uniq! 
        CSV.open("#{choc_batch_loc}/new_index.txt", "w") do |csv|
          @new_choc_csv_data.each do |new_choc_data|
            csv << new_choc_data
          end
        end
     File.rename("#{choc_batch_loc}/new_index.txt", "#{choc_batch_loc}/#{@index_base_name_choc}")
        InputBatch.log.info "\nCopied to CHOC batch folder"
        p "Copied to CHOC batch folder"
      end
      end
   
      InputBatch.log.info "\nDeleting #{unzip_loc} as the batchloading completed"
      FileUtils.rm_rf(unzip_loc)# deleting the temporary directory where unzipping takes place
      sleep 1
      FileUtils.mv(zip, archive_loc)# archiving the batch zip files to BatchArchive folder in the application
    end
  end


  def extract_file lock_file = nil
    puts "\nExtracting #{zip_name}...."
    InputBatch.log.info "\nExtracting #{zip} to path #{unzip_loc}"
    FileUtils.mkdir_p(File.dirname(unzip_loc))
    use_unzip_command
    puts "Extraction complete"
    InputBatch.log.info "Extraction of #{zip} completed"
    orbo_facility_array = ["ORB TEST FACILITY","ORBOGRAPH","GULF IMAGING ASSOCIATES","THE GEORGE WASH UNIV MFA","SOUTH NASSAU COMMUNITY HOSPITAL"]
    if orbo_facility_array.include?(@facility_name)
      self.unzip_loc = unzip_loc + "/#{File.basename(zip, File.extname(zip))}"
      curr_orbidx = Dir.glob("#{unzip_loc}/*.[O,o][R,r][B,b][O,o][I,i][D,d][X,x]").first
      if curr_orbidx.nil?
        self.unzip_loc = unzip_loc.split('/')
        self.unzip_loc.pop
        self.unzip_loc = unzip_loc.join('/')
        curr_orbidx = Dir.glob("#{unzip_loc}/*.[O,o][R,r][B,b][O,o][I,i][D,d][X,x]").first
      end
      new_orbidx = "#{unzip_loc}/#{File.basename(curr_orbidx).split('.').first.to_s}.xml"
      FileUtils.mv(curr_orbidx, new_orbidx)
    end

    import_batch
    unless @duplicate_batch
      is_batch_loaded = Batch.select('file_name').find_by_file_name(@zip_name)
      if is_batch_loaded
        if @inbound_file_information
          @inbound_file_information.update_cut
          Batch.update_batch_total_charges(@inbound_file_information);
          if $IS_PARTNER_BAC
            require 'ocr/ocrpackage'
            Ocr::OcrPackage.new(@inbound_file_information).perform
          end
          @inbound_file_information.mark_completed_loading
          batches = @inbound_file_information.batches
          batches.each do |batch|
            set_batch_type batch
          end if batches.count > 1
          batches.each do |batch|
             batch.arrival_time = @inbound_file_information.arrival_time;
             batch_target_time = @inbound_file_information.arrival_time + batch.facility.tat.to_i.hours
	           batch.target_time = batch_target_time
             batch.contracted_time = batch_target_time
            batch.save
          end
        end
        ocr_enabled = EnvironmentVariable.find_by_name("OcrEnabled").value  if EnvironmentVariable.find_by_name("OcrEnabled")   #setting which identifies whether instance has ocr enabled or not
        if ocr_enabled == 1
          if @facility.ocr_enabled_flag
            puts "OCR Input Zip file generation starts at #{Time.now.strftime("%y:%m:%d - %H:%M:%S")}"
            batches = Batch.find_all_by_facility_id_and_file_name_and_status(@facility.id,@zip_name,"NEW")
            batches.each do |batch|
              InputBatch.prepare_ocr_input(batch.id)
            end
            puts "OCR Input Zip file generation ends at #{Time.now.strftime("%y:%m:%d - %H:%M:%S")}"
          end
        end
      elsif !is_batch_loaded and @inbound_file_information
        exception_type, system_exception = 'Batch Loading failed', 'batch is not duplicate but failed to load'
        @inbound_file_information.mark_batch_loading_exception exception_type, system_exception
      end
    end
  end

  def use_unzip_command
    client_name = @facility.client.name.upcase
    if client_name == 'RMS'
      pwd_cnf = YAML::load(File.open("#{Rails.root}/lib/input_batch/yml/input_batch_passwords.yml"))
      cnf_parameter = @facility.name.upcase.gsub(' ','_')
      password = "#{pwd_cnf[cnf_parameter]}"
      system "unzip -P \"#{password}\" \"#{zip}\" -d \"#{unzip_loc}\""
    else
      system "unzip \"#{zip}\" -d \"#{unzip_loc}\""
    end
  end

  def is_ack_generate
    @is_ack_generate
  end

  def method_to_call
    method_to_call = "index_condition"
    if self.methods.include?("#{method_to_call}_#{@fac_sym}".to_sym)
      method_to_call << "_#{@fac_sym}"
    elsif self.methods.include?("#{method_to_call}_#{@client_sym.gsub("'","")}".to_sym)
      method_to_call << "_#{@client_sym.gsub("'","")}"
    elsif @index_parser && self.methods.include?("#{method_to_call}_#{@index_parser.downcase}".to_sym)
      method_to_call << "_#{@index_parser.downcase}"
    end
    return method_to_call
  end

  def index_condition ext, file_name
    @index_ext == ext
  end

  def file_names_for_boa
    file_names = []
    file_names << "summary.csv" if InputBatch.is_payment_process(@facility)
    file_names << "corresp.csv" if InputBatch.is_corresp_process(@facility)
    return file_names
  end

  def index_condition_pnc ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_boa ext, file_name
    @index_ext == ext and file_names_for_boa.include?(file_name)
  end

  def index_condition_barnabas ext, file_name
    file_name.include?("index")
  end

  def index_condition_university_of_pittsburgh_medical_center ext, file_name
    file_name.include?("index")
  end

  def index_condition_childrens_hospital_of_orange_county ext, file_name
    file_name.include?("index")
  end


  def index_condition_stanford_university_medical_center ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_good_start_genetics ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_wellstar_laboratory_services ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_caris_diagnostics_do ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_caris_diagnostics ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_caris_molecular_profiling_institute ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_metroplex_pathology_asoc ext, file_name
    index_condition_boa ext, file_name
  end


  def index_condition_cohen_dermatopathology ext, file_name
    index_condition_boa ext, file_name
  end

  def index_condition_insight_health_corp ext, file_name
    file_names = ["summary.csv", "corresp.csv", "detail.csv"]
    @index_ext == ext and !file_names.include?(file_name)
  end

  def index_condition_jpmc_single ext, file_name
    @index_ext == ext or file_name.include?("index")
  end


  def index_condition_goodman_campbell ext, file_name
    @index_ext == ext or file_name.include?("index")
  end

  def index_condition_hurley_medical_center ext, file_name
    @index_ext == ext or file_name.include?("index")
  end

  def index_condition_robinson_memorial_hospital_lab ext, file_name
    @index_ext == ext or file_name.include?("index")
  end

  def index_condition_coug ext, file_name
    file_name == 'indexfile.txt'
  end

  def file_rename_stanford_university_medical_center
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_good_start_genetics
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_caris_diagnostics
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_caris_diagnostics_do
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_caris_molecular_profiling_institute
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_metroplex_pathology_asoc
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_cohen_dermatopathology
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end

  def file_rename_wellstar_laboratory_services
    subfolders = [ "images", "corr"]
    subfolders.each do |folder|
      images = Dir.glob("#{unzip_loc}/#{folder}/*.tif")
      images.each do |image|
        File.rename( image, "#{File.dirname(image)}/#{folder}#{File.basename(image)}")
      end
    end
  end



  def get_index_files
    @directory =  Dir.glob("#{unzip_loc}/images/*.idx", File::FNM_CASEFOLD) if @facility_name == "NLFH OUTREACH LABORATORY"
    @directory.select do |file|
      extension = File.extname(file).delete(".").to_s.downcase
      file_name = File.basename(file).downcase
      send(method_to_call, extension, file_name)
    end
  end

  def zero_batch_file?
    @index_files = @index_files.select do |file|
      type = 'PAYMENT'
      if @cnf['PARSER'] == 'csv'
        type = 'CORRESP' if File.basename(file).downcase == 'corresp.csv'
        header_row = @cnf['BANK_OF_AMERICA'][type]['HEADER_ROW']
        rows =   CSV.read(file, :col_sep => @cnf['COL_SEP'] )
        rows.shift(header_row)
      else
        rows = File.readlines(file)
      end
      !rows.join.blank?
    end
    @index_files.empty?
  end

  def rename_shc_reference_laboratory
    shc_facility = Facility.find_by_name("SHC REFERENCE LABORATORY")
    if shc_facility
      shc_facility.name = "STANFORD UNIVERSITY MEDICAL CENTER"
      shc_facility.save
    end
  end

  def change_image_type(facility,image_type)
    hx_facility = Facility.find_by_name(facility)
    if hx_facility
      hx_facility.image_type = image_type
      hx_facility.save
    end
  end

  def find_facility
    if @facility_name.to_file == 'st_barnabas'
      system("unzip -C -j #{@zip} *index -d #{@unzip_loc}")
      index_file =  Dir.glob("#{@unzip_loc}/index", File::FNM_CASEFOLD).first
      @csv = CSV.read(index_file)
      lockbox = @csv.first[3].to_s.strip[0..4]
      system("rm -rf #{@unzip_loc}/*") #remove the index file
      facility = Facility.find_by_lockbox_number(lockbox)
      raise "Cannot find facility for lockbox_number #{lockbox}" unless facility
    elsif  @facility_name.upcase == "PDS"
      lockbox = @zip_name.split("_").first.scan(/\d+/).first
      facility_lockbox = FacilityLockboxMapping.find_by_lockbox_number(lockbox)
      facility = Facility.find(facility_lockbox.facility_id)
      raise "Cannot find facility for lockbox_number #{lockbox}" unless facility
    elsif  @facility_name.upcase == "BENEFIT RECOVERY"
      lockbox = @zip_name[0..3]
      facility_lockbox = FacilityLockboxMapping.find_by_lockbox_number(lockbox)
      facility = Facility.find(facility_lockbox.facility_id)
      raise "Cannot find facility for lockbox_number #{lockbox}" unless facility
    elsif  @facility_name.upcase == "TEST"
      lockbox = @zip_name.split("_").first[3..5]
      facility_lockbox = FacilityLockboxMapping.find_by_lockbox_number(lockbox)
      facility = Facility.find(facility_lockbox.facility_id)
      raise "Cannot find facility for lockbox_number #{lockbox}" unless facility
    else
      facility = Facility.find_by_name(facility_name)
      raise "Cannot find facility by name #{facility_name}" unless facility
    end
    @inbound_file_information.update_attributes(:facility_id=>facility.id,:client_id=>facility.client_id) if @inbound_file_information
    facility
  end

  #this method will check the duplication of input batches for Quadax client
  def check_batch_duplication
    @facility_id, @client_id, @client_name = @facility.id, @facility.client.id, @facility.client.name.strip
    if any_batch_with_same_name?
      if same_content
        @subject, @is_duplicate_name, @has_same_name = "Duplicate File #{@zip_name}", false, true
        update_ifi_and_send_duplication_notification
      else
        @subject, @is_duplicate_name, @has_same_name = "Duplicate Filename #{@zip_name}", true, true
        update_ifi_and_send_duplication_notification
      end
      puts @subject
      @duplicate_batch = true
    elsif any_batch_with_same_content?
      @subject, @is_duplicate_name, @has_same_name = "Duplicate File #{@zip_name}", false, false
      update_ifi_and_send_duplication_notification
      puts @subject
      @duplicate_batch = true
    else
      @duplicate_batch = false
    end if @client_name == "Quadax" || "PACIFIC DENTAL SERVICES"
  end

  def any_batch_with_same_name?
    @batch_with_same_name = Batch.select('id, file_name, batchid, facility_id, client_id,file_name, file_meta_hash, arrival_time').find_by_file_name_and_facility_id_and_client_id(@zip_name, @facility_id, @client_id)
    @batch_with_same_name.present?
  end

  def any_batch_with_same_content?
    @batch_with_same_content = Batch.select('id, facility_id, file_name, batchid, client_id, file_meta_hash, arrival_time').find_by_file_meta_hash_and_facility_id_and_client_id(@idx_file_hash, @facility_id, @client_id)
    @batch_with_same_content.present?
  end

  def same_content
    @idx_file_hash == @batch_with_same_name.file_meta_hash
  end

  def update_ifi_and_send_duplication_notification
    duplicate_batch = @has_same_name ?  @batch_with_same_name : @batch_with_same_content
    if @inbound_file_information
      exception_type, system_exception = @subject, "Duplicate of file #{duplicate_batch.file_name}"
      @inbound_file_information.mark_batch_loading_exception exception_type, system_exception
    end
    email_cnf = YAML::load(File.open("#{Rails.root}/lib/input_batch/yml/batch_duplication_email_recipients.yml"))
    sender, recipient = email_cnf['sender'], email_cnf['recipient']
    RevremitMailer.notify_input_batch_duplicate(sender, recipient, @subject, duplicate_batch, @client_name, @facility_name, @zip_name, @is_duplicate_name, @arrival_time ).deliver
  end

  def get_combined_index_files_meta_hash
    if @index_files.count == 1
      Digest::MD5.hexdigest(File.read(@index_files.first))
    else
      file_meta_hash = []
      @index_files.sort.each do |file|
        file_meta_hash << Digest::MD5.hexdigest(File.read("#{file}"))
      end
      Digest::MD5.hexdigest(file_meta_hash.join)
    end
  end

  def set_batch_type batch
    unless batch.blank?
      check_amounts = CheckInformation.where(:job_id => batch.job_ids).map(&:check_amount).map(&:to_f)
      batch.batch_type = if check_amounts.blank?
        'Correspondence'
      elsif check_amounts.uniq.count == 1 and check_amounts.include?(0)
        'Correspondence'
      elsif !check_amounts.include?(0)
        'Payment'
      elsif check_amounts.uniq.count > 1 and check_amounts.include?(0)
        'All'
      else
        'All'
      end
      batch.save
    end
  end
end
