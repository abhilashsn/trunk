class InputBatch::IdxCsvQuadaxCustomFilePathParser  < InputBatch::IndexCsvTransformer
  attr_reader :csv, :cnf, :type, :facility, :row


  def transform cvs
    @csv = CSV.read(cvs)
    @type = find_type
    foldername = nil
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    header_line = row_header_find
    csv.each do |row|
      if csv.index(row) > header_line
        @row = row
        foldername = save_records
      end
    end
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
    foldername
  end

  def row_header_find
    for i in 0..csv.length-1
      check_num_check = csv[i][0].strip rescue nil
      if check_num_check == "Num"
        row_count = i
        break
      else
        row_count = 0
      end
    end
    return row_count
  end

  def save_records
    prepare_batch

    if @bat
      @job_condition = job_condition
      @img_count = 1 if @job_condition
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
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
    "#{@bat.date.strftime("%Y%m%d")}_#{@bat.batchid}_SUPPLEMENTAL_OUTPUT" rescue nil
  end


  #### methods for setting values which are not parsed from index file during batch loading ####
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = facility.batches.last.date if bat.date.blank?
    bat.bank_deposit_date = facility.batches.last.date if bat.bank_deposit_date.blank?
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end



  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    if type == "CORRESP"
      image_path = Dir.glob("#{@location}/**/corr/corr#{image.filename}.[T,t][I,i][F,f]")[0]
    else
      image_path = Dir.glob("#{@location}/**/images/images#{image.filename}.[T,t][I,i][F,f]")[0]
    end
    new_image_name = File.basename("#{image_path}")
    ext_name = File.extname("#{image_path}")
    count = %x[identify "#{image_path}"].split(new_image_name).length-1
    if count>1
      dir_location = File.dirname("#{image_path}")
      ext_name = File.extname("#{image_path}")
      new_image_base_name = new_image_name.chomp("#{ext_name}")
      if ((not ext_name.empty?) and (ext_name.casecmp(".pdf") == 0) ) then
        system "pdftk  '#{image_path}' burst output '#{dir_location}/#{new_image_base_name}_%d#{ext_name}'"
        for image_count in 1..count
          image = ImagesForJob.new(:image_file_name=>"#{new_image_base_name}_#{image_count}#{ext_name}",:is_splitted_image=>true)
          image = update_image image
          images << image
        end
      else
        InputBatch.split_image(count,image_path, dir_location, new_image_base_name)
        single_images = Dir.glob("#{@location}/**/*").select{|file| InputBatch.get_single_image(file, new_image_base_name)}.sort
        single_images.each_with_index do |single_image, index|
          new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
          File.rename(single_image, new_image_name)
          image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
          @img_count += 1
          images << image
        end
      end
      new_initial_image_name = new_image_base_name
    else
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
      image = update_image image
      images << image
      new_initial_image_name = new_image_name
    end

    return images,new_initial_image_name+ext_name
  end



  def update_image image
    image.image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    if type == "CORRESP"
      image_path = Dir.glob("#{@location}/**/corr/#{image.image_file_name}")[0]
    else
      image_path = Dir.glob("#{@location}/**/images/#{image.image_file_name}")[0]
    end
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

  # method to find the type of batch corresponce or payment
  def find_type
    for i in 0..csv.length-1
      check_num_check = csv[i][13].strip rescue nil
      if check_num_check == "Check Num"
        value = "PAYMENT"
        break
      else
        value = "CORRESP"
      end
    end
    return value
  end
end