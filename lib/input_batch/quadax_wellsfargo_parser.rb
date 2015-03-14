class InputBatch::QuadaxWellsfargoParser  < InputBatch::DatParser

  def get_batchid_general(batchid=nil)
    @zip_file_name[0...-4]
  end

  def save_records
    if type
      prepare_batch
      save_all_data_from_index_file
    end
  end

  def save_all_data_from_index_file
    if @bat
      update_batch_information
      prepare_job
      @bat.jobs << @job if @job_condition
      create_job_and_check
      @flag = 0
    end
  end

  def create_job_and_check
    if @job_condition
      images = create_images_for_jobs
      chk = prepare_cheque
      @job.check_informations << chk
      @job.initial_image_name = @initial_image_name
      mic=update_payment_related_info(type,chk,facility)
    end
    save_batch_job_check_information(images,chk,mic)

  end

  def save_batch_job_check_information(images,chk,mic)
    if @flag == 0
      save_all_information(images,chk,mic)
    end
  end

  def save_all_information(images,chk,mic)
    if @bat.save
      save_job_related_info(images,chk,mic)
    else
      raise "Error on line #{@row_index} : Cannot save batch"
    end
  end

  def save_job_related_info(images,chk,mic)
    if @job.save
      save_all_images(images)
      total_number_of_images = number_of_pages(@job)
      check_number = chk.check_number if !chk.blank?
      estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
      @job.update_attributes(:estimated_eob => estimated_eob, :pages_to => total_number_of_images)
      save_check_and_micr_info(chk,mic)
    else
      raise "Error on line #{@row_index} : Cannot save job for batch #{@bat.batchid}"
    end
  end
  
  def save_check_and_micr_info(chk,mic)
    if @job_condition and chk.save
      InputBatch::Log.status_log.info "Check id #{chk.id}, check_number #{chk.check_number}, Job id #{chk.job.id}, batch id #{chk.job.batch.id} successfully loaded"
      save_micr(chk,mic)
    end
  end

  def save_micr(chk,mic)
    if mic and mic.save
      InputBatch::Log.status_log.info "Check #{chk.id} associated to micr #{chk.micr_line_information.id}"
      @job.save_payer_group(mic)
    end
  end

  def save_all_images(images)
    unless images.blank?
      images.each do |image|
        save_image(image)
      end
    end
  end

  

  def update_batch_information
    @img_count = 1 if @job_condition
    if @inbound_file_information
      @bat.inbound_file_information = @inbound_file_information
      @bat.arrival_time = @inbound_file_information.arrival_time
    end
  end

  def create_images_for_jobs
    images,@initial_image_name = prepare_image
    images.each{|image| @bat.images_for_jobs << image}
    images.each{|image| @job.images_for_jobs << image}
    return images
  end

  def update_job_status(facility,payer)
    if !facility.payer_ids_to_exclude.blank?
      @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
    elsif !facility.payer_ids_to_include.blank?
      @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
    end
  end

  def update_payment_related_info(type,chk,facility)
    if type == 'PAYMENT'
      mic = prepare_micr
      @job.check_informations << chk
      if mic
        update_micr_info(mic,chk,facility)
        mic.check_informations << chk
      end
      return mic
    end
  end

  def update_micr_info(mic,chk,facility)
    if mic.payer_id
      payer = mic.payer
      chk.payer_id = mic.payer_id
      delete_exclude_job(facility,chk.payer_id)
      update_job_status(facility,payer)
    end
  end

  def delete_exclude_job(facility,payer_id)
    if InputBatch.is_exclude_payer( facility, payer_id)
      @job.delete
      @type = nil
      @flag = 1
    end
  end

end