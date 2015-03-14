require 'csv'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which columns
# of the csv file to parse to get data is written in a seperate yml file different 
# for different facilities. So new facility can be done by creating new configuration(yml) file.
class InputBatch::IndexAscTransformer
  attr_accessor :file_meta_hash
  attr_reader :asc, :cnf, :type, :facility, :row
   
  def initialize(cnf, facility, location, zip_file_name, inbound_file_information = nil)
    @cnf = YAML::load(File.open(cnf))
    @facility = facility
    @location = location
    @zip_file_name = zip_file_name
    @fac_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @inbound_file_information = inbound_file_information
  end

  def transform asc_file, pages
    InputBatch.log.info "Opened asc file for processing"
    puts "Opened asc file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @pages = pages
    @prev_row = nil
    @asc = File.readlines(asc_file)
    asc.delete_if{|x| x.blank?}
    asc.delete_at(-1)
    asc.each do |row|
      @row_index = asc.index(row)
      @prev_row = asc[@row_index-1] if @row_index>0
      @row = row
      find_type
      save_records if job_condition
    end   
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def save_records
    prepare_batch
    if @bat
      @job_condition = job_condition
      @img_count = 1 if @job_condition
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
      images = prepare_image
      images.each{|image| @bat.images_for_jobs << image}

      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}

      if @job_condition
        chk = prepare_cheque
        @job.check_number = '0' if chk.check_amount == 0.0
        @job.check_informations << chk
         @job.initial_image_name = @initial_image_name
        if @type == 'PAYMENT'
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

         # total_number_of_images = @pages.shift
          total_number_of_images = @job.client_images_to_jobs.length
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

  def prepare_batch
    if @facility.name.upcase == "HORIZON LABORATORY LLC" || @facility.name.upcase == "LAKE HEALTH REFERENCE LAB"
     batchid = @zip_file_name[0...-4]
    else
     batchid = @zip_file_name.split(/_/).last[0...-4]                            #batch id is the last segment of quadax zip file name (excluding '.zip')
    end
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = (bat.nil? and (@batchid != batchid))
    if @batch_condition
      @bat = Batch.new      
      @job_index = 0
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      parse_values("BATCH", @bat)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end  
  
  
  def prepare_cheque
    chq = CheckInformation.new
    parse_values("CHEQUE", chq)
    chq = update_check chq
    return chq
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
      aba_routing_number = parse(conf["MICR"]["aba_routing_number"])
      payer_account_number = parse(conf["MICR"]["payer_account_number"])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end
  
  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    image_chk = Dir.glob("#{@location}/**/#{image.filename}")[0]
    condition = (@facility.name == "HORIZON LABORATORY LLC" && image_chk != nil) || (@facility.name != "HORIZON LABORATORY LLC")
    if condition
      images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    end
    return images
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
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end
  
  def update_job job
    job.check_number = '0' if job.check_number.blank? 
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
    return job
  end
  
  def update_check chk
    if chk.check_amount.blank? or chk.check_amount == 0.01
      chk.check_amount = 0.0
      chk.check_amount = chk.check_amount.to_f
      chk.check_number = '0'
    end
    if (@facility.name == "LAKE HEALTH REFERENCE LAB" || @facility.name == "HORIZON LABORATORY LLC") and @type == 'CORRESP'
      chk.check_amount = 0.0
      chk.check_number = '0'
    end
    return chk
  end
  
  
  # method to find the type of batch corresponce or payment
  def find_type
    if @prev_row.blank?
      @previous_job_row = 0
     else
      @previous_job_row = @prev_row[25..30]
     end
    if (row[16] != " " and @facility.name == "LAKE HEALTH REFERENCE LAB") || ((@facility.name == "HORIZON LABORATORY LLC") and ((@row_index == 0 && row[34] == 'M') or ((@row[25..30] != @previous_job_row) && row[34] == 'M')))
      @type = 'CORRESP'
    else
      @type = 'PAYMENT'
    end
  end
    
  def parse_values(data, object)
    cnf[type][data].each do |k,v|
      if v[2] 
        if v[2] == 'date'
          object[k] = Date.strptime(parse(v), v[3]) rescue nil
        elsif v[2] == "float"
          object[k] = parse_amount(parse(v))
        end
      else
        object[k] = parse(v)
      end
    end
  end
  
  
  def parse_amount amount_str
    if amount_str.index(".") == 0
      amount_str = "0"+amount_str.to_s
    end
    amount_str.gsub(/[^\d\.]/, "").scan(/\d+\.?\d*/)[0].to_f rescue nil
  end
  
  def parse(v)
    row[v[0],v[1]].strip rescue nil
  end
  
  def conf
    cnf[type] rescue cnf['PAYMENT']
  end

  def job_condition
    if @facility.name == "LAKE HEALTH REFERENCE LAB" || @facility.name == "HORIZON LABORATORY LLC"
      @current_job =  @row[25..30]
      if @prev_row.blank?
        @previous_job = 0
      else
        @previous_job = @prev_row[25..30]
      end
      ((parse(cnf[type]['IMAGE']['type']) == 'C') || (@row_index == 0 && parse(cnf[type]['IMAGE']['type']) == 'M')||(@current_job != @previous_job)) #&& (parse(cnf[type]['IMAGE']['type']) == 'M')))
    else
      parse(cnf[type]['IMAGE']['type']) == 'C'
    end
  end

end #class
