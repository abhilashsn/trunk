require 'yaml'
require 'input_batch'

################################################################################
# Description : Base class used for txt index file parsing and batch loading. The
#               details of which columns of the txt file to parse to get data is
#               written in a seperate yml file different for different facilities.
#               So new facility can be done by creating new configuration(yml) file.
#               Now this parser is used only for facility 'COUG'
# Created     : 11-08-11 by Sunil Antony @ Revenuemed
################################################################################
class InputBatch::IndexTxtTransformer 
  attr_accessor :txt_lines, :config_yml, :facility, :row, :type, :file_meta_hash
  

  #-----------------------------------------------------------------------------
  # Description : This method initialize the parser class.
  # Input       : config file, facility, extracted zip location, zip_file_name
  # Output      : None
  #-----------------------------------------------------------------------------
  def initialize(config, facility, location, zip_file_name, inbound_file_information = nil)
    @config_yml = YAML::load(File.open(config))
    @facility = facility
    @location = location
    @zip_file_name = zip_file_name
    @inbound_file_information = inbound_file_information
  end

  #-----------------------------------------------------------------------------
  # Description : This method parses the input txt file and  saves the retrieved
  #               data to application database.
  # Input       : txt file name
  # Output      : None
  #-----------------------------------------------------------------------------
  def transform index_file
    InputBatch.log.info "Opened txt file for processing"
    puts "Opened txt file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @txt_lines = File.readlines(index_file)
    txt_lines.each do |row|
      @row = row.chomp
      save_records
    end

    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  #-----------------------------------------------------------------------------
  # Description : Saves batch first, then jobs, checks and images.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def save_records
    @job_condition = job_condition
    find_type
    prepare_batch

    if @batch
      @image_count = 1 if @job_condition
      @batch.inbound_file_information = @inbound_file_information if @inbound_file_information

      images = prepare_image
      images.each{|image| @batch.images_for_jobs << image}

      prepare_job
      @batch.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}

      if @job_condition
        check = prepare_cheque
        @job.check_number = '0' if check.check_amount == 0.0
        @job.check_informations << check
        @job.initial_image_name = @initial_image_name
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
      
      if @batch.save
        if @job.save
          images.each do |image|
            if image.save
              InputBatch.log.debug "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
              puts "Image #{image.filename} successfully loaded"
            end
          end

          total_number_of_images = number_of_pages(@job)
          check_number = check.check_number if !check.blank?
          estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
          @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

          if @job_condition and check.save
            InputBatch.log.debug "Check id #{check.id}, check_number #{check.check_number}, Job id #{check.job.id}, batch id #{check.job.batch.id} successfully loaded"
            if micr and micr.save
              InputBatch.log.debug "Check #{check.id} associated to micr #{check.micr_line_information.id}"
              @job.save_payer_group(micr)
            end
          end
        end
      end
    end
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
    batchid = parse(config["BATCH"]["batchid"])
    batch = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = batch.nil? and @batchid != batchid
    if @batch_condition
      @batch = Batch.new
      @job_index = 0
      puts "Preparing batch #{batchid}"
      puts type
      InputBatch.log.debug "Preparing batch #{batchid}"
      parse_values("BATCH", @batch)
      @batch = update_batch @batch
      @batch.batchid = batchid
      @batch.file_meta_hash = file_meta_hash
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @batch = nil
      end
    end
    @batchid = batchid
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
    parse_values("CHEQUE", check)
    check = update_check check
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
      parse_values("JOB", @job)
      @job = update_job @job
      @jobs << @job
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
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    images,@initial_image_name = InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
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
  
  #### methods for setting values which are not parsed from index file during batch loading ####


  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to batch object
  #               that are not parsed from index file during batch loading
  # Input       : Batch object
  # Output      : Batch object
  #-----------------------------------------------------------------------------
  def update_batch batch
    batch.file_name = @zip_file_name
    batch.arrival_time = Time.now
    batch.facility_id = facility.id
    batch.client_id = facility.client_id
    batch.contracted_time = (Time.now + facility.tat.to_i.hours)
    batch.target_time = (Time.now + facility.tat.to_i.hours)
    batch.date = Date.today if batch.date.blank?
    batch.bank_deposit_date = Date.today if batch.bank_deposit_date.blank?
    batch.correspondence = true if type == 'CORRESP'
    return batch
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
    if check.check_amount.blank? or check.check_amount == 0.01
      check.check_amount = 0.0
      check.check_amount = check.check_amount.to_f
      check.check_number = '0'
    end
    return check
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for finding batch type.
  # Input       : Index file
  # Output      : None
  #-----------------------------------------------------------------------------
  def find_type
    if @job_condition
      @type = (row[88].chr == 'C') ? 'PAYMENT' : 'CORRESP'
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for parsing values from index file using column
  #               index and saving the value into corresponding object.
  # Input       : YML object, model object,
  # Output      : None
  #-----------------------------------------------------------------------------
  def parse_values(data, object)
    config[data].each do |k,v|
      if v[2]
        if v[2] == 'date'
          object[k] = Date.strptime(parse(v), "%y%m%d") rescue nil
        elsif v[2] == "float"
          object[k] = parse_amount(parse(v))
        end
      else
        object[k] = parse(v)
      end
    end
  end


  #-----------------------------------------------------------------------------
  # Description : This method is for parsing particular column value from index
  #               file. parse_value method uses this method to extract values.
  # Input       : Column index
  # Output      : Extracted value
  #-----------------------------------------------------------------------------  
  def parse(v)
    row[v[0]..v[1]].strip rescue nil
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for selecting type and version from YML file.
  # Input       : None
  # Output      : Type and version
  #----------------------------------------------------------------------------- 
  def config
    config_yml['PAYMENT']
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for identifying occurence of job details from
  #               index file .
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def job_condition
    batchid = parse(config["BATCH"]["batchid"])
    job_sequence_number = parse([84, 87])
    if (batchid != @prev_batchid) || (@prev_job_sequence != job_sequence_number)
      @prev_job_sequence = job_sequence_number
      @prev_batchid = batchid
      true
    else
      false
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for formatting amount values.
  # Input       : Amount string
  # Output      : Formatted amount
  #-----------------------------------------------------------------------------
  def parse_amount amount_string
    if amount_str.index(".") == 0
      amount_str = "0"+amount_str.to_s
    end
    amount_string.gsub(/[^\d\.]/, "").scan(/\d+\.?\d*/)[0].to_f rescue nil
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
        path =  Dir.glob("#{@location}/**/#{image.filename}").first
        count += %x[identify #{path}].split(image.filename).length-1            #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end

  def update_image image
    image.image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    image_path = Dir.glob("#{@location}/**/#{image.image_file_name}")[0]
    image.image = File.open("#{image_path}","rb")
    image.image_number = @img_count
    @img_count += 1
    if Dir.glob("#{@location}/**/#{image.filename}")[0]
      InputBatch.log.info "Image #{image.filename} found"
    else
      InputBatch.log.info "Image #{image.filename} not found"
    end
    return image
  end

end 


