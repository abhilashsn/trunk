require 'csv'
require 'yaml'
require 'input_batch'

# base class used for csv index file parsing and batch loading. The details of which columns
# of the csv file to parse to get data is written in a seperate yml file different
# for different facilities. So new facility can be done by creating new configuration(yml) file.
class InputBatch::IndexCsvTransformer
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

  def transform cvs
    process_csv cvs
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

  def process_csv cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false)
    csv.each do |row|
      @row = row
      save_records
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

      images = prepare_image
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
      @job_index = job_index
      tag ? parse_values("JOB", @job, tag) : parse_values("JOB", @job)
      @job.guid_number= tag ? parse("guid_number", tag) : parse("guid_number")
      @job = update_job @job
      @jobs << @job
    end
  end


  def prepare_micr
    if conf["MICR"]
      aba_routing_number_pos = conf["MICR"]["aba_routing_number"]
      aba_routing_number = parse(aba_routing_number_pos)
      payer_account_number_pos = conf["MICR"]["payer_account_number"]
      payer_account_number = parse(payer_account_number_pos)
      MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
    end
  end

  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    return images
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

  def split_image(count, path, dir_location, new_image_base_name)
    system("tiffsplit #{path} #{dir_location}/#{new_image_base_name}")
  end

  #this method is used to get the single image based on condition
  def get_single_image(file,new_image_base_name)
    File.basename(file).split('.').first =~ /#{new_image_base_name}[a-z][a-z][a-z]/
  end

  # method to find batchid
  def find_batchid
    method = "get_batchid"
    if self.methods.include?("#{method}_#{@fac_sym}".to_sym)
      method << "_#{@fac_sym}"
    elsif self.methods.include?("#{method}_#{@client_sym}".to_sym)
      method << "_#{@client_sym}"
    end
    batchid = send(method)
    return batchid
  end


  #### methods for setting values which are not parsed from index file during batch loading ####


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
    return bat
  end

  def update_job job
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
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
    check_number = parse(cnf['PAYMENT']['CHEQUE']['check_number'])
    check_amount = parse(cnf['PAYMENT']['CHEQUE']['check_amount'][0])
    condition = (check_number.blank? or check_number.squeeze == '0') &&
      (check_amount.blank? or parse_amount(check_amount) == 0.0)
    @type = condition ? 'CORRESP' : 'PAYMENT'
  end

  def find_type_pathology_medical_services
    @type = row.size < 4 ? 'CORRESP' : 'PAYMENT'
  end

  def find_type_nebraska_lablinc
    @type = row.size < 4 ? 'CORRESP' : 'PAYMENT'
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
    end unless amount_str.nil?
    amount_str.gsub(/[^\d\.]/, "").scan(/\d+\.?\d*/)[0].to_f rescue nil
  end

  def parse(v)
    row[v].strip rescue nil
  end

  def conf
    cnf[type] rescue cnf['PAYMENT']
  end

  def job_condition
    job_index.blank? ? true : (@job_index != job_index)
  end

  def job_index tag = nil
    if conf["JOB"]["job_index"]
      tag ? parse(conf["JOB"]["job_index"], tag) : parse(conf["JOB"]["job_index"])
    else
      nil
    end
  end

  def get_batchid
    parse(conf['BATCH']['batchid'])
  end

  def get_batchid_visalia_medical_clinic
    string = parse(conf['BATCH']['batchid'])
    if string
      str = string.split("-")[1..-1].join("-") rescue nil
      batchid = str.split("_")[0..-2].join("_") rescue nil
    end
    return batchid
  end

  def get_batchid_navicure
    string = parse(conf['BATCH']['batchid'])
    batchid = string.split("_").last rescue nil
    date = parse(conf['BATCH']['date'][0])
    bat_date = Date.rr_parse(date, true).strftime("%m%d%Y") rescue nil
    "#{batchid}_#{bat_date}"
  end

  def get_batchid_blue_ridge_pediatrics
    date = parse(conf['BATCH']['date'][0])
    batchid = Date.rr_parse(date, true).strftime("%m%d%Y") rescue nil
    "#{batchid}"
  end

  def get_batchid_optim_healthcare
    @zip_file_name.upcase.chomp("_LOCKBOX.ZIP").chomp(".ZIP")                                   #batch id is the last segment of quadax zip file name (excluding '.zip')
  end


  def get_batchid_tattnall_hospital_company_llc
    @zip_file_name.upcase.chomp("_LOCKBOX.ZIP").chomp(".ZIP")                                   #batch id is the last segment of quadax zip file name (excluding '.zip')
  end

  def get_batchid_hurley_medical_center
     @zip_file_name[0...-4]
  end

  def get_batchid_robinson_memorial_hospital_lab
    @zip_file_name[0...-4]
  end

  def get_batchid_downey_regional_medical_center
    batch_id =  parse(conf['BATCH']['batchid'])
    date = parse(conf['BATCH']['date'][0])
    bat_date = Date.rr_parse(date, true).strftime("%m%d%Y") rescue nil
    "#{batch_id}_#{bat_date}"
  end

  def get_batchid_nebraska_lablinc
    @zip_file_name.upcase.chomp("_LOCKBOX.ZIP").chomp(".ZIP")                                   #batch id is the last segment of quadax zip file name (excluding '.zip')
  end


  def get_batchid_quadax
  #    if ["GOOD SHEPHERD MEDICAL CENTER","GOOD START GENETICS","PATHOLOGY MEDICAL SERVICES"].include? (@facility.name.upcase.strip)
#       @zip_file_name[0...-4]
#    else
      @zip_file_name.split(/_/).last[0...-4]                                      #batch id is the last segment of quadax zip file name (excluding '.zip')
#    end
    end

  def get_batchid_good_shepherd_medical_center
    return zip_name_without_extension
  end

  def get_batchid_good_start_genetics
   return zip_name_without_extension
  end

  def get_batchid_pathology_medical_services
   return zip_name_without_extension
  end

  def get_batchid_univ_hosp_lab_svc_foundation
    return zip_name_without_extension
  end

  def get_batchid_stanford_university_medical_center
   return zip_name_without_extension
  end

  def get_batchid_wellstar_laboratory_services
   return zip_name_without_extension
  end

  def get_batchid_pathology_consultants_llc
   return zip_name_without_extension
  end

  def get_batchid_ucb
    @zip_file_name[0...-4]                                           #batch id is the quadax zip file name (excluding '.zip')
  end

  def get_batchid_mount_nittany_medical_center
    @zip_file_name[0...-4]                                            #batch id is the quadax zip file name (excluding '.zip')
  end

  def get_batchid_benefit_recovery
    @zip_file_name[0...-4]                                           #batch id is the quadax zip file name (excluding '.zip')
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

  def zip_name_without_extension
    @zip_file_name[0...-4]
  end

end
