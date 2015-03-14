require 'csv'
require 'yaml'
require 'input_batch'

################################################################################
# Description : This class is responsible for parsing index file from BOA, Apria,
#               PNC, WellsFargo lockboxes.It gets a file object as its input and
#               parses all the records in the csv file, parses data and save the
#               data to the application database.
# Created     : 09-02-11 by Sunil Antony @ Revenuemed
################################################################################
class InputBatch::CsvParser
  attr_accessor :csv, :config_hash, :type, :facility, :row, :client, :file_meta_hash
  WARRANT_ABA = '121113423'
  WARRANT_PAYER_ACCOUNT_NUMBER = "000000000"
  FIRST_BATCH_ID = 2176782335
  #-----------------------------------------------------------------------------
  # Description : This method initialize the parser class.
  # Input       : config file, facility, extracted zip location, zip_file_name
  # Output      : None
  #-----------------------------------------------------------------------------
  def initialize(config_yml_file, facility, location, zip_file_name,inbound_file_information)
    @config_yml = config_yml_file
    @facility = facility
    @parser = @facility.index_file_parser_type.to_s.downcase.split('_')[0]
    @sitecode = @facility.sitecode.to_s.strip.upcase
    @location = location
    @zip_file_name = zip_file_name
    @client = facility.client
    @@batch_date = Date.today if !defined?(@@batch_date)
    @hash_envelop_images = {}
    @hash_envelop_value = 0
    @inbound_file_information = inbound_file_information 
  end

  #-----------------------------------------------------------------------------
  # Description : This method parses the input csv file and  saves the retrieved
  #               data to application database.
  # Input       : Csv file name
  # Output      : None
  #-----------------------------------------------------------------------------
  def transform index_file
    @config_hash = YAML.load(ERB.new(File.read(@config_yml)).result(binding))
    InputBatch::Log.write_log "Opened csv file for processing"
    InputBatch::Log.write_log "Batch type to load : #{facility.batch_load_type.upcase}"

    @index_file_name = File.basename(index_file).downcase
    load_flag = true
    @corresp_flag = true
    @version = facility.index_file_parser_type.downcase.include?('_bank') ? 'BANK_OF_AMERICA' : 'GENERAL'
    begin
      @csv = CSV.read(index_file, :col_sep => config_hash['COL_SEP'] )
    rescue
      raise ">>>>>>>> Invalid index file....."
    end
    @type = call_parser_specific_method "find_type"
    @image_folder = Dir.glob("#{@location}/**/#{config['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
    unless @image_folder.blank?
      @image_path = @image_folder.first.split('/')[0..-2].join('/')

      raise "Image Folder Mismatch : Please check for folder (case insensitive)
        '#{config['IMAGE']['image_folder']}' in batch zip " if @image_folder.blank?

      @image_ext =File.extname(@image_folder[0]).delete(".")
    end
    InputBatch::Log.write_log ">>>>>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    header_row = config["HEADER_ROW"]
    csv.shift(header_row)                                                       #skipping rows upto header
    unless csv.blank?
      raise ">>>> Error in date field. Dates should be unique for all the batches" unless unique_date?

      if (@sitecode == '00Q49' && type == 'CORRESP' && csv[0][config['IMAGE']['image_file_name']].to_s.strip =~ /^\d+$/)  # DAP Correspondence logic
        @single_image_batch = true
        current_job_image = image_folder.detect{|file| File.extname(file) =~ /^.[t,T][i,I][f,F]$/ }
        dir_name = File.dirname(current_job_image)
        file_name = File.basename(current_job_image).split('.').first
        @page_count = %x[identify #{current_job_image}].split(File.basename(current_job_image)).length-1 rescue nil
        system("tiffsplit #{current_job_image} #{dir_name}/#{file_name}")
      end
      csv.each_with_index do |row, index|
        @row_index = index + 1
        @row = row
        if !@row[0].blank?
          load_flag = eval("InputBatch.is_#{type.downcase}_process(facility)") if job_condition
          if load_flag
            InputBatch::Log.status_log.info "**** Processing index file row #{@row_index} ****"
            save_records if valid_record?
          end
        end
      end
      @inbound_file_information.associate_to_report_check_informations if !@inbound_file_information.blank?
    end
    InputBatch::Log.write_log ">>>>>Index Transformation Ends " + Time.now.to_s

  end

  def call_parser_specific_method method_prefix
    method_suffix = @parser
    method = self.methods.include?("#{method_prefix}_#{method_suffix}".to_sym) ? "#{method_prefix}_#{method_suffix}" : method_prefix
    send(method)
  end

  #-----------------------------------------------------------------------------
  # Description : Saves batch first, then jobs, checks and images.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def save_records
    @new_batch_flag = 0
    (@parser == 'wellsfargo' && type == "CORRESP") ? prepare_wellfargo_corresp_batch : prepare_batch
    if @bat
      if @inbound_file_information
        @bat.inbound_file_information = @inbound_file_information
        @bat.arrival_time = arr_time = @inbound_file_information.arrival_time
        set_batch_time @bat, arr_time
      end
      @job_condition = job_condition
      if @job_condition
        @img_count = 1
        do_bank_logics if type == 'PAYMENT'        #Applying bank specific logic
      end
      images = call_parser_specific_method "prepare_image"
      images.each{|image| @bat.images_for_jobs << image}

      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}
       @job.initial_image_name =  @initial_image_name
      if @job_condition
        check = prepare_cheque
        if type == 'PAYMENT'
          micr = prepare_micr
          if micr
            payer = micr.payer
            check.payer_id = micr.payer_id if micr.payer_id
            if !facility.payer_ids_to_exclude.blank?
              @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
            elsif !facility.payer_ids_to_include.blank?
              @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
            end
            micr.check_informations << check
          end
        end
        @job.check_informations << check
      end
    end

    if @bat.save
      @bat.update_attributes(:status => BatchStatus::NEW)
      if @job.save
        images.each do |image|
#          if image.save
            if image.image_file_name.upcase  == @check_image.to_s.upcase
              save_image_types("CHK",image)
            elsif ((image.image_file_name.upcase  == @envelop_image.to_s.upcase) and (@job.job_status != JobStatus::EXCLUDED))
              save_image_types("ENV",image)
            elsif ((@job.job_status == JobStatus::EXCLUDED) and (image.image_file_name.upcase != @check_image.to_s.upcase))
              save_image_types("OTH",image)
            end
            total_number_of_images = number_of_pages(@job)
            check_number = check.check_number if !check.blank?
            estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
            @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)
    
            InputBatch::Log.status_log.info "Image #{image.image_file_name}
                  id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id}
                  successfully loaded"
            puts "Image #{image.image_file_name} successfully loaded" if !image.size.blank?
#          else
#            raise "Error on line #{@row_index} : Cannot load image #{image.image_file_name}"
#          end
        end
        if @job_condition and check.save
          InputBatch::Log.status_log.info "Check id #{check.id}, check_number
                #{check.check_number}, Job id #{check.job.id}, batch id #{check.job.batch.id}
                successfully loaded"
          if micr and micr.save
            InputBatch::Log.status_log.info "Check #{check.id} associated to micr
                #{check.micr_line_information.id}"
            @job.save_payer_group(micr)
          end

        end
      else
        raise "Error on line #{@row_index} : Cannot save job for batch #{@bat.batchid}"
      end
    else
      raise "Error on line #{@row_index} : Cannot save batch"
    end
    "#{@bat.date.strftime("%Y%m%d")}_#{@bat.batchid}_SUPPLEMENTAL_OUTPUT" rescue nil
  end

  #-----------------------------------------------------------------------------
  # Description : This method  check if the batch already exists in application
  #               database. The parsing will be discarded if the batch already
  #               exists. Otherwise it will create a new batch object and sets
  #               parameters to the object.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_batch
    if  $IS_PARTNER_BAC
      prepare_bank_batch
    else
      index_batchid = parse(config['BATCH']['index_batch_number']).to_s
      if @current_batchid != index_batchid
        @current_batchid = index_batchid
        @new_batch_flag = 1
      end
      batchid = find_batchid
      batch = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id =>\
            facility.id})
      @batch_condition = batch.nil? and @batchid != batchid
      if @batch_condition && @corresp_flag
        @corresp_flag = false if (@version == 'BANK_OF_AMERICA' && type == 'CORRESP')
        @bat = Batch.new
        @job_index = 0
        InputBatch::Log.write_log "Preparing batch #{batchid}"
        InputBatch::Log.write_log type
        parse_values("BATCH", @bat)
        @@batch_date = @bat.date if !@bat.date.blank?
        @bat = update_batch @bat
        @bat.batchid = batchid
        @bat.file_meta_hash = file_meta_hash
      else
        if @batchid != batchid && @corresp_flag
          InputBatch::Log.write_log "Batch #{batchid} already loaded"
          @bat = nil
        end
      end
      @batchid = batchid
    end
  end

  def prepare_bank_batch
    index_batchid = parse(config['BATCH']['index_batch_number']).to_s
    if @current_batchid != index_batchid
      @current_batchid = index_batchid
      @new_batch_flag = 1
    end
    if @new_batch_flag == 1 && @corresp_flag
      @bat = Batch.create(:batchid => 'dummy', :status => BatchStatus::LOADING)
      @bat.batchid = create_bank_batchid
      @corresp_flag = false if (@version == 'BANK_OF_AMERICA' && type == 'CORRESP')
      @job_index = 0
      InputBatch::Log.write_log "Preparing batch #{@bat.batchid}"
      InputBatch::Log.write_log type
      parse_values("BATCH", @bat)
      @@batch_date = @bat.date if !@bat.date.blank?
      @bat = update_batch @bat
    end
  end

  def create_bank_batchid
    batchid = (@bat.id - 1)
    (FIRST_BATCH_ID - batchid ).to_s(36).upcase
  end

  #-----------------------------------------------------------------------------
  # Description : This method is to aggregate all the correspondence batches within
  #               a Wells Fargo Cut (which could include multiple files into one
  #               single batch.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_wellfargo_corresp_batch
    lockbox_number = parse(config["BATCH"]["lockbox"]).to_s
    deposit_date = parse(config["BATCH"]["date"][0]).to_s
    deposit_date = Date.rr_parse(deposit_date)
    index_batch_number = parse(config['BATCH']['batchid']).to_s
    reconciliation_informations = ReconciliationInformation.find_all_by_deposit_date_and_lockbox_number(deposit_date, lockbox_number)
    raise "ERROR >> Reconciliation information not found for this cut. Please load reconciliation csv first. Command: 'rake new_input:import_reconciliation_csv['<path>']'" if reconciliation_informations.blank?
    current_batch = reconciliation_informations.detect{|ri| ri.index_batch_number.to_s.strip == index_batch_number}
    raise "ERROR >> This batch(batchid: #{index_batch_number}) is not mentioned in reconciliation CSV. PLease check it" if current_batch.blank?


    batch_ids_in_cut = reconciliation_informations.collect(&:index_batch_number)
    corresp_batch_ids = batch_ids_in_cut.select{|id|(900..999).include?(id.to_i)}
    @bat = Batch.find_by_date_and_lockbox(deposit_date, lockbox_number)
    unless @bat
      raise "ERROR >> This batch(batchid: #{index_batch_number}) has already been loaded" if current_batch.is_batch_loaded
      payment_batch_ids = batch_ids_in_cut - corresp_batch_ids
      prepare_batch
      @bat.index_batch_number = payment_batch_ids.blank? ? '2' : payment_batch_ids.sort.last.to_i + 1
    end

    current_batch.update_attributes(:is_batch_loaded => 1)
    @bat.status = (reconciliation_informations.detect{|ri| (900..999).include?(ri.index_batch_number.to_i) && !ri.is_batch_loaded }).blank? ? BatchStatus::NEW : 'Incomplete Cut'
  end

  #-----------------------------------------------------------------------------
  # Description : This will create a new check_information object and sets
  #               parameters to the object by reading the column header positions
  #               under CHEQUE section in configuration YML file.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_cheque
    check = CheckInformation.new
    parse_values("CHEQUE", check) if type == "PAYMENT"
    cheque = update_check check
    return check
  end

  #-----------------------------------------------------------------------------
  # Description : This will create a job object and sets parameters to the object
  #               by reading the column header positions under JOB section in
  #               configuration YML file.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_job
    if @job_condition
      @job = Job.new
      @job_index = @job_index
      parse_values("JOB", @job)
      @job.guid_number= parse("guid_number")
      @job = update_job @job
      @jobs << @job
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This will create a micr_line_information object and sets
  #               parameters to the object by reading the column header positions
  #               under MICR section in configuration YML file.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_micr
    if config["MICR"]
      aba_routing_number = parse(config["MICR"]["aba_routing_number"])
      payer_account_number = parse(config["MICR"]["payer_account_number"])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end   
  end

  #-----------------------------------------------------------------------------
  # Description : This will create an images_for_job object and sets parameters
  #               to the object by reading the column header positions under
  #               IMAGE section in configuration YML file.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_image
    images_for_job = []
    images = []
    @images_from_index = row.slice(config['IMAGE']['image_file_name'][0]..-1).compact
    @images_from_index = @images_from_index.collect{|file| file.include?('.') ? \
        file: file + ".#{@image_ext}"}
    # identifying check and envelop images
    @check_image, @envelop_image = call_parser_specific_method  "prepare_check_and_envelop_images"  if @version == 'BANK_OF_AMERICA' and facility.index_file_parser_type != "Apria_bank"
    envelop_image_to_loaded = (@envelop_image.upcase)[0...-4].split("_")  unless @envelop_image.blank?
    @image_folder = Dir.glob("#{@location}/**/#{config['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
    @images_from_index.each do |file_name|
      unless @hash_envelop_images.has_key?("#{file_name}")
        images_for_job << @image_folder.select{|file| File.basename(file).upcase == file_name.upcase}
        images_for_job << @image_folder.select{|file| file_name[0...-4] + "B" == File.basename(file)[0...-4].upcase}
          
      else
        unless @envelop_image.blank?
              images_for_job << @image_folder.select{|file| File.basename(file).upcase == @envelop_image.upcase ||
              File.basename(file)[0...-4].upcase == @envelop_image.upcase[0...-4] +'B'}
          if envelop_image_to_loaded.size == 2
            @image_folder = Dir.glob("#{@location}/**/#{config['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
            images_for_job << @image_folder.select{|file| File.basename(file)[0...-4].upcase == envelop_image_to_loaded[0]+'B_'+ envelop_image_to_loaded[1]}
          end
        end
      end
    end
    images_for_job.flatten!
   # @initial_image_name = images_for_job[0]
    multi_page_facilities = ['CHRISTIAN HOSPITAL LABORATORY','GENOPTIX MEDICAL LABORATORY']
    images_for_job = convert_single_page_to_multipage(images_for_job) if multi_page_facilities.include? facility.name.strip.upcase
    f = nil
    images_for_job.each_with_index do |image_name,img_count|
      f = File.open("#{image_name}","rb")
      image = ImagesForJob.new(:image => f)
      parse_values("IMAGE", image, File.basename(image_name))
      image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
     # initial_image = images_for_job[0]
      @initial_image_name = image_file_name if img_count == 0
      path =  Dir.glob("#{@location}/**/#{image_file_name}").first
      count = %x[identify "#{path}"].split(image_file_name).length-1
      new_image_name = File.basename("#{path}")
      if count>1
        dir_location = File.dirname("#{path}")
        ext_name = File.extname("#{path}")
        new_image_base_name = new_image_name.chomp("#{ext_name}")
        if ((not ext_name.empty?) and (ext_name.casecmp(".pdf") == 0) ) then
          system "pdftk  '#{path}' burst output '#{dir_location}/#{new_image_base_name}_%d#{ext_name}'"
          for image_count in 1..count
            image = ImagesForJob.new(:image_file_name=>"#{new_image_base_name}_#{image_count}#{ext_name}",:is_splitted_image=>true)
            image = update_image image
            image.save
            images << image
          end
        else
          InputBatch.split_image(count,path, dir_location, new_image_base_name)
          single_images = Dir.glob("#{@location}/**/*").select{|file| InputBatch.get_single_image(file, new_image_base_name)}.sort
          single_images.each_with_index do |single_image, index|
            new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
            File.rename(single_image, new_image_name)
            image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
            @img_count += 1
            images << image
          end
        end
      else
        # image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
        image = update_image image
        image.save
        images << image
      end
      f.close
    end
    return images
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to batch object
  #               that are not parsed from index file during batch loading
  # Input       : Batch object
  # Output      : Batch object
  #-----------------------------------------------------------------------------
  def update_batch batch
    batch.file_name = @zip_file_name
    batch.arrival_time = arr_time = Time.now
    batch.facility_id = facility.id
    batch.client_id = facility.client_id
    set_batch_time batch, arr_time
    if batch.date.blank?
      batch.date = facility.index_file_parser_type.to_s.downcase == 'boa_bank'? @@batch_date : Date.today
    end
    batch.correspondence = true if type == 'CORRESP'
    if !@corresp_flag
      last_batch = Batch.find(:last, :conditions => ["file_name = ? ", @zip_file_name])
      last_batch_corresp = Batch.find(:last, :conditions => ["file_name = ? and correspondence = 'true'", @zip_file_name])
      @index_condition = ((type == 'CORRESP' and (!(last_batch.nil?)) and (last_batch_corresp.nil?)) or (type == 'CORRESP' and (!(last_batch.nil?)) and !(last_batch_corresp.nil?) and (last_batch.id>last_batch_corresp.id)))
      batch.index_batch_number =  @index_condition ?  (last_batch.index_batch_number.to_i + 1) : 2
    end
    batch.lockbox = batch.lockbox.split('-').last if batch.lockbox
    return batch
  end
  
  def set_batch_time batch, arr_time
    batch.contracted_time = (arr_time + facility.tat.to_i.hours)
    batch.target_time = (arr_time + facility.tat.to_i.hours)
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to job object
  #               that are not parsed from index file during batch loading
  # Input       : Job object
  # Output      : Job object
  #-----------------------------------------------------------------------------
  def update_job job
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
    return job
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to CheckInformation
  #               object that are not parsed from index file during batch loading
  # Input       : CheckInformation object
  # Output      : CheckInformation object
  #-----------------------------------------------------------------------------
  def update_check check
    check.check_number = '0' if check.check_number.blank?
    check.check_amount = 0.0 if check.check_amount.blank?
    check.check_amount = check.check_amount.to_f
    return check
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to image object
  #               that are not parsed from index file during image loading
  # Input       : Image object
  # Output      : Image object
  #-----------------------------------------------------------------------------
  def update_image image
    temp_path = @image_folder.detect{|image_string| image_string.downcase == "#{@image_path}/#{image.image_file_name}".downcase}
    filename = File.basename(temp_path)
    image.image_number = @img_count

    @img_count += 1
    if temp_path.blank?
      InputBatch::Log.status_log.error ">>>>>>>>Image #{filename} not found<<<<<<<<<"
      puts ">>>>>>>>>>>>Image #{filename} not found"
      InputBatch::Log.error_log.error "Error on line #{@row_index} : Image #{filename} not found"
    else
      InputBatch::Log.status_log.info "Image #{filename}  found"
      image.page_count = %x[identify #{temp_path}].split(filename).length-1 rescue nil
    end

    rename_image image if facility.index_file_parser_type == "WellsFargo_bank"
    return image
  end

  #Saving values in image_types table

  def save_image_types type_of_image, job_image
    @image_type = ImageType.new
    @image_type.image_type = type_of_image
    @image_type.images_for_job_id = job_image.id
    @image_type.image_page_number = job_image.image_number
    @image_type.save
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for parsing values from index file using column
  #               index and saving the value into corresponding object.
  # Input       : YML object, model object,
  # Output      : None
  #-----------------------------------------------------------------------------
  def parse_values(data, object, count = nil)
    config[data].each do |k,v|
      if v.class == Array
        if v[1] == "date"
          object[k] = v[2] ? Date.strptime(parse(v[0]), v[2]) : Date.rr_parse(parse(v[0]),\
              true) rescue nil
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0]))
        else
          object[k] = count
        end
      elsif v.class == Hash
        object.details = Hash.new
        v.each do |key, value|
          object.details[key] =  parse(value)
        end
      else
        object[k] = parse(v)
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for doing bank specific logics such as transpose
  #               and warrant logics for payment batches.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def do_bank_logics
    aba = parse(config["MICR"]["aba_routing_number"])
    payer_account_number = parse(config["MICR"]["payer_account_number"])
    check_number = parse(config['CHEQUE']['check_number'])
    if facility.details[:is_transpose]
      transpose = InputBatch.do_transpose(@bat, aba, check_number)
      if transpose
        row[config["MICR"]["payer_account_number"]], row[config['CHEQUE']['check_number']]\
          = row[config['CHEQUE']['check_number']], row[config["MICR"]["payer_account_number"]]
      end
    end
    if facility.details[:is_warrant]
      if aba == WARRANT_ABA
        row[config['CHEQUE']['check_number']] , row[config["MICR"]["payer_account_number"]]\
          = row[config["MICR"]["payer_account_number"]], WARRANT_PAYER_ACCOUNT_NUMBER
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for formatting amount values.
  # Input       : Amount string
  # Output      : Formatted amount
  #-----------------------------------------------------------------------------
  def parse_amount amount_string
    if amount_string.index(".") == 0
      amount_str = "0"+amount_str.to_s
    end
    amount_string.gsub(/[^\d\.]/, "").scan(/\d+\.?\d*/)[0].to_f rescue nil
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for parsing particular column value from index
  #               file. parse_value method uses this method to extract values.
  # Input       : Column index
  # Output      : Extracted value
  #-----------------------------------------------------------------------------
  def parse(v)
    row[v].strip rescue nil
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for selecting type and version from YML file.
  # Input       : None
  # Output      : Type and version
  #-----------------------------------------------------------------------------
  def config
    @config_hash[@version][type] rescue @config_hash['GENERAL']['PAYMENT']
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for identifying occurence of job details from
  #               index file .
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def job_condition
    config['BATCH']['record_type'] ? parse(config['BATCH']['record_type'] )== 'CHK' : true
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for creating batchid based on the specifications.
  # Input       : None
  # Output      : Batchid string
  #-----------------------------------------------------------------------------
  def find_batchid
    if @version == 'BANK_OF_AMERICA'
      if @new_batch_flag == 1
        InputBatch.get_batchid
      else
        batch =  Batch.find(:last,:conditions=>"client_id = #{client.id} and file_name = '#{@zip_file_name}'")
        if !batch.blank?
          batch.batchid
        else
          InputBatch.get_batchid
        end
      end
    else
      get_batchid_general
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for generating batchid for non-banking clients.
  # Input       : None
  # Output      : Batchid string
  #-----------------------------------------------------------------------------
  def get_batchid_general
    if ['GENOPTIX MEDICAL LABORATORY','METROHEALTH SYSTEM','FRONT LINE'].include?(facility.name.upcase)
      @zip_file_name[0...-4]                                   #batch id is the last segment of quadax zip file name (excluding '.zip')
    else
      batchid = parse(config['BATCH']['batchid'])
      date = parse(config['BATCH']['date'][0])
      batch_date = Date.rr_parse(date, true).strftime("%m%d%Y") rescue nil
      "#{batchid}_#{batch_date}"
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for calculating number of pages in a multipage
  #               tiff file.
  # Input       : Job object
  # Output      : Number of pages
  #-----------------------------------------------------------------------------
  def number_of_pages job
    count = 0
    pages = job.client_images_to_jobs.length
    if (@facility.image_type == 1) && (pages < 2)
      job.images_for_jobs.each do |image|
        image_path = @image_folder.detect{|image_string| image_string.downcase == "#{@image_path}/#{image.image_file_name}".downcase}
        count += %x[identify #{image_path}].split(image.image_file_name).length-1 rescue nil            #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for finding wheather the current row is need to
  #               processed.
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def valid_record?
    status = (config['BATCH']['record_type']? parse(config['BATCH']['record_type'] ) != 'INV' : true)
    return status
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for finding index file type.
  # Input       : Index file
  # Output      : Type string
  #-----------------------------------------------------------------------------
  def find_type
    @index_file_name == 'corresp.csv' ? 'CORRESP' : 'PAYMENT'
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for finding index file type of WellsFargo.
  # Input       : Index file
  # Output      : Type string
  #-----------------------------------------------------------------------------
  def find_type_wellsfargo
    batch_id = csv[0][(config_hash['BANK_OF_AMERICA']['PAYMENT']['BATCH']['batchid'])].to_i
    (900..999).include?(batch_id) ? 'CORRESP' : 'PAYMENT'
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for finding index file type of Apria.
  # Input       : Index file
  # Output      : Type string
  #-----------------------------------------------------------------------------
  def find_type_apria
    csv[0][0].to_s.strip.downcase =~ /^denials*$/ ? 'CORRESP' : 'PAYMENT'
  end

  #-----------------------------------------------------------------------------
  # Description : This will create an images_for_job object and sets parameters
  #               to the object by reading the column header positions under
  #               IMAGE section in configuration YML file.(Only for Apria)
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_image_apria
    images = []
    if @sitecode ==  "00Q49" # site code for DAP
      single_page_images = convert_multipage_to_singlepage
      single_page_images.each_with_index do |image_file, index|
        new_file_name = rename_image_for_dap(image_file, index)
        File.rename(image_file, new_file_name)
        @image_folder = Dir.glob("#{@location}/**/#{config['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
        image = ImagesForJob.new :image => File.open("#{new_file_name}","rb")
        image.image_file_name = File.basename(new_file_name)
        image.is_splitted_image = true
        image = update_image image
        images << image
      end
    else
      image = ImagesForJob.new
      parse_values("IMAGE", image)
      image_path = @image_folder.detect{|image_string| image_string.downcase == "#{@image_path}/#{image.image_file_name}".downcase}
      image.image = File.open(image_path, "rb")
      image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
      path =  Dir.glob("#{@location}/**/#{image_file_name}").first
      count = %x[identify "#{path}"].split(image_file_name).length-1
      new_image_name = File.basename("#{path}")
      if count>1
        dir_location = File.dirname("#{path}")
        ext_name = File.extname("#{path}")
        new_image_base_name = new_image_name.chomp("#{ext_name}")
        if ((not ext_name.empty?) and (ext_name.casecmp(".pdf") == 0) ) then
          system "pdftk  '#{path}' burst output '#{dir_location}/#{new_image_base_name}_%d#{ext_name}'"
          for image_count in 1..count
            image = ImagesForJob.new(:image_file_name=>"#{new_image_base_name}_#{image_count}#{ext_name}",:is_splitted_image=>true)
            image = update_image image
            images << image
          end
        else
          InputBatch.split_image(count,path, dir_location, new_image_base_name)
          single_images = Dir.glob("#{@location}/**/*").select{|file| InputBatch.get_single_image(file, new_image_base_name)}.sort
          single_images.each_with_index do |single_image, index|
            new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
            File.rename(single_image, new_image_name)
            image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count, :is_splitted_image=>true)
            @img_count += 1
            images << image
          end
        end
      else
        image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
        image = update_image image
        images << image
      end
    end
    return images
  end


  def rename_image_for_dap(image_file, index)
    @image_count ||= 1
    original_image_name = File.basename(image_file).split('.').first
    if @single_image_batch
      new_image_name = original_image_name.gsub('DOC', 'SP')
      new_image_name[-6..-1] = "%05d" % @image_count
      @image_count += 1
    else
      new_image_name = original_image_name.gsub('DOC', 'S')
      new_image_name[-3..-1] = "%04d" % (index + 1)
    end
    image_file.gsub(original_image_name, new_image_name)
  end

  def convert_multipage_to_singlepage
    begin
      if @single_image_batch
        page_from = parse(config['IMAGE']['image_file_name']).to_i
        page_to = csv[@row_index].blank? ? @page_count : csv[@row_index][config['IMAGE']['image_file_name']].to_i - 1
        image_folder.select{|file| File.extname(file) =~ /^.[t,T][i,I][f,F]$/}.sort[page_from..page_to]
      else
        current_job_image = @image_folder.select{|file| File.basename(file) == parse(config["IMAGE"]['image_file_name'])}[0]
        dir_name = File.dirname(current_job_image)
        file_name = File.basename(current_job_image).split('.').first
        system("tiffsplit #{current_job_image} #{dir_name}/#{file_name}")
        image_folder.select{|file| File.basename(file).split('.').first =~ /#{file_name}[a-z][a-z][a-z]/}.sort
      end
    rescue
      InputBatch::Log.error_log.error ">>>>>>>>>>>>>>>> Error while converting multipage to single page <<<<<<<<<<<<<<"
      puts ">>>>>>>>>>>>>>>> Error while converting multipage to single page <<<<<<<<<<<<<<"
    end
  end


  #-----------------------------------------------------------------------------
  # Description : This method is for converting single page images to multipage
  #               for non-bank BOA client CHRISTIAN HOSPITAL LABORATORY  .
  # Input       : Array of single page images for a job
  # Output      : converted multipage image.
  #-----------------------------------------------------------------------------
  def convert_single_page_to_multipage(single_page_images)
    begin
      check_image = "#{File.dirname(single_page_images.first)}/#{parse(config["IMAGE"]["image_file_name"][0])}#{File.extname(single_page_images.first)}"
      system("tiffcp -a #{single_page_images.push(single_page_images.delete(check_image)).join(' ')}")
      [check_image]
    rescue
      InputBatch::Log.error_log.error ">>>>>>>>>>>>>>>> Error while converting single page to multipage <<<<<<<<<<<<<<"
      puts ">>>>>>>>>>>>>>>> Error while converting single page to multipage <<<<<<<<<<<<<<"
    end
  end

  def image_page_count image
    count = 0
    pages = image.client_images_to_jobs.length
    if (@facility.image_type == 1) && (pages < 2)
      count = %x[identify #{@image_path}].split(image.image_file_name).length-1 rescue nil            #command for retrieve number of pages in a  tiff file (multi/single)
      pages = count
    end
    pages
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for renaming original Image File name by prefixing
  #               the original bank batch ID for Wellsfargo parser.
  # Input       : ImagesForJob object
  # Output      : None
  #-----------------------------------------------------------------------------
  def rename_image image
    begin
      File.rename("#{@location}/#{image.image_file_name}", "#{@location}/#{@bat.index_batch_number}#{image.image_file_name}")
      image.image_file_name = "#{@bat.index_batch_number}#{image.image_file_name}"
      temp_path = "#{@image_path}/#{image.image_file_name}"
    rescue
      InputBatch::Log.error_log.error ">>>>>>>>>>>>>>>> Error while renaming image, Probably due to file name or directory mismatch <<<<<<<<<<<<<<"
      puts ">>>>>>>>>>>>>>>> Error while renaming image, Probably due to file name or directory mismatch <<<<<<<<<<<<<<"
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method checks if the date field in the index file has the
  #               same value for all the batches within a lockbox file. If the
  #               date value is different then error the file out.
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def unique_date?
    if config['BATCH']['date']
      date_index = config['BATCH']['date'][0]
      dates = csv.collect{|row| row[date_index]}.compact
      dates.uniq.length == 1
    else
      true
    end
  end

  def prepare_check_and_envelop_images_wellsfargo
    if ( parse(config['BATCH']['record_type']) == "CHK")
      index_file_images = row.slice(config['IMAGE']['image_file_name'][0]..-1)
      index_file_images = index_file_images.collect{|file|
        ((!file.blank?)? ( file.include?('.') ?  file: file + ".#{@image_ext}" ) : "")}
      check_image =  "#{@bat.index_batch_number}#{index_file_images[0]}"
      return check_image
    end
  end

  def prepare_check_and_envelop_images
    check_image = nil
    new_envelop_image = nil
    index_file_images = row.slice(config['IMAGE']['image_file_name'][0]..-1)
    index_file_images = index_file_images.collect{|file|
      ((!file.blank?)? ( file.include?('.') ?  file: file + ".#{@image_ext}" ) : "")}

    (type == 'PAYMENT')? (check_image,envelop_image = index_file_images[0..1]):(envelop_image = index_file_images[0])
    if (type == 'PAYMENT')
      if @hash_envelop_images.has_key?("#{envelop_image}")
        envelop_image_back = envelop_image[0...-4]+"B.#{@image_ext}"
        envelop_image_back_lowercase = envelop_image[0...-4]+"b.#{@image_ext}"
        @envelop_image_folder = Dir.glob("#{@location}/**/#{config['IMAGE']['image_folder']}", File::FNM_CASEFOLD)[0]
        @hash_envelop_value += 1
        if @hash_envelop_value > 0
          new_envelop_image = envelop_image[0...-4].split("_")[0]+"_#{@hash_envelop_value}"+".#{@image_ext}"
          system("cp \"#{@image_path}/#{envelop_image}\" \"#{@image_path}/#{new_envelop_image}\"")
          if File.exist?("#{@image_path}"+"/#{envelop_image_back}")
            new_envelop_image_back = envelop_image_back[0...-4].split("_")[0]+"_#{@hash_envelop_value}"+".#{@image_ext}"
            system("cp \"#{@image_path}/#{envelop_image_back}\" \"#{@image_path}/#{new_envelop_image_back}\"")
          end
          if File.exist?("#{@image_path}"+"/#{envelop_image_back_lowercase}")
            new_envelop_image_back_lowercase = envelop_image_back_lowercase[0...-4].split("_")[0]+"_#{@hash_envelop_value}"+".#{@image_ext}"
            system("cp \"#{@image_path}/#{envelop_image_back_lowercase}\" \"#{@image_path}/#{new_envelop_image_back_lowercase}\"")
          end
        end
      else
        @hash_envelop_value = 0
      end
      @hash_envelop_images = {"#{envelop_image}"=>"#{@hash_envelop_value}"} unless envelop_image.blank?
    end
    new_envelop_image =  new_envelop_image.blank?? envelop_image : new_envelop_image
    return check_image,new_envelop_image
  end

  def load_zero_byte_batch
    @bat = Batch.create(:batchid => 'dummy')
    @bat.batchid = create_bank_batchid
    @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
    InputBatch::Log.write_log "Loading zero byte batch #{@bat.batchid}"
    update_batch @bat
    @bat.status = BatchStatus::COMPLETED
    lockbox_identifier = Lockbox::Identification.new @zip_file_name
    lockbox_identifier.parse
    @bat.lockbox = lockbox_identifier.lockbox
    @bat.correspondence = nil
    @bat.index_batch_number = 0
    @bat.save
  end

 
  #-----------------------------------------------------------------------------
  # Description : Content of the temperory image folder may get changed in
  #               between batch loading(like image splitting). So we are using a
  #               method call to get the contents.
  # Input       : None
  # Output      : Array of image files plus index file
  #-----------------------------------------------------------------------------
  def image_folder
    Dir.glob("#{@location}/**/#{config['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
  end

end
