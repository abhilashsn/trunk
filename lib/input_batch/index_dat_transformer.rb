require 'yaml'
require 'input_batch'

# base class used for dat index file parsing and batch loading. The details of which columns
# of the dat file to parse to get data is written in a seperate yml file different 
# for different facilities. So new facility can be done by creating new configuration(yml) file.
class InputBatch::IndexDatTransformer
  attr_accessor :dat, :cnf, :facility, :row, :type, :file_meta_hash
  
    
  def initialize(cnf, facility, location, zip_file_name, inbound_file_information = nil)
    @cnf = YAML::load(File.open(cnf))
    @facility = facility
    @location = location
    @zip_file_name = zip_file_name
    @fac_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @inbound_file_information = inbound_file_information
    @img_count = 0
  end

  def transform cvs
    InputBatch.log.info "Opened dat file for processing"
    puts "Opened dat file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @dat = File.readlines(cvs)     
    dat.each do |row|
      @row = row.split
      save_records
    end
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def save_records
    find_type
    if parse(conf["TYPE"]) == "1CK" || parse(conf["TYPE"]) == "1IN"
      prepare_batch

      if @bat        
        @job_condition = job_condition
        @bat.inbound_file_information = @inbound_file_information
        @img_count = 1 if @job_condition
        images = prepare_image
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
            if mic
              payer = mic.payer
              chk.payer_id = mic.payer_id if mic.payer_id
              if !facility.payer_ids_to_exclude.blank?
                @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
              elsif !facility.payer_ids_to_include.blank?
                @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
              end
              mic.check_informations << chk
            end
          end
        end
        
        if @bat.save
          if @job.save
            images.each do |image|
              if image.save
                InputBatch.log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
                puts "Image #{image.filename} successfully loaded"
              end
            end

            total_number_of_images = number_of_pages(@job)
            check_number = chk.check_number if !chk.blank?
            estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
            @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

            if @job_condition and chk.save
              InputBatch.log.info "Check id #{chk.id}, check_number #{chk.check_number}, Job id #{chk.job.id}, batch id #{chk.job.batch.id} successfully loaded"
              if mic and mic.save
                InputBatch.log.info "Check #{chk.id} associated to micr #{chk.micr_line_information.id}"
                @job.save_payer_group(mic)
              end
            end
          end
        end
      end
    end
  end

  def prepare_batch
    batchid = find_batchid
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
      @bat = Batch.new      
      @job_index = 0
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      InputBatch.log.info type
      puts type
      parse_values("BATCH", @bat)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
    elsif type == 'CK'
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end  
  
  
  def prepare_cheque
    chq = CheckInformation.new
    chq = update_check chq
    return chq
  end

  def prepare_job tag = nil
    if @job_condition
      @job = Job.new
      @job = update_job @job
      @jobs << @job
    end
  end
  

  def prepare_micr
    if conf["MICR"]
      aba_routing_number = parse(conf["MICR"]["aba_routing_number"])
      payer_account_number = parse(conf["MICR"]["payer_account_number"])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end
  
  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
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
  
  # method to find batchid(now this class is used only for quadax)
  def find_batchid
    if @facility.name.upcase == "ATLANTICAR CLINICAL LAB"
      @zip_file_name[0...-4]
    else
     @zip_file_name.split(/_/).last[0...-4]                                       # batch id is the last segment of quadax zip file name (excluding '.zip')
   end
    end
  
  def get_batch_date
    date_indexes = conf['BATCH']['date']
    date_string = parse(date_indexes[0])[date_indexes[1]..date_indexes[2]]
    batch_date = Date.rr_parse(date_string, true).strftime("%Y-%m-%d") rescue nil
  end
  
  
  #### methods for setting values which are not parsed from index file during batch loading ####
  
  
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = Date.today if bat.date.blank?
    bat.bank_deposit_date = Date.today if bat.bank_deposit_date.blank?
    bat.lockbox = get_lockbox rescue nil
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end
  
  def update_job job
    job.check_number = get_check_details(parse(conf['JOB']['check_number']))[0]
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
    return job
  end
  
  def update_check chk
    chk.check_amount = get_check_details(parse(conf['CHEQUE']['check_number']))[1]
    chk.check_number = get_check_details(parse(conf['CHEQUE']['check_number']))[0]
    chk.check_number = '0' if chk.check_number.blank?
    chk.check_amount = 0.0 if chk.check_amount.blank?
    chk.check_amount = chk.check_amount.to_f
    return chk
  end
  
  
  # method to find the type of batch check or in
  def find_type
    if row[4].length == 1
      @type = 'PAYMENT'
    elsif row[4][0..0] == '1'
      @type = 'CORRESP'
    end
  end
  
  def get_check_details check_string
    begin
      check_split = check_string.split('.')
      check_number = check_split[1][2..check_split[1].length]
      check_amount = check_string[0..check_string.length-check_number.length-1]
      return check_number,check_amount
    rescue
      return nil,nil
    end
  end
  
  def get_lockbox
    lockbox_str = parse(conf['BATCH']['lockbox'][0])
    lockbox_str[conf['BATCH']['lockbox'][1]..conf['BATCH']['lockbox'][2]]
  end
  
  
  def parse_values(data, object)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = parse(v)
      else
        if v[3] == "date"
          object[k] = get_batch_date
        end
      end
    end
  end
  
  def parse(v)
    row[v] rescue nil
  end
  
  def conf
    cnf[type] rescue cnf['PAYMENT']
  end

  def job_condition
    if parse(conf["TYPE"]) == "1CK" || parse(conf["TYPE"]) == "1IN"
      true
    end
  end
 
  #method for finding number of pages in a tiff file   
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
  
end #class


