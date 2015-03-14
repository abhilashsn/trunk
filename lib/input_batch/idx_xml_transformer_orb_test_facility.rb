require 'nokogiri'
#require 'yaml'

class  InputBatch::IdxXmlTransformerOrbTestFacility< InputBatch::IndexXmlTransformer
  def transform xml
    idx_xml = File.open(xml)
    batch_id_from_xml = nil
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    InputBatch.log.info "Opened XML document for processing"
    puts "Opened XML document for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @ins_batches =  doc.xpath("/ins:Transmission/ins:Batch").length
    batch_id_from_xml = doc.xpath("/ins:Transmission/ins:Batch").attribute("BatchID") unless doc.xpath("/ins:Transmission/ins:Batch").to_s.blank?
    correspondence_xml_path = get_correspondence_path
    if correspondence_xml_path.present?
      correspondence_batch_id_from_xml = correspondence_xml_path.attribute("BatchID")
    end
    if batch_id_from_xml.blank? and correspondence_batch_id_from_xml.blank?
      subject = "Orbograph Non Lockbox File Arrival Notification"
      RevremitMailer.notify_orbo_batch_edit_nonlockbox_client(@zip_file_name,@location,subject).deliver
      @bat =  nil
    else
      if @ins_batches>0
        @batch_type="Batch"
        InputBatch.log.info "Number of cheques: #{@ins_batches}"
        doc.xpath("/ins:Transmission/ins:#{@batch_type}").each do |e|
          e.xpath("ins:Transaction").each do |chk|
            save_record(chk,doc,e)
          end
        end
      end
      save_correspondence_items(correspondence_xml_path)      
    end
    idx_xml.close
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def save_record(chk,doc,e, is_correspondence = false)
    
    prepare_batch(e, doc)
    @job_condition = job_condition
    if @bat

      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
      @img_count = 1 if @job_condition

      images,@initial_image_name = prepare_image(e, chk, is_correspondence)
      @new_batch = false
      images.each{|image| @bat.images_for_jobs << image}

      #payer = prepare_payer chk
           
      prepare_job chk
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}

      if @job_condition
        chq = prepare_cheque chk
        update_job_check_number @job, chq
        @job.payer_group = "Insurance" if is_correspondence
        @job.is_correspondence = true if is_correspondence
        #chq.payer_id = payer.id if payer
        @job.check_informations << chq
        @job.initial_image_name = @initial_image_name
        if @type == "PAYMENT"
          mic = prepare_micr chk
          if mic
            payer = mic.payer
            chq.payer_id = mic.payer_id if mic.payer_id
            if !facility.payer_ids_to_exclude.blank?
              @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
            elsif !facility.payer_ids_to_include.blank?
              @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
            end
            mic.check_informations << chq
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
          check_number = chq.check_number if !chq.blank?
          estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
          @job.update_attributes(:pages_from => 1 ,:estimated_eob => estimated_eob, :pages_to => total_number_of_images)
          #@job.update_attributes(:estimated_eob => estimated_eob)

          if chq.save
            InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
            if mic and mic.save
              InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}"
              @job.save_payer_group(mic)
            end
            InputBatch.log.info "Check #{chq.id} associated to micr #{chq.payer.id}" if payer and payer.save
          end
        end
      end
    end
    #      end
    #      end
  end



  def prepare_batch(chk, doc)
    batchid = find_batchid(chk, doc)
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
      @bat = Batch.new
      @job_index = 0
      @image_number_in_batch = 0
      @new_batch = true
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      @type = (@batch_type == "Batch")? 'PAYMENT':'CORRESPONDENCE'
      InputBatch.log.info @type
      puts @type
      parse_values("BATCH", @bat, chk, doc)
      @bat = update_batch @bat
      @bat.correspondence = true if @batch_type == 'Correspondence'
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

  def prepare_image(tag = nil, atag = nil, is_correspondence = nil)
    images = []
    image = ImagesForJob.new
    tag ? parse_values("IMAGE", image, tag) : parse_values("IMAGE", image)
    image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    path =  Dir.glob("#{@location}/**/#{image_file_name}").first
    if is_correspondence
      count = %x[identify "#{path}"].split(image_file_name).length-1
      @last_page = 0 if @last_page.blank?
      first_page = @last_page + 1
      last_page = count
    else
      first_page = parse(conf["JOB"]["pages_from"], atag).to_i
      last_page = parse(conf["JOB"]["pages_to"], atag).to_i
      @last_page = last_page
      count = last_page - first_page + 1
    end
    new_image_name = File.basename(path)
    if count>1
      dir_location = File.dirname(path)
      ext_name = File.extname(path)
      new_image_base_name = new_image_name.chomp(ext_name)
      if ((not ext_name.empty?) and (ext_name.casecmp(".pdf") == 0) ) then
        # @image_number_in_batch = pds_actual_image_number
        if !@image_number_in_batch.blank?
          if @new_batch == true
            @image_page_number_in_batch = 1
          end
        end
        system "pdftk  '#{path}' burst output '#{dir_location}/#{new_image_base_name}_%d#{ext_name}'"
        for image_count in first_page..last_page
          
          image = ImagesForJob.new(:image_file_name=>"#{new_image_base_name}_#{image_count}#{ext_name}",:is_splitted_image=>true,:actual_image_number => @image_page_number_in_batch)
          image = update_image(image)
          images << image
          unless @image_number_in_batch.blank?
            @image_page_number_in_batch += 1
          end
        end
      else
        # @image_number_in_batch = pds_actual_image_number
        if !@image_number_in_batch.blank?
          if @new_batch == true
            @image_page_number_in_batch = 1
          end
        end
        system("tiffsplit #{path} #{dir_location}/#{new_image_base_name}")
        single_images = Dir.glob("#{@location}/**/*").select{|file| File.basename(file).split('.').first =~ /#{new_image_base_name}[a-z][a-z][a-z]/}.sort
        for index in (first_page - 1)..(last_page - 1)
          new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
          if single_images[index]
            File.rename(single_images[index], new_image_name)
           
            image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true, :actual_image_number => @image_page_number_in_batch)
            @img_count += 1
            images << image
            unless @image_number_in_batch.blank?
              @image_page_number_in_batch += 1
            end
          end
        end
      end
    else
      if @new_batch == true
        @image_page_number_in_batch = 1
      end
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}",:actual_image_number=>@image_page_number_in_batch)
      @image_page_number_in_batch += 1
      image = update_image image
      images << image
    end
    return images,image_file_name
  end

  def update_image(image, image_count = nil)
    image_path = Dir.glob("#{@location}/**/#{image.filename}")[0]
    image.image = File.open("#{image_path}","rb")
    image_count ? image.image_number = image_count : image.image_number = @img_count
    @img_count += 1
    if Dir.glob("#{@location}/**/#{image.filename}")[0]
      InputBatch.log.info "Image #{image.filename} found"
    else
      InputBatch.log.info "Image #{image.filename} not found"
    end
    return image
  end

  #Unused method
  def prepare_payer chk
    payer_name = parse(conf["PAYER"]["payer"], chk)
    payer = Payer.find_by_payer(payer_name)
    return payer
  end

  #Unused method (i think)
  def prepare_eob svc, chq
    pat_acc_no = parse(conf['CLAIM']['patient_account_number'], svc)
    unless @pat_acc_nos.include?(pat_acc_no)
      eob = InsurancePaymentEob.new
      eob = return_data svc, cnf["CLAIM"], eob
    else
      eob = chq.insurance_payment_eobs.find_by_patient_account_number(pat_acc_no)
    end
    @pat_acc_nos << pat_acc_no
    return eob
  end

  #Unused method (i think)
  def prepare_svc sc
    svc = ServicePaymentEob.new
    svc = return_data sc, cnf["SVC"], svc
    return svc
  end

  def find_batchid(chk, doc)
    #    processing_date = parse(conf["BATCH"]["date"][0], doc) rescue nil
    #    transmission_id = parse(conf["BATCH"]["transmission_id"], doc) rescue nil
    #    batch_id = parse(conf["BATCH"]["batchid"], chk) rescue nil
    #    batchid = "#{processing_date}_#{transmission_id}_#{batch_id}"
    file_name = parse(conf["IMAGE"]["image_file_name"], chk) rescue nil
    if file_name
      file_names = file_name.split('.')
      file_names.pop
      file_name = file_names.join('.')
    end
    return file_name
  end

  #Unused method (i think)
  def return_data chk, hash, record
    hash.each do |k,v|
      data = chk.xpath(v).text.strip
      unless data.squeeze == "9" or data == "0"
        record[k] = data
      else
        record[k] = ""
      end
    end
    return record
  end

  def find_checkdate tag = nil
    #  check_date
    date = tag ? parse(conf['CHEQUE']['check_date'], tag) : parse(conf['CHEQUE']['check_date'])
  end

  def parse_values(data, object, tag = nil, atag = nil)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = tag ? parse(v, tag) : parse(v)
      else
        if v[1] == "date"
          if data == "BATCH"
            object[k] = v[2] ? Date.strptime(parse(v[0],atag), v[2]) : Date.rr_parse(parse(v[0]), true) rescue nil
          elsif data == "CHEQUE"
            object[k] = v[2] ? Date.strptime(parse(v[0],tag), v[2]) : Date.rr_parse(parse(v[0]), true) rescue nil
          end
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0],tag))
        end
      end
    end
  end

  def get_correspondence_path
    path = nil
    correspondence_xml_path_names = ["/ins:Transmission/ins:Batch/ins:Correspondence", "/ins:Transmission/ins:Correspondence"]
    correspondence_xml_path_names.each do |name|
      xpath = doc.xpath(name)
      if xpath.present?
        path = xpath
        break
      end
    end
    path
  end

  def save_correspondence_items(correspondence_xml_path)
    if correspondence_xml_path.present?
      @corr_batches =  correspondence_xml_path.length
      if @corr_batches>0
        InputBatch.log.info "Number of cheques: #{@corr_batches}"
        correspondence_xml_path.each do |element|
          save_record(element, doc, element, true)
        end
      end
    end
  end
  
end
