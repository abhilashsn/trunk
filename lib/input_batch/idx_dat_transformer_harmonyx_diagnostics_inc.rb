require 'csv'
require 'yaml'
require 'input_batch'
class InputBatch::IdxDatTransformerHarmonyxDiagnosticsInc < InputBatch::IndexDatTransformer
  attr_accessor :csv, :cnf, :type,:config_hash, :facility, :row, :client
  WARRANT_ABA = '121113423'
  WARRANT_PAYER_ACCOUNT_NUMBER = "000000000"
  FIRST_BATCH_ID = 2176782335
  #-----------------------------------------------------------------------------
  # Description : This method initialize the parser class.
  # Input       : config file, facility, extracted zip location, zip_file_name
  # Output      : None
  #-----------------------------------------------------------------------------
  def initialize(cnf, facility, location, zip_file_name,inbound_file_information)
    @cnf = YAML::load(File.open(cnf))
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
    InputBatch::Log.write_log "Opened csv file for processing"
    InputBatch::Log.write_log "Batch type to load : #{facility.batch_load_type.upcase}"
    @index_file_name = File.basename(index_file).downcase
    @corresp_flag = true
    @last_row_type = nil
    @dat = File.readlines(index_file)
    @image_folder = Dir.glob("#{@location}/**/#{cnf['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
    unless @image_folder.blank?
      @image_path = @image_folder.first.split('/')[0..-2].join('/')

      raise "Image Folder Mismatch : Please check for folder (case insensitive)
        '#{cnf['IMAGE']['image_folder']}' in batch zip " if @image_folder.blank?

      @image_ext =File.extname(@image_folder[0]).delete(".")
    end
    InputBatch::Log.write_log ">>>>>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    dat.each_with_index do |row, index|
      @row_line = row
      @row_next= dat[index+1].blank? ? "EOF" : dat[index+1].split("|")
      @row = row.split("|")
      @row_index = index + 1
      @type = find_type
      if !@row[0].blank?
        InputBatch::Log.status_log.info "**** Processing index file row #{@row_index} ****"
        save_records if valid_record?
      end
    end
    @inbound_file_information.associate_to_report_check_informations if !@inbound_file_information.blank?
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
    micr = nil
    prepare_batch
    if @batch
      if @inbound_file_information
        @batch.inbound_file_information = @inbound_file_information
        @batch.arrival_time = @inbound_file_information.arrival_time
      end
      @job_condition = job_condition
      if @job_condition
        @img_count = 1
        do_bank_logics if type == 'PAYMENT'        #Applying bank specific logic
      end
      images = prepare_image
      images.each{|image| @batch.images_for_jobs << image} unless images.blank?

      prepare_job
      @batch.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image} unless images.blank?
     
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
        @job.initial_image_name = @initial_image_name
      end
    end



    if @batch.save
      @batch.update_attributes(:status => BatchStatus::NEW)
      if @job.save
        @job.save_payer_group(micr) unless micr.blank?
        unless images.blank?
  
          images.each do |image|
            if image.save
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

              puts "Image #{image.image_file_name} successfully loaded" if !image.size.blank?
            else
              raise "Error on line #{@row_index} : Cannot load image #{image.image_file_name}"
            end
          end
        end
      end
    else
      raise "Error on line #{@row_index} : Cannot save batch"
    end
    "#{@batch.date.strftime("%Y%m%d")}_#{@batch.batchid}_SUPPLEMENTAL_OUTPUT" rescue nil
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
    index_batchid = parse(cnf['BATCH']['index_batch_number']).to_s
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
      @batch = Batch.new
      @job_index = 0
      InputBatch::Log.write_log "Preparing batch #{batchid}"
      InputBatch::Log.write_log type
      parse_values("BATCH", @batch)
      @@batch_date = @batch.date if !@batch.date.blank?
      @batch = update_batch @batch
      @batch.batchid = batchid
      @batch.file_meta_hash = file_meta_hash
    else
      if @batchid != batchid && @corresp_flag
        InputBatch::Log.write_log "Batch #{batchid} already loaded"
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
    parse_values("CHEQUE", check) if type == "PAYMENT"
    update_check check
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
    if cnf["MICR"]
      aba_routing_number = parse(cnf["MICR"]["aba_routing_number"])
      payer_account_number = parse(cnf["MICR"]["payer_account_number"])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This will create an images_for_job object and sets parameters
  #               to the object by reading the column header positions under
  #               IMAGE section in cnfuration YML file.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def prepare_image
    if @job_condition 
      @images_for_job = []
      @images = []
    end
    @images_from_index = row.slice(cnf['IMAGE']['image_file_name'][0]..-1).compact
    @images_from_index = @images_from_index.collect{|file| file.include?('.') ? \
        file: file + ".#{@image_ext}"}
    # identifying check and envelop images
    @check_image, @envelop_image = call_parser_specific_method  "prepare_check_and_envelop_images"  if @version == 'BANK_OF_AMERICA' and facility.index_file_parser_type != "Apria_bank"
    envelop_image_to_loaded = (@envelop_image.upcase)[0...-4].split("_")  unless @envelop_image.blank?
    @image_folder = Dir.glob("#{@location}/**/#{cnf['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
    @images_from_index.each do |file_name|
      unless @hash_envelop_images.has_key?("#{file_name}")
        @images_for_job << @image_folder.select{|file| File.basename(file).upcase == file_name.upcase || file_name[0...-4] +\
            'B' == File.basename(file)[0...-4].upcase }
      else
        unless @envelop_image.blank?
          @images_for_job << @image_folder.select{|file| File.basename(file).upcase == @envelop_image.upcase ||
              File.basename(file)[0...-4].upcase == @envelop_image.upcase[0...-4] +'B'}
          if envelop_image_to_loaded.size == 2
            @image_folder = Dir.glob("#{@location}/**/#{cnf['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
            @images_for_job << @image_folder.select{|file| File.basename(file)[0...-4].upcase == envelop_image_to_loaded[0]+'B_'+ envelop_image_to_loaded[1]}
          end
        end
      end
    end
    @images_for_job.flatten!
    if row[6]!=@row_next[6]
      images_for_job = convert_single_page_to_multipage(@images_for_job) #if multi_page_facilities.include? facility.name.strip.upcase
      images_for_job.each do |image_name|
        image = ImagesForJob.new :image => File.open("#{image_name}","rb")
        parse_values("IMAGE", image, File.basename(image_name))
        @images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
      end
    end
    return @images
   
  end

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
    batch.target_time = (Time.now + facility.tat.to_i.hours)
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
    cnf[data].each do |k,v|
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
    aba = parse(cnf["MICR"]["aba_routing_number"])
    payer_account_number = parse(cnf["MICR"]["payer_account_number"])
    check_number = parse(cnf['CHEQUE']['check_number'])
    if facility.details[:is_transpose]
      transpose = InputBatch.do_transpose(@batch, aba, check_number)
      if transpose
        row[cnf["MICR"]["payer_account_number"]], row[cnf['CHEQUE']['check_number']]\
          = row[cnf['CHEQUE']['check_number']], row[cnf["MICR"]["payer_account_number"]]
      end
    end
    if facility.details[:is_warrant]
      if aba == WARRANT_ABA
        row[cnf['CHEQUE']['check_number']] , row[cnf["MICR"]["payer_account_number"]]\
          = row[cnf["MICR"]["payer_account_number"]], WARRANT_PAYER_ACCOUNT_NUMBER
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
      amount_string = "0"+amount_string.to_s
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
  # Description : This method is for identifying occurence of job details from
  #               index file .
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def job_condition
    job_condition = false
    if parse(cnf['BATCH']['record_type'])=="CHK"
      job_condition = true
    else
      if (parse(cnf['BATCH']['record_type'])!="CHK") and (parse(cnf['JOB']['job_number']) == "1")
        if  (@last_row_type=="CHK")
          job_condition = false
        else
          job_condition = true
        end
      end
    end
    @last_row_type = parse(cnf['BATCH']['record_type'])
    return job_condition
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for creating batchid based on the specifications.
  # Input       : None
  # Output      : Batchid string
  #-----------------------------------------------------------------------------
  def find_batchid
    @zip_file_name[0...-4]
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for generating batchid for non-banking clients.
  # Input       : None
  # Output      : Batchid string
  #-----------------------------------------------------------------------------
  def get_batchid_general
    if facility.name.upcase == 'GENOPTIX MEDICAL LABORATORY'
      @zip_file_name[0...-4]                                   #batch id is the last segment of quadax zip file name (excluding '.zip')
    else
      batchid = parse(cnf['BATCH']['batchid'])
      date = parse(cnf['BATCH']['date'][0])
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
    status = (cnf['BATCH']['record_type']? parse(cnf['BATCH']['record_type'] ) != 'INV' : true)
    return status
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for finding index file type.
  # Input       : Index file
  # Output      : Type string
  #-----------------------------------------------------------------------------
  def find_type
    parse(cnf['BATCH']['record_type'])=="CHK" ?  "PAYMENT" : "CORRESP"
  end

  #-----------------------------------------------------------------------------
  # Description : This method is for converting single page images to multipage
  #               for non-bank BOA client CHRISTIAN HOSPITAL LABORATORY  .
  # Input       : Array of single page images for a job
  # Output      : converted multipage image.
  #-----------------------------------------------------------------------------
  def convert_single_page_to_multipage(single_page_images)
    begin
      check_image = "#{File.dirname(single_page_images.first)}/#{File.basename(single_page_images.first)}" #{File.extname(single_page_images.first)}"
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
  # Description : This method checks if the date field in the index file has the
  #               same value for all the batches within a lockbox file. If the
  #               date value is different then error the file out.
  # Input       : None
  # Output      : True or False
  #-----------------------------------------------------------------------------
  def unique_date?
    if cnf['BATCH']['date']
      date_index = cnf['BATCH']['date'][0]
      dates = csv.collect{|row| row[date_index]}.compact
      dates.uniq.length == 1
    else
      true
    end
  end

  def prepare_check_and_envelop_images
    check_image = nil
    new_envelop_image = nil
    index_file_images = row.slice(cnf['IMAGE']['image_file_name'][0]..-1)
    index_file_images = index_file_images.collect{|file|
      ((!file.blank?)? ( file.include?('.') ?  file: file + ".#{@image_ext}" ) : "")}

    (type == 'PAYMENT')? (check_image,envelop_image = index_file_images[0..1]):(envelop_image = index_file_images[0])
    if (type == 'PAYMENT')
      if @hash_envelop_images.has_key?("#{envelop_image}")
        envelop_image_back = envelop_image[0...-4]+"B.#{@image_ext}"
        envelop_image_back_lowercase = envelop_image[0...-4]+"b.#{@image_ext}"
        @envelop_image_folder = Dir.glob("#{@location}/**/#{cnf['IMAGE']['image_folder']}", File::FNM_CASEFOLD)[0]
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

  #-----------------------------------------------------------------------------
  # Description : Content of the temperory image folder may get changed in
  #               between batch loading(like image splitting). So we are using a
  #               method call to get the contents.
  # Input       : None
  # Output      : Array of image files plus index file
  #-----------------------------------------------------------------------------
  def image_folder
    Dir.glob("#{@location}/**/#{cnf['IMAGE']['image_folder']}*", File::FNM_CASEFOLD)
  end

end

