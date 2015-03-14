require 'nokogiri'

class  InputBatch::IdxXmlTransformerFultonCountyHealthCenter< InputBatch::IndexXmlTransformer
  def transform xml
    idx_xml = File.open(xml)    
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    @job_images = []
    @img_count = 1
    @new_batch = true
    @image_number_in_batch = 0
    image_name = doc.xpath("/ProcessVolume/ImageFile").attribute("FileName").value
     images =  prepare_image image_name
    doc.xpath(cnf["ITERATORS"]["IHEADER"]).each do |e|
      @image_number = 1
      InputBatch.log.info "Number of cheques: #{e.xpath(cnf["ITERATORS"]['IJOB']).size}"
      save_all_details_from_xml(e,images)
    end
    idx_xml.close
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def save_all_details_from_xml(e,images)
     e.xpath(cnf["ITERATORS"]["IBAT"]).each do |batch|
        prepare_batch batch
        save_batch_job_check_informations(batch,images)
     end
  end

  def save_batch_job_check_informations(batch,images)
     batch.xpath(cnf["ITERATORS"]["IJOB"]).each do |job|
          job_node = job.xpath(cnf["ITERATORS"]["ICHK"])
          job_size = job_node.size
          job_image_number = 0
          eob_node = job.xpath(cnf["ITERATORS"]["IEOB"])
          chk = job_size>0 ? job_node[0] : eob_node[0]
          @chk = chk
          job_image_number = job_size
          eob_size = eob_node.size
          job_image_number += eob_size

          find_type chk
          @job_condition = job_condition
          if @bat
            update_batch_job_check_informations(chk,job_image_number,images)
          end
        end
  end

  def update_batch_job_check_informations(chk,job_image_number,images)
    save_job_information(chk)
    job_images=[]
    actual_page_count = @image_number-1
    job_page_count = job_image_number-1
    total_page_count = actual_page_count + job_page_count
    save_batch_and_job_image_association(job_image_number,actual_page_count,total_page_count,images,job_images)
    if @job_condition
      chq,mic=save_check_and_micr_informations(chk,job_images)
    end
    if @bat.save
      if @job.save
        save_images_and_job_attributes(job_images,job_image_number,chq,mic)
      end
    end
  end

  def prepare_batch chk
    batchid = @zip_file_name.upcase.chomp("_LOCKBOX.ZIP").chomp(".ZIP")
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
      save_batch_details(chk,batchid)
    else
      batch_already_exists(batchid)
    end
    @batchid = batchid
  end

  def batch_already_exists(batchid)
    if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
  end

  def save_batch_details(chk,batchid)
    @bat = Batch.new
      @job_index = 0
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      InputBatch.log.info type
      puts type
      parse_values("BATCH", @bat, chk)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
  end
 

  def prepare_image image_name
    images = []
    image = ImagesForJob.new
    image.image_file_name = image_name
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count,@image_number_in_batch,@new_batch)
    return images
  end

 
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end

  def save_images_and_job_attributes(job_images,job_image_number,chq,mic)
    save_all_images(job_images)
    total_number_of_images =  number_of_pages(@job)
    check_number = chq.check_number if !chq.blank?
    estimated_eob =  @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
   # @job.update_attributes(:pages_from => @image_number ,:estimated_eob => estimated_eob, :pages_to => (@image_number+total_number_of_images-1))
   @job.update_attributes(:pages_from => 1 ,:estimated_eob => estimated_eob, :pages_to => total_number_of_images)
    @image_number +=  job_image_number
    save_check_and_micr(chq,mic)
  end
  
  def save_check_and_micr(chq,mic)
     if chq.save
      InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
      if mic and mic.save
        InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}"
        @job.save_payer_group(mic)
      end
    end
  end

  def save_all_images(job_images)
    job_images.each do |image|
      if image.save
        InputBatch.log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
        puts "Image #{image.filename} successfully loaded"
      end
    end
  end

  def save_job_information(chk)
    @img_count = 1 if @job_condition
    prepare_job chk
    @bat.jobs << @job if @job_condition
         
  end

  def save_check_and_micr_informations(chk,job_images)
    chq = prepare_cheque chk
    @job.check_informations << chq
    @job.initial_image_name = @initial_image_name
    @job.initial_image_name = job_images[0].filename
    if type == "PAYMENT"
      mic = prepare_micr chk
     save_micr_information(mic,chq)
    end
    return chq,mic
  end

  def save_micr_information(mic,chq)
     if mic
        payer = mic.payer
        chq.payer_id = mic.payer_id if mic.payer_id
        save_job_status(payer)
        mic.check_informations << chq
      end
  end

  def save_job_status(payer)
    if !facility.payer_ids_to_exclude.blank?
          @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
        elsif !facility.payer_ids_to_include.blank?
          @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
        end
  end

  def save_batch_and_job_image_association(job_image_number,actual_page_count,total_page_count,images,job_images)
    if job_image_number>0
      for i in actual_page_count..total_page_count
        @bat.images_for_jobs << images[i]
        @job.images_for_jobs << images[i]
        job_images << images[i]
        images[i].update_attributes(:image_number => job_images.size)
      end
    end
  end
end
