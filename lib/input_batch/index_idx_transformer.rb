require 'yaml'
require 'input_batch'

# base class used for dat index file parsing and batch loading. The details of which columns
# of the dat file to parse to get data is written in a seperate yml file different 
# for different facilities. So new facility can be done by creating new configuration(yml) file.
class InputBatch::IndexIdxTransformer < InputBatch::IndexDatTransformer

  def transform index_file
    InputBatch.log.info "Opened idx file for processing"
    puts "Opened idx file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @prv_row = nil
    @dat = File.readlines(index_file)
    dat.each do |row|
      @row = row.chomp.strip
      index = dat.index(row)
      @prv_row = dat[index-1] unless dat[index-1].nil?
      save_records
    end
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def save_records
    find_type
    if type == 'CK' || type == 'IN'
      prepare_batch

      if @batch
        @job_condition = job_condition
        @img_count = 1 if @job_condition
        @batch.inbound_file_information = @inbound_file_information if @inbound_file_information
        images = prepare_image
        images.each{|image| @batch.images_for_jobs << image}

        prepare_job
        @batch.jobs << @job if @job_condition
        images.each{|image| @job.images_for_jobs << image}
        if @job_condition
          check = prepare_cheque
          @job.check_informations << check
           @job.initial_image_name = @initial_image_name
          if type == 'CK'
            mic = prepare_micr
            if mic
              payer = mic.payer
              check.payer_id = mic.payer_id if mic.payer_id
              if !facility.payer_ids_to_exclude.blank?
                @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
              elsif !facility.payer_ids_to_include.blank?
                @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
              end
              mic.check_informations << check
            end
          end
          if @batch.save
            if @job.save
              images.each do |image|
                if image.save
                  InputBatch.log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
                  puts "Image #{image.filename} successfully loaded"
                end
              end
            end
          end
        end
        if ((!@job_condition) and (facility.name.upcase == "LOGAN LABORATORIES LLC" || facility.name.upcase == "AVITA HEALTH SYSTEMS"))
          @job=@batch.jobs.last
          check = @job.check_informations.first
        end
        total_number_of_images = number_of_pages(@job)
        check_number = check.check_number if !check.blank?
        estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, nil, check_number)
        @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

        if @job_condition and check.save
          InputBatch.log.info "Check id #{check.id}, check_number #{check.check_number}, Job id #{check.job.id}, batch id #{check.job.batch.id} successfully loaded"
          if mic and mic.save
            InputBatch.log.info "Check #{check.id} associated to micr #{check.micr_line_information.id}"
            @job.save_payer_group(mic)
          end
        end
      end
    end
  end

  def prepare_batch
    batchid = find_batchid
    batch = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = batch.nil? and @batchid != batchid
    if @batch_condition
      @batch = Batch.new
      @job_index = 0
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      InputBatch.log.info type
      puts type
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
  
  
  def prepare_cheque
    check = CheckInformation.new
    parse_values("CHEQUE", check) if type == "CK"
    check = update_check check
    return check
  end

  def prepare_job tag = nil
    if @job_condition
      @job = Job.new
      parse_values("JOB", @job)
      @job = update_job @job
      @jobs << @job
    end
  end
  

  def prepare_micr
    if conf["MICR"]
      aba_routing_number_pos = conf["MICR"]["aba_routing_number"]
      aba_routing_number = parse(aba_routing_number_pos[0]..aba_routing_number_pos[1])
      payer_account_number_pos = conf["MICR"]["payer_account_number"]
      payer_account_number = parse(payer_account_number_pos[0]..payer_account_number_pos[1])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end
  
  # method to find batchid
  def find_batchid
    if facility.client.name.upcase == "QUADAX"
      method = "get_batchid"
      method << "_#{@client_sym}"
      batchid = send(method)
      return batchid
    else
      batchid_position = conf['BATCH']['batchid']
      batch_date_position = conf['BATCH']['date']
      batch_date = Date.rr_parse(parse(batch_date_position[0]..batch_date_position[1]),true).strftime("%m%d%Y")
      "#{parse(batchid_position[0]..batchid_position[1])}_#{batch_date}"
    end
  end
  
  def get_batchid_quadax
    # Rajesh - 10/23/2012
    # The commented line may be used in future for real time batch id generation for all quadax batch files. Hence commented out
    #@zip_file_name.upcase.chomp("_LOCKBOX.ZIP").chomp(".ZIP")
    # @zip_file_name.split("__")[0]
    @zip_file_name.chomp(".ZIP").chomp(".zip")
  end

  #### methods for setting values which are not parsed from index file during batch loading ####
  
  
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
  
  def update_job job
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
    return job
  end
  
  def update_check check
    check.check_number = '0' if check.check_number.blank?
    check.check_amount = 0.0 if check.check_amount.blank?
    check.check_amount = check.check_amount.to_f
    check.check_number = check.check_number.strip
    return check
  end
  
  # method to find the type of batch corresponce or payment
  def find_type
    if row[0..0] == "5"
      @type = "CK"
    elsif row[0..0] == "6"
      @type = "IN"
    else
      @type = nil
    end
  end
  
  
  def parse_values(data, object)
    unless conf[data].blank?
      conf[data].each do |k,v|
        if v.length == 2
          object[k] = parse(v[0]..v[1])
        else
          if v[2] == "date"
            object[k] = Date.rr_parse(parse(v[0]..v[1]), true).strftime("%Y-%m-%d") rescue nil
          elsif v[2] == "float"
            object[k] = parse_amount(parse(v[0]..v[1]))/100
          end
        end
      end
    end
  end
  
  def parse_amount amount_str
    if amount_str.index(".") == 0
      amount_str = "0"+amount_str.to_s
    end
    amount_str.gsub(/[^\d\.]/, "").scan(/\d+\.?\d*/)[0].to_f rescue nil
  end

  def job_condition
    if type == 'CK' 
      return true
    elsif facility.name.upcase == "LOGAN LABORATORIES LLC" || facility.name.upcase == "AVITA HEALTH SYSTEMS"
      if @prv_row.nil?
        return true
      elsif (@row[20..22]!= @prv_row[20..22])
        return true
      end
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
        path =  Dir.glob("#{@location}/**/#{image.filename}").first
        count += %x[identify #{path}].split(image.filename).length-1 rescue nil            #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end
   
end 
