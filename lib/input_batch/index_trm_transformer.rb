require 'csv'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which columns
# of the csv file to parse to get data is written in a seperate yml file different
# for different facilities. So new facility can be done by creating new configuration(yml) file.
class InputBatch::IndexTrmTransformer
  attr_accessor :file_meta_hash
  attr_reader :csv, :cnf, :type, :facility, :row
  
  
  def initialize(cnf, facility, location, zip_file_name, inbound_file_information = nil)
    @cnf = YAML::load(File.open(cnf))
    @facility = facility
    @location = location
    @zip_file_name = zip_file_name
    @fac_sym = facility.name.to_file
    @client_sym = facility.client.name.to_file
    @inbound_file_information = inbound_file_information
  end

  def transform trm_file
    process_trm trm_file
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

   def process_trm trm_file
    InputBatch.log.info "Opened trm file for processing"
    puts "Opened trm file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(trm_file, "r", :headers => cnf['PAYMENT']['HEADER'] || false)
    @row = nil
    @img_row = []
    @check_row = nil
    csv.each do |row|
      if row[0]!= "START"
        if @row.blank? and @check_row.blank?
          @row = row
        else
          @row = @check_row unless @check_row.blank?
        end
        @img_row << row if row[0]!= "CHECK" and  row[0]!= "CORR"
        if ((row[0] =="CHECK" and !@row.blank?)||(row[0] =="END" and !@row.blank?)|| (row[0] =="CORR" and !@row.blank?))
          @check_row =  row
          if !@row.blank? and !@img_row.blank?
            save_records
          end
        end
      end
    end

    csv.close
  end

  def save_records
    find_type_method = "find_type_#{@fac_sym}".to_sym
    send(self.respond_to?(find_type_method)? find_type_method : :find_type)

    prepare_batch

    if @bat
      @job_condition = job_condition
      @img_count = 1 if @job_condition
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information

      image = prepare_image
      @bat.images_for_jobs << image

      prepare_job
      @bat.jobs << @job if @job_condition
      @job.images_for_jobs << image

      if @job_condition
        chk = prepare_cheque
        @job.check_informations << chk

        if type == 'PAYMENT'
          mic = prepare_micr
          if mic
            payer = mic.payer
            chk.payer_id = mic.payer_id if mic.payer_id
            if !facility.payer_ids_to_exclude.blank?
              @job.job_status = 'EXCLUDED' if payer && payer.excluded?(facility)
            elsif !facility.payer_ids_to_include.blank?
              @job.job_status = 'EXCLUDED' if !facility.included_payers.include?(payer)
            end
            mic.check_informations << chk
          end
        end
      end

      if @bat.save
        if @job.save
          if image.save
            InputBatch.log.debug "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
            puts "Image #{image.filename} successfully loaded"
          end
          
          total_number_of_images = number_of_pages(@job)
          check_number = chk.check_number if !chk.blank?
          estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
          @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

          if @job_condition and chk.save
            InputBatch.log.debug "Check id #{chk.id}, check_number #{chk.check_number}, Job id #{chk.job.id}, batch id #{chk.job.batch.id} successfully loaded"
            if mic and mic.save
              InputBatch.log.debug "Check #{chk.id} associated to micr #{chk.micr_line_information.id}"
              @job.save_payer_group(mic)
            end
          end
        end
      end
      @row = []
      @img_row = []
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
      InputBatch.log.debug "Preparing batch #{batchid}"
      InputBatch.log.debug type
      puts type
      parse_values("BATCH", @bat)
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


  def prepare_cheque
    chq = CheckInformation.new
    parse_values("CHEQUE", chq) if type == "PAYMENT"
    chq = update_check chq
    return chq
  end

  def prepare_job tag = nil
    if @job_condition
      @job = Job.new
      @job_index = 0
      tag ? parse_values("JOB", @job, tag) : parse_values("JOB", @job)
      @job.guid_number= tag ? parse("guid_number", tag) : parse("guid_number")
      @job = update_job @job
      @jobs << @job
    end
  end


  def prepare_micr
    if conf["MICR"]
      aba_routing_number = parse(conf["MICR"]["aba_routing_number"])
      payer_account_number = parse(conf["MICR"]["payer_account_number"])
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end

  def prepare_image
    image_file = convert_singlepages_to_multipage
    image = ImagesForJob.new(:image_file_name => File.basename(image_file))
    image.image = File.open("#{image_file}","rb")
    image.image_number = 1
    return image
  end

  def convert_singlepages_to_multipage
    image_folder = Dir.glob("#{@location}/**/*.tif", File::FNM_CASEFOLD)
    image_names = @img_row.collect{|image| image[0].to_s.strip == 'IMAGECHK' ? image[1].to_s.strip.delete('.') : image[1].to_s.strip}
    images = image_folder.select{|file| image_names.include?(File.basename(file, ".*"))}.sort
    raise "Cannot find images specified in the index file" if images.empty?
    system("tiffcp -a #{images.join(' ')}")
    images.last
  end

  # method to find batchid
  def find_batchid
    @zip_file_name.split(/_/).last[0...-4]  
  end


  #### methods for setting values which are not parsed from index file during batch loading ####


  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = Date.strptime(row[2].to_s,"%m%d%y") unless row[2].blank?
    bat.bank_deposit_date = Date.today if bat.bank_deposit_date.blank?
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end

  def update_job job
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    return job
  end

  def update_check chk
    chk.check_number = '0' if chk.check_number.blank?
    chk.check_amount = 0.0 if chk.check_amount.blank?
    chk.check_amount = chk.check_amount.to_f
    return chk
  end

  # method to find the type of batch corresponce or payment
  def find_type
    batch_type= parse(cnf['PAYMENT']['CHEQUE']['identifier'])
    #if batch_type == "CHECK"
      @type = (batch_type == "CHECK")? 'PAYMENT':'CORRESP'
      #  @type = @row[1].blank?? 'CORRESP' : 'PAYMENT'
    #end
  end

  def parse_values(data, object)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = parse(v)
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

  def parse(v)
    row[v].strip rescue nil
  end

  def conf
    cnf[type] rescue cnf['PAYMENT']
  end

  def job_condition
    parse(cnf['PAYMENT']['CHEQUE']['identifier'])== "CHECK"
  end
 
  #method for finding number of pages in a tiff file
  def number_of_pages job
    count = 0
    pages = job.client_images_to_jobs.length
    if (@facility.image_type == 1) && (pages < 2)
      job.images_for_jobs.each do |image|
        path =  Dir.glob("#{@location}/**/#{image.filename}").first
        count += %x[identify "#{path}"].split(image.filename).length-1            #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end

  def format_date date
    formated_date = Date.rr_parse(date, true) if date.is_a?(String)
  end

end
