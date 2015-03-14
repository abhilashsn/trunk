# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxTxtTransformerPartnersInInternalMedicine< InputBatch::IndexCsvTransformer
  def process_csv cvs
    InputBatch.log.info "Opened txt file for processing"
    puts "Opened txt file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @images = []
    @previous_image = nil
    @dat = File.readlines(cvs) rescue []
    @dat.each_with_index do |row, index|
      @row_index = index + 1
      @row = row.chomp
      @type = "PAYMENT"
      InputBatch::Log.status_log.info "**** Processing index file row #{@row_index} ****"
      next_row = (@dat[index+1].blank? ? "EOF" : @dat[index+1])
      save_records(next_row)
    end
    InputBatch::Log.write_log ">>>>>Index Transformation Ends " + Time.now.to_s
  end

  def find_batchid
    @zip_file_name[0...-4]
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

  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = Date.today if bat.date.blank?
    bat.bank_deposit_date = Date.today if bat.bank_deposit_date.blank?
    return bat
  end

  def parse(v)
    row[v[0]..v[1]].strip rescue nil
  end

   
  def parse_values(data, object)
    conf[data].each do |k,v|
      if v.class == Hash
        object.details = Hash.new
        v.each do |key, value|
          object.details[key] =  parse(value).strip
        end
      else
        if v.length == 2
          object[k] = parse(v).strip
        else
          if v[2] == "date"
            object[k] = Date.rr_parse(parse(v).strip, true).strftime("%Y-%m-%d") rescue nil
          elsif v[2] == "float"
            object[k] = parse_amount(parse(v).strip)
          end
        end
      end
    end
  end

  def save_records(next_row)
    prepare_batch
    if @bat
      batch_date = parse(cnf["PAYMENT"]["BATCH"]["date"]).to_s
      @bat.date = "20"+batch_date[0..1]+"-"+batch_date[2..3]+"-"+batch_date[4..5]
      @bat.date = Date.today if @bat.date.blank?
      @job_condition = job_condition(next_row)
      @img_count = 1
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information

      images,@initial_image_name = prepare_image
      images.each{|image| @bat.images_for_jobs << image} unless images.blank?

      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image} unless images.blank?
      
      if @job_condition
        @bat.correspondence = true if @job_type == 'CORRESP'
        chk = prepare_cheque
        @job.check_informations << chk
        @job.initial_image_name = @initial_image_name
        if @job_type == 'PAYMENT'
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
      if @job_condition
        if @bat.save
          if @job.save
            images.each do |image|
              if image.save
                if image.image_file_name[14] == "C"
                  save_image_types("CHK",image)
                elsif image.image_file_name[14] == "I"
                  save_image_types("EOB",image)
                end
                InputBatch.log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
                puts "Image #{image.filename} successfully loaded"
              end
            end
            @images = []
            images = []
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
  end

  def prepare_job tag = nil
    @job = Job.new
    @job_index = job_index
    tag ? parse_values("JOB", @job, tag) : parse_values("JOB", @job)
    @job.guid_number= tag ? parse("guid_number", tag) : parse("guid_number")
    @job = update_job @job
    @jobs << @job
  end

  #Saving values in image_types table

  def save_image_types type_of_image, job_image
    @image_type = ImageType.new
    @image_type.image_type = type_of_image
    @image_type.images_for_job_id = job_image.id
    @image_type.image_page_number = job_image.image_number
    @image_type.save
  end

  #method for finding number of pages in a tiff file
  def number_of_pages job
    count = 0
    pages = job.client_images_to_jobs.length
    if (@facility.image_type == 1) && (pages < 2)
      job.images_for_jobs.each do |image|
        path =  Dir.glob("#{@location}/Parser/Images/#{image.filename}").first
        count += %x[identify "#{path}"].split(image.filename).length-1            #command for retrieve number of pages in a  tiff file (multi/single)
      end
      pages = count
    end
    pages
  end

  def image_parse
    @img_1 = parse(cnf["PAYMENT"]["IMAGE"]["image_file_name1"]).to_s
    @img_2 = parse(cnf["PAYMENT"]["IMAGE"]["image_file_name2"]).to_s
    @img_3 = parse(cnf["PAYMENT"]["IMAGE"]["image_file_name3"]).to_s
    @img_4 = parse(cnf["PAYMENT"]["IMAGE"]["image_file_name4"]).to_i.to_s
    @img_5 = parse(cnf["PAYMENT"]["IMAGE"]["image_file_name5"]).to_i.to_s
    front_img = @img_1 + "_" + @img_2 + "_" + @img_3 + "_FrontItem" + @img_4 + "_" + @img_5 + ".tif"
    return front_img
  end

  def prepare_image
    front_img = image_parse
    if @img_3 == "I"
      if @previous_image == front_img
        front_img.gsub!("FrontItem","RearItem")
      end
    end
    image = ImagesForJob.new(:image_file_name=>front_img)
    image = update_image image
    @images << image
    @previous_image = front_img
    return @images,front_img
  end

  def update_image image
    image.image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    image_path = Dir.glob("#{@location}/Parser/Images/#{image.image_file_name}")[0]
    image.image = File.open("#{image_path}","rb")
    image.image_number = @img_count
    @img_count += 1
    if Dir.glob("#{@location}/Parser/Images/#{image.filename}")[0]
      InputBatch.log.info "Image #{image.filename} found"
    else
      InputBatch.log.info "Image #{image.filename} not found"
    end
    return image
  end
  
  def job_condition(next_row)
    if parse(cnf["PAYMENT"]['BATCH']['transaction_number']) != next_row[81..83].to_s
      if parse(cnf["PAYMENT"]['BATCH']['record_type']) == "C"
        @job_type = "PAYMENT"
      else
        @job_type = "CORRESP"
      end
      return true
    else
      return false
    end
  end
  
end
