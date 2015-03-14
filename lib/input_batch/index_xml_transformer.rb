require 'nokogiri'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which tags
# of the xml file to parse to get data is written in a seperate yml file different
# for different facilities. So new facility can be done by creating new configuration(yml) file.

class InputBatch::IndexXmlTransformer
  attr_accessor :file_meta_hash
  attr_reader :doc, :cnf, :type, :facility, :chk, :batch_type
  
  
  def initialize(cnf, facility, location, zip_file_name, inbound_file_information = nil, batch_type = nil)
    @facility = facility
    @location = location
    @cnf = YAML::load(File.open(cnf))
    @zip_file_name = zip_file_name
    @fac_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @batch_type = batch_type
    @inbound_file_information = inbound_file_information 
  end

  def transform xml
    idx_xml = File.open(xml)
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    InputBatch.log.info "Opened XML document for processing"
    puts "Opened XML document for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    doc.xpath(cnf["ITERATORS"]["IBAT"]).each do |e|
      #      log.debug "Number of cheques: #{e.xpath(cnf["ITERATORS"]['ICHK']).size}"
      e.xpath(cnf["ITERATORS"]["ICHK"]).each do |chk|
        @chk = chk
        save_records
      end
    end
    idx_xml.close
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end


  def save_records
    find_type
    prepare_batch
    @job_condition = job_condition
    if @bat          
      @img_count = 1 if @job_condition
      
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information

      images = prepare_image
      images.each{|image| @bat.images_for_jobs << image}
      
      
      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}

      if @job_condition
        chq = prepare_cheque
        @job.check_informations << chq

        @job.initial_image_name = @initial_image_name
       if type == "PAYMENT"
          mic = prepare_micr
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
          @job.update_attributes(:estimated_eob => estimated_eob, :pages_from => 1, :pages_to => total_number_of_images)

          if @job_condition and chq.save
            InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
            if mic and mic.save
              InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}" 
              @job.save_payer_group(mic)  
            end
          end
        end
      end
    end
  end
  
  def prepare_batch tag = nil
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
      tag ? parse_values("BATCH", @bat, tag) : parse_values("BATCH", @bat)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
      batch_details = ["production_status","provider_id","group_id","interchange_sender_id","interchange_receiver_id","group_sender_id","group_receiver_id","payee_name","payee_id","payee_address1","payee_address2","payee_city","payee_state","payee_zip"]
      batch_details.each do |batch_detail|
        @bat.details["#{batch_detail}".to_sym] =  parse(conf["BATCH"]["#{batch_detail}"]) unless parse(conf["BATCH"]["#{batch_detail}"]).blank?
      end
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end
  
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
    bat
  end

  def prepare_cheque tag = nil
    chq = CheckInformation.new
    tag ? parse_values("CHEQUE", chq, tag) : parse_values("CHEQUE", chq)
    chq = update_check chq
    payer_details =["payer_name","payer_address1", "payer_address2", "payer_city","payer_state","payer_zip", "chk_payer_id","chk_date","payer_supplemental_code","payer_tax_id","medistreams_payer_id"]
    payer_details.each do |payer_detail|
      chq.details["#{payer_detail}".to_sym] =  parse(conf["CHEQUE"]["#{payer_detail}"]) unless parse(conf["CHEQUE"]["#{payer_detail}"]).blank?
    end
    return chq
  end

  def update_check chk
    payer = nil
    if (chk.check_number.blank? or chk.check_number == '0') && 
        (chk.check_amount.to_f == 0.0)
      chk.check_date = find_checkdate
      # Creating default values for payer if a payer called UNKNOWN is not already existing
      payer = Payer.find(:first, :conditions => {:payer => "UNKNOWN"})
      if payer.blank?
        payer = Payer.create!(
          :payer => "UNKNOWN",
          :pay_address_one => "NOT PROVIDED",
          :pay_address_two => "NOT PROVIDED",
          :payer_city => "DEFAULT CITY",
          :payer_state => "XX",
          :payer_zip => "99999",
          :payid => "99999",
          :gateway => "client"
        )
      end
    end
    chk.check_number = '0' if chk.check_number.blank?
    chk.check_amount = 0.0 if chk.check_amount.blank?
    chk.check_amount = chk.check_amount.to_f
    return chk
  end

  def prepare_job tag = nil
    if @job_condition
      @job = Job.new
      @job_index = job_index
      tag ? parse_values("JOB", @job, tag) : parse_values("JOB", @job)
      @job.guid_number= tag ? parse("guid_number", tag) : parse("guid_number")
      @job = update_job @job
      @jobs << @job
    end
  end
  
  def update_job job
    job.check_number = '0' if job.check_number.blank?
    return job
  end

  def prepare_image tag = nil
    images = []
    image = ImagesForJob.new
    tag ? parse_values("IMAGE", image, tag) : parse_values("IMAGE", image)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
  end


  
  def prepare_micr tag = nil
    aba_routing_number = tag ? parse(conf["MICR"]["aba_routing_number"], tag) : parse(conf["MICR"]["aba_routing_number"])
    payer_account_number = tag ? parse(conf["MICR"]["payer_account_number"], tag) : parse(conf["MICR"]["payer_account_number"])
    MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
  end

  def find_batchid tag = nil
    tag ? parse(conf['BATCH']['batchid'], tag) : parse(conf['BATCH']['batchid'])
  end

  def find_checkdate tag = nil
    date = tag ? parse(conf['CHEQUE']['chk_date'], tag) : parse(conf['CHEQUE']['chk_date'])
    date = "01/01/2000" if date.nil?
    date
  end
  
  def job_condition
    job_index.blank? ? true : (@job_index != job_index)
  end
  
  def job_index tag = nil
    tag ? parse(conf["JOB"]["job_index"], tag) : parse(conf["JOB"]["job_index"])
  end
  
  def parse_values(data, object, tag = nil)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = tag ? parse(v, tag) : parse(v)
      else
        if v[1] == "date"
          object[k] = v[2] ? Date.strptime(parse(v[0]), v[2]) : Date.rr_parse(parse(v[0]), true) rescue nil
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0]))
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
  
  def find_type tag = nil
    check_number = tag ? parse(conf['CHEQUE']['check_number'], tag) : parse(conf['CHEQUE']['check_number'])
    check_amount = tag ? parse(conf['CHEQUE']['check_amount'], tag) : parse(conf['CHEQUE']['check_amount'])
    condition = (check_number.blank? or check_number.squeeze == '0') and 
      (check_amount.blank? or parse_amount(check_amount) == 0.0)
    @type = condition ? 'CORRESP' : 'PAYMENT'       
  end
  
  def conf
    cnf
  end
  
  def parse(v, tag = nil)
    if tag
      tag.xpath(v).text.strip rescue nil
    else
      chk.xpath(v).text.strip rescue nil
    end
  end
   
  #method for finding number of pages in a tiff file
  def number_of_pages job
    count = 0
    pages = job.client_images_to_jobs.length
    if (@facility.image_type == 1) && (pages < 2)
      job.images_for_jobs.each do |image|
        path =  Dir.glob("#{@location}/**/#{image.filename}").first
        count += %x[identify "#{path}"].split(image.filename).length-1                    #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end
  
  def update_job_check_number job, chq
    job.check_number = chq.check_number unless chq.check_number.blank?
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
end #class
