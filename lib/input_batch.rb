CNF_PATH = "#{Rails.root}/lib/yml"

require 'zip/zip'

class String
  def to_file
    self.downcase.gsub(" ", "_")
  end
end

module InputBatch
  require 'utils/rr_logger'    
  module Log    
    def self.setup_log zip, facility
      @error_logger = RevRemitLogger.new_logger(LogLocation::BLDELOG)
      @status_logger = RevRemitLogger.new_logger(LogLocation::BLDSLOG)
      header = <<HEAD 
########################################################################
#  ZipFileName : #{zip} 
#  Facility    : #{facility} 
#  User        : #{ENV['USERNAME']}             
#  Time        : #{Time.now}
########################################################################
HEAD
      @status_logger.info(header)
      @error_logger.info(header)
    end
        
    def self.error_log
      @error_logger
    end
  
    def self.status_log
      @status_logger
    end
    
    def self.write_log message
      @status_logger.debug message
      puts message
    end
  end
  
  def self.log
    log_loc = "#{Rails.root}/IdxLog/#{Time.now.strftime("%m%d%Y")}"
    FileUtils.mkdir_p(log_loc)
    Logger.new("#{log_loc}/IdxTransform.log")
  end
  
  def self.class_for(idx_ext, facility)
    detect_class(idx_ext, facility) || 
      detect_class(idx_ext, facility.client) || 
      detect_class(idx_ext, facility.client.partner) ||
      detect_class(idx_ext)
  end

  def self.cnf_parser_file(idx_ext, parser)
    parser_name = parser.to_file
    cnf = "idx_#{parser_name}_#{idx_ext}.yml"
    cnf_file = "#{CNF_PATH}/#{cnf}"
    if File.exists?(cnf_file) 
      cnf_file
    else
      raise "Cannot find configuration YML file : #{cnf_file}"      
    end
  end
  
  def self.class_for_parser(lockbox, parser_type)
    file_name = "#{lockbox.downcase}#{parser_type}_parser"
    const_get(file_name.camelize) rescue const_get("#{parser_type}_parser".camelize)
  end

  def self.detect_class(idx_ext, organization = nil)
    if organization
      organization_name = organization.name.gsub("'", "")
      org_name = organization_name.to_file
      file_name = "idx_#{idx_ext}_transformer_#{org_name}"
    else
      file_name = "index_#{idx_ext}_transformer"
    end
    const_get(file_name.camelize) rescue nil
  end
  
  def self.config_file(idx_ext, facility)
    cnf_file(idx_ext, facility) ||
      cnf_file(idx_ext, facility.client) ||
      cnf_file(idx_ext, facility.client.partner) ||
      cnf_file(idx_ext)
  end
  
  def self.cnf_file(idx_ext, organization = nil)
    if organization
       organization_name = organization.name.gsub("'", "")
      org_name = organization_name.to_file
      cnf = "idx_#{org_name}_#{idx_ext}.yml"
    else
      cnf = "idx_#{idx_ext}.yml"
    end
    cnf_file = "#{CNF_PATH}/#{cnf}"
    File.exists?(cnf_file) ? cnf_file : nil
  end
  
  def self.ext_name(file)
    File.extname(file).delete(".").to_file
  end
  
  def self.get_batchid
    batch = Batch.last
    if batch
      batchid = batch.batchid.to_i(36) - 1
      batchid = batchid.to_s(36).upcase
    else
      batchid = "ZZZZZZ"
    end
  end

  def self.do_transpose(batch,aba,check_number)
    status = false
    if batch.id
      check_informations = CheckInformation.find(:all,:select=>"id,check_number",\
          :conditions=>"jobs.batch_id= #{batch.id} and check_informations.check_number
          ='#{check_number}'",:include => [:job])
      if check_informations
        check_informations.each do |ci|
          aba_number_exist = MicrLineInformation.find(:first,:conditions=>"id=
              #{ci.micr_line_information_id} and aba_routing_number=#{aba}")
          if aba_number_exist
            status = true
          end
        end
      end
    end
    return status
  end
  
  def self.do_warrant(row)
    if row[11] == "121113423"
      row[13], row[12] = row[12], "000000000"
    end
  end

  def self.is_corresp_process(facility)
    (facility.batch_load_type.upcase.include?('C')) ? true : false
  end

  def self.is_payment_process(facility)
    (facility.batch_load_type.upcase.include?('P')) ? true : false
  end
  
  def self.is_exclude_payer(facility,payid)
    unless facility.payer_ids_to_exclude.blank?
      (facility.payer_ids_to_exclude.include?(payid.to_s)) ? true : false
    end
  end

  def self.convert_multipage_to_singlepage(image,location,img_count,pds_actual_image_number = nil,pds_new_batch_flag = nil)
    images = []
    @location = location
     @image_number_in_batch = pds_actual_image_number
     if !@image_number_in_batch.blank?
     if pds_new_batch_flag == true
       @image_page_number_in_batch = 0
     end
   end
    @img_count = img_count
    image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    path =  Dir.glob("#{@location}/**/#{image_file_name}").first
    count = %x[identify "#{path}"].split(image_file_name).length-1
    new_image_name = File.basename("#{path}")
    initial_image_name = new_image_name
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
        split_image(count,path, dir_location, new_image_base_name)
        single_images = Dir.glob("#{@location}/**/*").select{|file| get_single_image(file, new_image_base_name)}.sort
        single_images.each_with_index do |single_image, index|
          new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
          File.rename(single_image, new_image_name)
          image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
          @img_count += 1
          unless @image_number_in_batch.blank?
            @image_page_number_in_batch += 1
           image.actual_image_number = @image_page_number_in_batch
           
         end
           images << image
        end
      end
    else
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
      image = update_image image
      images << image
    end
    return images,initial_image_name
  end

  def self.update_image image
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

  def self.split_image(count, path, dir_location, new_image_base_name)
    system("tiffsplit #{path} #{dir_location}/#{new_image_base_name}")
  end
  
  #this method is used to get the single image based on condition
  def self.get_single_image(file,new_image_base_name)
    file_name = File.basename(file).split('.')
    file_name.pop
    file_name = file_name.join('.')
    file_name =~ /#{new_image_base_name}[a-z][a-z][a-z]/
  end

  # This method is for merging image zip files plus index file of dayton into 1 zip
  def self.create_zip_for_dayton file_path,facility
    zip_files =  Dir.glob("#{file_path}/*.[Z,z][I,i][P,p]")
    facility_name = facility.split(" ").first.downcase
    time_stamp = Time.now.strftime("%Y%m%d%H%M%S")
    Zip::ZipOutputStream::open("#{file_path}/#{time_stamp}_#{facility_name}.zip") do |zipfile|
      zip_files.each do |zip|
        Zip::ZipFile.open(zip) do |file|
          file.each do |f|
            zipfile.copy_raw_entry(f)
          end
        end
        File.delete(zip)
      end
    end

    Zip::ZipFile.open("#{file_path}/#{time_stamp}_#{facility_name}.zip") do |zipfile|
      filename = Dir.glob("#{file_path}/*.[I,i][D,d][X,x]").first
      zipfile.add(File.basename(filename), filename)
    end
  end

  def self.prepare_ocr_input(batch_id)
    begin
      provider_id = EnvironmentVariable.find_by_name("ProviderId").value #unique id of the instance
      batch = Batch.find(batch_id, :include => [{:jobs => [:images_for_jobs, :check_informations]}])
      dir_name = "#{batch.batchid}"
      Dir.mkdir("#{Rails.root.to_s}/OCR_IMAGES/#{dir_name}")
      ocr_job_counter = 0
      builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
        xml.BATCH("BatchNumber" => batch.batchid, "count" => batch.jobs.count, "ProcType" => "EOB", "DueTime" => "") do
          batch.jobs.each do |job|
            check = job.check_informations.first
            payer = check.micr_line_information.payer if check.micr_line_information
            payerid = payer.nil? ? "" : payer.payid
            is_ocr_job = check.micr_line_information.is_ocr if check.micr_line_information
            if is_ocr_job
              ocr_job_counter += 1
              images = job.images_for_jobs
              xml.document("DocID" => job.id, "Name" => "#{job.id}_#{provider_id}.tif", "CheckAmount" => ("%.2f"%check.check_amount rescue nil), "ProviderID" => provider_id, "PayerID" => payerid, "Pages" => images.count )
              images_path = job.images_for_jobs.collect{|image_for_job| Rails.root.to_s + "/private" + image_for_job.image.url.split("?").first}
              if images.count > 1
                convert_single_page_to_multipage(images_path, job.id, dir_name, provider_id)
              else
                system("cp #{images_path.first} #{Rails.root.to_s}/OCR_IMAGES/#{dir_name}/#{job.id}_#{provider_id}.tif")
              end
              job.update_attributes(:job_status => "OCR", :ocr_status => "OCR")
            end
          end
        end
      }
      if ocr_job_counter > 0
        xml_file_name = "#{provider_id}_#{batch.batchid}_OCR_#{Time.now.strftime("%y%m%d%H%M%S")}.xml"
        dir_path = "#{Rails.root.to_s}/OCR_IMAGES/#{dir_name}"
        doc = Nokogiri::XML(builder.to_xml)
        doc.root.set_attribute("count", "#{ocr_job_counter}")
        File.open("#{dir_path}/#{xml_file_name}", 'w') { |f| f.write(doc.to_xml) }
        zip_filename = "#{xml_file_name.split(".xml").first}.zip"
        batch.update_attribute(:ocr_zip_file_name, zip_filename)
        create_zip_file(zip_filename, dir_path, dir_name)
      end
      FileUtils.rm_rf("#{Rails.root.to_s}/OCR_IMAGES/#{dir_name}")
    rescue
      FileUtils.rm_rf("#{Rails.root.to_s}/OCR_IMAGES/#{dir_name}")
    end
  end

  def self.convert_single_page_to_multipage(single_page_images, job_id, dir_name, provider_id)
    begin
      system("tiffcp -a #{single_page_images.join(' ')} #{Rails.root.to_s}/OCR_IMAGES/#{dir_name}/#{job_id}_#{provider_id}.tif" )
    rescue
      InputBatch::Log.error_log.error ">>>>>>>>>>>>>>>> Error while converting single page to multipage <<<<<<<<<<<<<<"
      puts ">>>>>>>>>>>>>>>> Error while converting single page to multipage <<<<<<<<<<<<<<"
    end
  end

  def self.create_zip_file(bundle_filename,dir_path, dir_name)
    Dir.chdir(dir_path)
    FileUtils.rm bundle_filename,:force => true
    Zip::ZipFile.open(bundle_filename, Zip::ZipFile::CREATE) { |zipfile|
      Dir.foreach(dir_path) do |item|
        item_path = "#{dir_path}/#{item}"
        zipfile.add(item,item_path) if File.file?item_path
      end
    }
    FileUtils.mv("#{dir_path}/#{bundle_filename}", "#{Rails.root.to_s}/OCR_IMAGES/OUT")
    FileUtils.rm_rf(dir_path)
    Dir.chdir(Rails.root.to_s)
    puts "The OCR Input zip file is generated..."
  end

end
