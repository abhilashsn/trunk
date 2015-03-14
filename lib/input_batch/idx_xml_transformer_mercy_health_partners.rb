require 'nokogiri'

class  InputBatch::IdxXmlTransformerMercyHealthPartners< InputBatch::IndexXmlTransformer
  def transform xml
    idx_xml = File.open(xml)    
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    @job_images = []
    doc.xpath(cnf["ITERATORS"]["IBAT"]).each do |e|
      InputBatch.log.info "Number of cheques: #{e.xpath(cnf["ITERATORS"]['IJOB']).size}"
      e.xpath(cnf["ITERATORS"]["IJOB"]).each do |job|
        prepare_batch job
        if job.xpath(cnf["ITERATORS"]["ICHK"]).size>0
          chk = job.xpath(cnf["ITERATORS"]["ICHK"])[0]
        else
          chk = job.xpath(cnf["ITERATORS"]["IEOB"])[0]
        end
        find_type chk
          
        @job_condition = job_condition
        if @bat
          @img_count = 1 if @job_condition
          if chk.attributes["imagePath"]
            @multi_page_image_name = chk.attributes["imagePath"].text
            @job_images << Dir.glob("#{@location}/#{@multi_page_image_name}")[0]
          end
          job.xpath(cnf["ITERATORS"]["IEOB"]).each do |eob|
            if eob.attributes["imagePath"]
              eob_image_name = eob.attributes["imagePath"].text #.split("/").last
              @job_images << Dir.glob("#{@location}/#{eob_image_name}")[0]
            end
          end
          @job_images = @job_images.flatten.uniq
          if chk.attributes["imagePath"]
            convert_single_page_to_multipage
            Dir.glob("#{@location}/**/images")
            images =  prepare_image chk
          end
          images.each{|image| @bat.images_for_jobs << image}
          prepare_job chk
          @bat.jobs << @job if @job_condition
          images.each{|image| @job.images_for_jobs << image}
          if @job_condition
            chq = prepare_cheque chk
            @job.check_informations << chq
            @job.initial_image_name = @initial_image_name
            if type == "PAYMENT"
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
              total_number_of_images =  number_of_pages(@job)
              check_number = chq.check_number if !chq.blank?
              estimated_eob =  @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
              @job.update_attributes(:pages_from => 1 ,:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

              if chq.save
                InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
                if mic and mic.save
                  InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}"
                  @job.save_payer_group(mic)
                end
              end
            end
          end
          @job_images=[]
        end
      end
    end
    idx_xml.close
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def convert_single_page_to_multipage
    system("tiffcp -a #{@job_images[1..-1].join(" ")} #{@location}/#{@multi_page_image_name}")
  end

  def prepare_batch chk
    batch_details= chk.text.split("\n")  
    batchid = @zip_file_name.upcase.chomp("_LOCKBOX.ZIP").chomp(".ZIP")
    @deposit_date = Date.strptime(batch_details[4].strip,"%m/%d/%Y")
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
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
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end
  
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

  def prepare_svc sc
    svc = ServicePaymentEob.new
    svc = return_data sc, cnf["SVC"], svc
    return svc
  end

  def prepare_image tag = nil
    images = []
    image = ImagesForJob.new
    tag ? parse_values("IMAGE", image, tag) : parse_values("IMAGE", image)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
  end


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

  def parse_values(data, object, tag = nil)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = tag ? parse(v, tag) : parse(v)
      else
        if v[1] == "date"
          object[k] = v[2] ? Date.strptime(parse(v[0],tag), v[2]) : Date.parse(parse(v[0]), true) rescue nil
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0],tag))
        end
      end
    end
  end

  
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = @deposit_date
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end


end
