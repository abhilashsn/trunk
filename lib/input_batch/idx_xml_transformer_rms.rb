require 'nokogiri'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which tags
# of the xml file to parse to get data is written in a seperate yml file different
# for different facilities. So new facility can be done by creating new configuration(yml) file.

class InputBatch::IdxXmlTransformerRms < InputBatch::IndexXmlTransformer
  attr_reader :doc, :cnf, :type, :facility, :chk, :batch_type
  
  def transform xml
    idx_xml = File.open(xml)
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    InputBatch.log.info "Opened XML document for processing"
    puts "Opened XML document for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    doc.xpath(cnf["ITERATORS"]["IBAT"]).each do |e|
      @node = e
      prepare_batch_information
      e.xpath(cnf["ITERATORS"]["ICHK"]).each do |chk|
        @chk = chk
        save_records
      end
    end
    idx_xml.close 
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
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
      
      images,@initial_image_name  = prepare_image
      images.each{|image| @bat.images_for_jobs << image}
           
      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}
      
      if @job_condition
        chq = prepare_cheque
        @job.check_informations << chq
        @job.initial_image_name = @initial_image_name
        if type == "PAYMENT"
          payer = prepare_payer
          if payer
            chq.payer = payer
             if !facility.payer_ids_to_exclude.blank?
              @job.job_status = JobStatus::EXCLUDED if payer.excluded?(facility)
            elsif !facility.payer_ids_to_include.blank?
              @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
            end
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
      @bat.meta_batch_information = @batch_information
      @bat.file_meta_hash = file_meta_hash
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end
  
  def prepare_job 
    if @job_condition
      @job = Job.new
      parse_values("JOB", @job)
      @job = update_job @job
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
end 
