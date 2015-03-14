require 'nokogiri'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which tags
# of the xml file to parse to get data is written in a seperate yml file different
# for different facilities. So new facility can be done by creating new configuration(yml) file.

class InputBatch::IdxXmlTransformerRevenueManagementSolutionsLlc < InputBatch::IndexXmlTransformer
  attr_reader :doc, :cnf, :type, :facility, :chk, :batch_type

  def transform xml
    idx_xml = File.open(xml)
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    InputBatch.log.info "Opened XML document for processing"
    puts "Opened XML document for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    iterate_data (doc)
    idx_xml.close
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def iterate_data (doc)
    doc.xpath(cnf["ITERATORS"]["IBAT"]).each do |e|
      @node = e
      document_format_value = @node.xpath(cnf["BATCH"]["document_format"]).to_s.strip
      if document_format_value.upcase != "KFI"
        send_notification_incorrect_batch
      else
        load_objects(e)
      end
    end
  end

  def load_objects(e)
    prepare_batch_information
    e.xpath(cnf["ITERATORS"]["ICHK"]).each do |chk|
      @chk = chk
      save_records
    end
  end

  def send_notification_incorrect_batch
    email_cnf = YAML::load(File.open("#{Rails.root}/config/references.yml"))
    if email_cnf['email']['batch_load_rms_kfi_wrong_batch_type']['notification'].blank?
      puts "Email configuration is missing in #{Rails.root}/config/references.yml"
    else
      email_exception_message = "Email connection not configured properly."
      RevremitMailer.notify_wrong_rms_kfi_batch_type(email_cnf['email']['batch_load_rms_kfi_wrong_batch_type']['notification'], @zip_file_name).deliver rescue puts email_exception_message
    end
    puts "EOB Lite batch received at KFI batches folder. So batch will not be loaded."
  end

  def prepare_batch_information
    @batch_information = MetaBatchInformation.new
    parse_values("BATCH", @batch_information)
  end

  def save_records
    find_type
    prepare_batch
    update_batch_information
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
        add_rms_kfi_payer_id chq
        @job.check_informations << chq
        @job.initial_image_name = @initial_image_name
        update_job_check_number @job, chq
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

          check_number = chq.check_number if !chq.blank?
          estimated_eob = @job.estimated_no_of_eobs(nil, nil, check_number)
          total_number_of_images = number_of_pages(@job)
          @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images, :pages_from => 1)

          if @job_condition and chq.save
            InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
            InputBatch.log.info "Check #{chq.id} associated to payer #{chq.payer.id}" if payer and payer.save
            if mic and mic.save
              InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}"
              @job.save_payer_group(mic)
            end
          end
        end
      end
    end
  end

  def prepare_batch
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
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
      #@bat.lockbox = chk.xpath('@id').to_s.strip
      @bat.meta_batch_information = @batch_information
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end

  def update_batch bat
    super
    due_time = @node.xpath(cnf["BATCH"]["due_time"]).to_s.strip
    bat.target_time = ActiveSupport::TimeZone.new('UTC').parse(due_time)
    bat
  end

  def prepare_job
    if @job_condition
      @job = Job.new
      parse_values("JOB", @job)
      @job = update_job @job
      @job.lockbox = chk.xpath('@id').to_s.strip
      @jobs << @job
    end
  end

  def prepare_payer
    payerid =  parse(cnf["PAYER"]["payid"])
    payer = Payer.find(:first, :conditions => {:payid => payerid} )
    if payer.blank?
      payer = Payer.new
      payer.payid = payerid
      payer.payer = 'UNKNOWN'
      payer.gateway = 'RMS'
    end
    payer
  end

  def add_rms_kfi_payer_id cheque
    payer_id =  parse(cnf["PAYER"]["payid"])
    cheque.details[:rms_kfi_payer_id] = payer_id
  end

  def job_condition
    true
  end

  def parse_values(data, object)
    cnf[data].each do |k,v|
      unless v.class == Array
        object[k] = (data == 'BATCH') ? parse(v, 1): parse(v)
      else
        if v[1] == "date"
          object[k] = v[2] ? Date.strptime(parse(v[0]), v[2]) : Date.rr_parse(parse(v[0]), true) rescue nil
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0]))
        end
      end
    end
  end

  def find_type
    check_amount =  parse(cnf['CHEQUE']['check_amount'])
    condition = check_amount.blank? or parse_amount(check_amount) == 0.0
    @type = condition ? 'CORRESP' : 'PAYMENT'
  end


  def parse(v, batch_flag = nil)
    batch_flag ? @node.xpath(v).to_s.strip : chk.xpath(v).to_s.strip rescue nil
  end

  def find_batchid
    @zip_file_name[0...-4]
  end

  def update_batch_information
    @batch_information.provider_code = chk.xpath('@ProviderID').to_s.strip
  end

  def prepare_image tag = nil
    images = []
    image = ImagesForJob.new
    tag ? parse_values("IMAGE", image, tag) : parse_values("IMAGE", image)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
  end

end
