
class InputBatch::IdxCsvTransformerTestClient< InputBatch::IndexCsvTransformer

  def transform cvs
    @starting_page_number = 1
    process_csv cvs
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
          @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images, :starting_page_number => @starting_page_number)
          @starting_page_number += total_number_of_images

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

  def find_batchid
    batchid = parse(conf['BATCH']['batchid'])+"_"+Time.now.strftime("%m%d%Y")
    "#{batchid}"
  end

  def update_job job
    job.estimated_eob = job.estimated_no_of_eobs(nil, nil, job.check_number)
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
  
end
