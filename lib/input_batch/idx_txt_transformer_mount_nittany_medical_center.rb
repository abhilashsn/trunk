# To change this template, choose Tools | Templates
# and open the template in the editor.

class InputBatch::IdxTxtTransformerMountNittanyMedicalCenter< InputBatch::IndexCsvTransformer
  def process_csv cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false,:col_sep => '|')
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
      batch_date = parse(cnf["PAYMENT"]["BATCH"]["date"][0]).to_s
      @bat.date = "20"+batch_date[4..5]+"-"+batch_date[0..1]+"-"+batch_date[2..3]
      @bat.date = Date.today if @bat.date.blank?
      @job_condition = job_condition
      @img_count = 1 if @job_condition
      @bat.inbound_file_information = @inbound_file_information if @inbound_file_information

      images = prepare_image if @job_condition
      images.each{|image| @bat.images_for_jobs << image} unless images.blank?

      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image} unless images.blank?

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
      if @job_condition
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
  end

  
  def job_condition
    image = ImagesForJob.new
    parse_values("IMAGE", image)
    img_name= image.image_file_name.split("\\").last
    @image_exists = nil
    if @bat.id
      @image_exists = ImagesForJob.find(:first,:conditions=>"image_file_name='#{img_name}' and batch_id=#{@bat.id}")
    end
    return @image_exists.blank?
  end

end
