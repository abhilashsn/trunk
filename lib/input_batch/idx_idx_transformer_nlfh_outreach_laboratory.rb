# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxIdxTransformerNlfhOutreachLaboratory< InputBatch::IndexIdxTransformer

  def initialize(cnf, facility, location, zip_file_name, inbound_file_information = nil)
    @cnf = YAML::load(File.open(cnf))
    @facility = facility
    @location = location
    @zip_file_name = zip_file_name
    @fac_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @inbound_file_information = inbound_file_information
  end
  
  def save_records
    find_type
    unless type.blank?
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
          if @type == 'PAYMENT'
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
                InputBatch.log.info "Check #{check.id} associated to micr #{check.payer.id}" if payer and payer.save
              end
            end
            @job_images = []
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
    parse_values("CHECK", check) 
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
    if cnf["MICR"]
      aba_routing_number_pos = cnf["MICR"]["aba_routing_number"]
      aba_routing_number = parse(aba_routing_number_pos[0]..aba_routing_number_pos[1])
      payer_account_number_pos = cnf["MICR"]["payer_account_number"]
      payer_account_number = parse(payer_account_number_pos[0]..payer_account_number_pos[1])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end

  # method to find batchid
  def find_batchid
    @zip_file_name.chomp(".zip").chomp(".ZIP")
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
    return check
  end

  # method to find the type of batch corresponce or payment
  def find_type
    check_number_position = cnf['CHECK']['check_number']
    check_number = parse(check_number_position[0]..check_number_position[1])
    if row[0..2].to_i > 0
      unless check_number.blank?
        @type = 'PAYMENT'
      else
        @type = 'CORRESP'
      end
    else
      @type = nil
    end
  end

  #The following method  search for the corresponding EOB / other images
  #related with that transaction.Only check_image name is present in the
  #index file.


  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    @multi_page_image_name = image.image_file_name.strip
    image_name = image.image_file_name.strip.split(".").first
    @job_images = Dir.glob("#{@location}/**/#{image_name}.*", File::FNM_CASEFOLD)
    @job_images.sort!
    convert_single_page_to_multipage
    Dir.glob("#{@location}/**/images")
    image = ImagesForJob.new(:image_file_name=>"#{@multi_page_image_name}")
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
  end


  def parse(v)
    row[v] rescue nil
  end

  def conf
    cnf[type] rescue cnf['PAYMENT']
  end


  def parse_values(data, object)
    cnf[data].each do |k,v|
      if v.length == 2
        object[k] = parse(v[0]..v[1]).strip
      else
        if v[2] == "date"
          object[k] = Date.rr_parse(parse(v[0]..v[1]), true).strftime("%Y-%m-%d") rescue nil
        elsif v[2] == "float"
          object[k] = parse_amount(parse(v[0]..v[1]))/100
        end
      end
    end
  end

  def job_condition
    unless type.blank?
      true
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

  def convert_single_page_to_multipage
    system("tiffcp -a #{@job_images[1..-1].join(" ")} #{@location}/IMAGES/#{@multi_page_image_name}")
  end

end
