require 'csv'
require 'yaml'
require 'input_batch'
#
# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxCsvTransformerKetteringPathologyAssoc< InputBatch::IndexCsvTransformer
  attr_accessor :csv, :cnf, :type, :facility, :row


  def transform cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false)
    csv.each do |row|
      @row = row
      @batch_exist = save_records
      if @batch_exist
        break
      end
    end
    csv.close
    puts ">>Index Transformation Ends " + Time.now.to_s
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end



  def save_records
    find_type
    prepare_batch

    if @bat.nil?
      @bat = Batch.find(:first,:conditions=>{:batchid=>@batchid})
    end

    @bat.inbound_file_information = @inbound_file_information if @inbound_file_information

    @job_condition = job_condition
    @img_count = 1 if @job_condition

    images,@initial_image_name = prepare_image
    if !images.nil?
      images.each{|image| @bat.images_for_jobs << image}

      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}

      if @job_condition
        chk = prepare_cheque
        @job.check_informations << chk

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

      @bat.save
      if @job.save
        images.each do |image|
          if image.save
            InputBatch.log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
            puts "Image #{image.filename} successfully loaded"
          end
        end
        check_number = chk.check_number if !chk.blank?
        estimated_eob = @job.estimated_no_of_eobs(nil, mic, check_number)
        total_number_of_images = number_of_pages(@job)
        @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

        if @job_condition and chk.save
          InputBatch.log.info "Check id #{chk.id}, check_number #{chk.check_number}, Job id #{chk.job.id}, batch id #{chk.job.batch.id} successfully loaded"
          if mic and mic.save
            InputBatch.log.info "Check #{chk.id} associated to micr #{chk.micr_line_information.id}"
            @job.save_payer_group(mic)
          end
        end
      end
      return false
    else
      puts "Batch #{@bat.batchid} is already loaded"
      return true
    end
  end

  def prepare_batch
    batchid = find_batchid
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? #and @batchid != batchid
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
      @batchid = batchid
    end
  end

  def prepare_image
    images = []
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    path =  Dir.glob("#{@location}/**/#{image_file_name}").first
    count = %x[identify "#{path}"].split(image_file_name).length-1
    new_image_name = File.basename("#{path}")
    if count>1
      dir_location = File.dirname("#{path}")
      ext_name = File.extname("#{path}")
      new_image_base_name = new_image_name.chomp("#{ext_name}")
      InputBatch.split_image(count,path, dir_location, new_image_base_name)
      single_images = Dir.glob("#{@location}/**/*").select{|file| InputBatch.get_single_image(file, new_image_base_name)}.sort
      single_images.each_with_index do |single_image, index|
        new_image_name = "#{dir_location}/#{new_image_base_name}_#{index}#{ext_name}"
        File.rename(single_image, new_image_name)
        image = ImagesForJob.create(:image => File.open(new_image_name), :image_number => @img_count,:is_splitted_image=>true)
        @img_count += 1
      end
    else
      image = ImagesForJob.new(:image_file_name=>"#{new_image_name}")
      image = update_image image
    end
    if !image.nil?
      images << image
      return images,image_file_name
    else
      return nil,nil
    end
  end

  def update_image image
    image.image_file_name = image.image_file_name.strip.split("\\").last unless image.image_file_name.blank?
    @image_exist = ImagesForJob.find(:first, :conditions => {:image_file_name => image.image_file_name})
    if @image_exist
      return nil
    else
      image_path = Dir.glob("#{@location}/**/#{image.filename}")[0]
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
  end

end

