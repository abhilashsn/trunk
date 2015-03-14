# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxIdxTransformerOrthopedicSurgeonsOfGeorgia< InputBatch::IndexIdxTransformer
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

        images,@initial_image_name = prepare_image
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
    batch_date_position = cnf['BATCH']['date']
    batch_date = parse(batch_date_position[0]..batch_date_position[1])  
    new_batch_date = batch_date.split("/")
    batch.date = "20"+new_batch_date[2]+"-"+new_batch_date[0]+"-"+new_batch_date[1] if new_batch_date.size>2
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
    image_file_name = image.image_file_name.strip.split("\\").last+".TIFF" unless image.image_file_name.blank?
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

  def update_image image
    image_path = Dir.glob("#{@location}/**/#{image.filename}")[0]
    image.image = File.open("#{image_path}","rb")
    image.image_number = @img_count
    @img_count += 1
    if image_path.blank?
      InputBatch::Log.status_log.error ">>>>>>>>Image #{image.filename} not found<<<<<<<<<"
      puts ">>>>>>>>>>>>Image #{image.filename} not found"
    else
      InputBatch::Log.status_log.info "Image #{image.filename}  found"
    end
    return image
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


end
