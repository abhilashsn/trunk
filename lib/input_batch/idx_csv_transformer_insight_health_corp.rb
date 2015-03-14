class InputBatch::IdxCsvTransformerInsightHealthCorp < InputBatch::IndexCsvTransformer

  def transform cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false)    
    3.times{|i| csv.readline}
    @corr_index = 0
    @payment_index = 0
    csv.each do |row|
      @row = row
      find_type      
      @corr_index += 1 if parse(conf["JOB"]["record_type"]) == "Correspondence"
      @payment_index += 1 if parse(conf["JOB"]["record_type"]) == "Check"
      save_records
    end
    csv.close
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def prepare_batch
    batchid = find_batchid
    find_facility
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
      @bat = Batch.new      
      @job_index = 0
      if parse(conf["JOB"]["record_type"]) == "Correspondence"
        @corr_index = 1 unless @corr_flag
        @corr_flag = true
      elsif parse(conf["JOB"]["record_type"]) == "Check"
        @payment_index = 1 unless @payment_flag
        @payment_flag = true
      end
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      InputBatch.log.info type
      puts type
      parse_values("BATCH", @bat)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.lockbox = @bat.lockbox.split("-").last rescue nil
      @bat.file_meta_hash = file_meta_hash
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end

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
  
  def update_image image    
    if parse(conf["JOB"]["record_type"]) == "Correspondence"
      image_path = Dir.glob("#{@location}/**/corr/#{@corr_index}.[T,t][I,i][F,f]")[0]      
      folder = "corr"     
    elsif parse(conf["JOB"]["record_type"]) == "Check"
      image_path = Dir.glob("#{@location}/**/images/#{image.filename}.[T,t][I,i][F,f]")[0]      
      folder = "images"      
    end
    image.image = File.open("#{image_path}","rb")
    image.image_number = @img_count
    @img_count += 1
    if image_path
      InputBatch.log.info "Image /#{folder}/#{image.filename} found"
    else
      InputBatch.log.info "Image /#{folder}/#{image.filename} not found"
    end
    return image
  end
  
  def get_batchid
    batchid = parse(conf['BATCH']['batchid'])
    date = parse(conf['BATCH']['date'][0])
    bat_date = Date.rr_parse(date, true).strftime("%m%d%Y") rescue nil
    "#{batchid}_#{bat_date}"
  end
  
  def find_facility
    lockbox_number = parse(conf['BATCH']['lockbox']).split("-").last.strip rescue ""
    client = Client.find_by_name("INSIGHT IMAGING")
    @facility = client.facilities.find_by_lockbox_number(lockbox_number) if client
    if @facility.blank? or client.blank?
      system "rake clients:create_clients_and_facilities"
      (@facility = Facility.find_by_lockbox_number(lockbox_number)) or
        (raise ActiveRecord::RecordNotFound,
        "Couldn't find Facility with lockbox number #{lockbox_number}")
    end
  end
 
  def prepare_micr
    if conf["MICR"] and facility.details[:micr_line_info]
      aba_routing_number = parse(conf["MICR"]["aba_routing_number"])
      payer_account_number = parse(conf["MICR"]["payer_account_number"])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end
  
end
