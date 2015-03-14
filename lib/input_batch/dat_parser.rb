require 'yaml'
require 'input_batch'

#######################################################################################
# Description : This class is responsible for parsing index file from Wachovia lockbox.
#               It gets a file object as its input and parses all the records in
#               the dat file, parses data and save the data to the application 
#               database.
# Created     : 09-02-11 by Abilu Bin Akbar @ Revenuemed
########################################################################################
class InputBatch::DatParser
  attr_accessor :dat, :cnf, :facility, :row, :type, :file_meta_hash
  
    
  def initialize(cnf, facility, location, zip_file_name, inbound_file_information)
    @cnf = YAML::load(File.open(cnf))
    @facility = facility
    @location = location
    @zip_file_name = zip_file_name
    @fac_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @client_id = facility.client.id
    @flag = 0
    @inbound_file_information = inbound_file_information
  end

  #-----------------------------------------------------------------------------
  # Description : This method parses the input dat file and  saves the retrieved
  #               data to application database.                   
  # Input       : Dat file name
  # Output      : None
  #----------------------------------------------------------------------------- 
  def transform cvs
    @version = find_version
    @corresp_flag = true
    InputBatch::Log.write_log "Opened dat file for processing"
    InputBatch::Log.write_log ">>>>>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @dat = File.readlines(cvs) rescue []
    load_flag = false
    dat.each_with_index do |row, index|
      @row_index = index + 1
      @row = row.chomp
      find_type
      raise ">>>> Error in date field. Dates should be unique for all the batches" unless unique_date?
      InputBatch::Log.status_log.info "**** Processing index file row #{@row_index} ****"
      @index_file_batchid = parse(conf["BATCH"]["batchid"])
      if @prev_index_file_batchid != @index_file_batchid
        @new_batch_condition = true
        @prev_index_file_batchid = @index_file_batchid
      else
        @new_batch_condition = false
      end
      @job_condition = job_condition
      load_flag =  eval("InputBatch.is_#{type.downcase}_process(facility)") if @job_condition
      if load_flag
        save_records
        load_flag = true
      end
    end
    @inbound_file_information.associate_to_report_check_informations if !@inbound_file_information.blank?
    InputBatch::Log.write_log ">>>>>Index Transformation Ends " + Time.now.to_s
  end

  #-----------------------------------------------------------------------------
  # Description : Saves batch first, then jobs, checks and images.
  # Input       : None 
  # Output      : None
  #----------------------------------------------------------------------------- 
  def save_records
    if type
      prepare_batch

      if @bat
        @img_count = 1 if @job_condition
        if @inbound_file_information
          @bat.inbound_file_information = @inbound_file_information
          @bat.arrival_time = @inbound_file_information.arrival_time
        end
        images,@initial_image_name = prepare_image
        images.each{|image| @bat.images_for_jobs << image}

        prepare_job
        @bat.jobs << @job if @job_condition
        images.each{|image| @job.images_for_jobs << image}

        if @job_condition
          chk = prepare_cheque
          @job.check_informations << chk
          @job.initial_image_name = @initial_image_name
          if type == 'PAYMENT'
            mic = prepare_micr
            @job.check_informations << chk
            if mic
              if mic.payer_id
                payer = mic.payer
                chk.payer_id = mic.payer_id
                if InputBatch.is_exclude_payer( facility, chk.payer_id)
                  @job.delete
                  @type = nil
                  @flag = 1
                end
                if !facility.payer_ids_to_exclude.blank?
                  @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
                elsif !facility.payer_ids_to_include.blank?
                  @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
                end
              end
              mic.check_informations << chk
            end
          end
        end

        if @flag == 0
          if @bat.save
            if @job.save
              images.each do |image|
                 save_image(image)
              end

              total_number_of_images = number_of_pages(@job)
              check_number = chk.check_number if !chk.blank?
              estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
              @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)
              
              if @job_condition and chk.save
                InputBatch::Log.status_log.info "Check id #{chk.id}, check_number #{chk.check_number}, Job id #{chk.job.id}, batch id #{chk.job.batch.id} successfully loaded"
                if mic and mic.save
                  InputBatch::Log.status_log.info "Check #{chk.id} associated to micr #{chk.micr_line_information.id}"
                  @job.save_payer_group(mic)
                end
              end
            else
              raise "Error on line #{@row_index} : Cannot save job for batch #{@bat.batchid}"
            end
          else
            raise "Error on line #{@row_index} : Cannot save batch"
          end
        end
        @flag = 0
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
    index_batch_id = find_batchid
    if @version == 'BANK_OF_AMERICA'
      unless index_batch_id == @last_bat_index
        batchid = InputBatch.get_batchid
      else
        batchid = @prev_batchid
      end
    else
      batchid = get_batchid_general(index_batch_id)
    end
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? && @prev_batchid != batchid
    if @batch_condition && @corresp_flag
      @corresp_flag = false if (@version == 'BANK_OF_AMERICA' && type == 'CORRESP')
      @bat = Batch.new
      @job_index = 0
      InputBatch::Log.write_log "Preparing batch #{batchid}"
      InputBatch::Log.write_log type
      parse_values("BATCH", @bat)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
    else
      if @prev_batchid != batchid && @corresp_flag
        InputBatch::Log.write_log "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @last_bat_index = index_batch_id
    @prev_batchid = batchid
  end
  
  #-----------------------------------------------------------------------------
  # Description : This will create a new check_information object and sets
  #               parameters to the object by reading the column header positions
  #               under CHEQUE section in configuration YML file.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_cheque
    chq = CheckInformation.new
    parse_values("CHEQUE", chq) if type == "PAYMENT"
    chq = update_check chq
    return chq
  end

  def save_image_type_data(image)
    if image.filename == @check_image
      save_image_types("CHK",image)
    elsif ((@job.job_status == JobStatus::EXCLUDED) and (image.filename != @check_image))
      save_image_types("OTH",image)
    end
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

    def save_image(image)
    if image.save
      save_image_type_data(image)
      InputBatch::Log.status_log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
      puts "Image #{image.filename} successfully loaded" if !image.size.blank?
    else
      raise "Error on line #{@row_index} : Cannot load image #{image.filename}"
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
    if conf["MICR"]
      aba_routing_number_pos = conf["MICR"]["aba_routing_number"]
      aba_routing_number = parse(aba_routing_number_pos)
      payer_account_number_pos = conf["MICR"]["payer_account_number"]
      payer_account_number = parse(payer_account_number_pos)
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
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
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
          image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
          @img_count += 1
          images << image
        end
      end
    else
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
      image = update_image image
      images << image
    end
    return images,image_file_name
  end
  
  # method to find batchid
  def find_batchid
     parse(conf['BATCH']['batchid']).strip
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to batch object
  #               that are not parsed from index file during batch loading
  # Input       : Batch object
  # Output      : Batch object
  #-----------------------------------------------------------------------------
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = arr_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (arr_time + facility.tat.to_i.hours)
    bat.target_time = (arr_time + facility.tat.to_i.hours)
    bat.date = Date.today if bat.date.blank?
    bat.bank_deposit_date = Date.today if bat.bank_deposit_date.blank?
    bat.correspondence = true if type == 'CORRESP'
    if !@corresp_flag
      last_batch = Batch.find(:last, :conditions => ["file_name = ?", @zip_file_name])
      payment_loading_condition = InputBatch.is_payment_process(facility)
      bat.index_batch_number = (!payment_loading_condition || (@row_index == 1)) ? 2 : last_batch.index_batch_number.to_i + 1
    end
    bat.lockbox = bat.lockbox.split('-').last if bat.lockbox
    return bat
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
  def update_check chk
    chk.check_number = '0' if chk.check_number.blank?
    chk.check_amount = 0.0 if chk.check_amount.blank?
    chk.check_amount = chk.check_amount.to_f
    return chk
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is for setting those information to image object
  #               that are not parsed from index file during image loading
  # Input       : Image object
  # Output      : Image object
  #-----------------------------------------------------------------------------
  def update_image image
    image.image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    image_path = Dir.glob("#{@location}/**/#{image.image_file_name}", File::FNM_CASEFOLD)[0]
    image.image = File.open("#{image_path}","rb")
    image.image_number = @img_count
    image.page_count = image_page_count(image)
    if @version == 'BANK_OF_AMERICA' and @doc_type == "1CK"
      @check_image = image.image_file_name
    else
      @check_image = nil
    end
    @img_count += 1
    if image_path.blank?
      InputBatch::Log.status_log.error ">>>>>>>>Image #{image.filename} not found<<<<<<<<<"
      puts ">>>>>>>>>>>>Image #{image.filename} not found"
      InputBatch::Log.error_log.error "Error on line #{@row_index} : Image #{image.filename} not found"
    else
      InputBatch::Log.status_log.debug "Image #{image.filename}  found"
      image.page_count = %x[identify #{image_path}].split(image.filename).length-1 rescue nil
    end

    return image
  end
  
  # method to find the type of batch corresponce or payment
  def find_type
    @doc_type = parse(cnf[@version]['PAYMENT']['DOC']).strip
    @type = (@doc_type == "1CK")? "PAYMENT" : "CORRESP"
  end
  
  
  def parse_values(data, object)
    conf[data].each do |k,v|
      if v.class == Hash
        object.details = Hash.new
        v.each do |key, value|
          object.details[key] =  parse(value).strip
        end
      else
        if v.length == 2
          object[k] = parse(v).strip
        else
          if v[2] == "date"
            object[k] = Date.rr_parse(parse(v).strip, true).strftime("%Y-%m-%d") rescue nil
          elsif v[2] == "float"
            object[k] = parse_amount(parse(v).strip)
          end
        end
      end
    end
  end
  
  def parse_amount amount_str
    if amount_str.index(".") == 0
      amount_str = "0"+amount_str.to_s
    end
    amount_str.gsub(/[^\d\.]/, "").scan(/\d*\.?\d*/)[0].to_f rescue nil
  end

  def job_condition
    job_sequence_number = parse(conf['JOB']['details']['batch_item_sequence'])
    if ((@new_batch_condition) && (@version == 'BANK_OF_AMERICA' && type == 'CORRESP'))
      @prev_job_sequence = job_sequence_number
      return true
    elsif @new_batch_condition || @prev_job_sequence != job_sequence_number
      @prev_job_sequence = job_sequence_number
      true
    else
      false
    end
  end
  
  def conf
    cnf[@version][type] rescue cnf['GENERAL']['PAYMENT']
  end
  
  def parse(v)
    row[v[0]..v[1]].strip rescue nil
  end
  
  def create_micr_array( batch, check_number, micr)
    chk_details = []
    chk_details[11] = micr.aba_routing_number
    chk_details[12] = micr.payer_account_number
    chk_details[13] = check_number
    chk_details
  end
   
  def find_version
    facility.index_file_parser_type.include?('_') ? 'BANK_OF_AMERICA' : 'GENERAL'
  end

  def get_batchid_general(batchid)
    if conf['APPEND']['date'] == "true"
      batchid += "_"+Time.now.strftime("%m%d%Y")
    end
    return "#{batchid}"
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
        count += %x[identify #{path}].split(image.filename).length-1 rescue nil            #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end


  def image_page_count image
    count = 0
    pages = image.client_images_to_jobs.length
    if (@facility.image_type == 1) && (pages < 2)
      path =  Dir.glob("#{@location}/**/#{image.filename}").first
      count = %x[identify #{path}].split(image.filename).length-1 rescue nil            #command for retrieve number of pages in a  tiff file (multi/single)
      pages = count
    end
    pages
  end
  #Saving values in image_types table

  def save_image_types type_of_image,image
    @image = ImageType.new
    @image.image_type = type_of_image
    @image.images_for_job_id = image.id
    @image.image_page_number = image.image_number
    @image.save
  end

  #-----------------------------------------------------------------------------
  # Description : This method checks if the date field in the index file has the
  #               same value for all the batches within a lockbox file. If the
  #               date value is different then error the file out.
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def unique_date?
    date_range = conf['BATCH']['date'][0]..conf['BATCH']['date'][1]
    dates = dat.collect{|row| row[date_range]}.compact
    dates.uniq.length == 1
  end
  
end

