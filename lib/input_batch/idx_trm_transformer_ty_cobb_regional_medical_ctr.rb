class InputBatch:: IdxTrmTransformerTyCobbRegionalMedicalCtr < InputBatch::IndexTrmTransformer

  def save_records
    find_type_method = "find_type_#{@fac_sym}".to_sym
    send(self.respond_to?(find_type_method)? find_type_method : :find_type)

    prepare_batch

    if @bat
      @job_condition = job_condition
      images = prepare_image
      images.each{|image| @bat.images_for_jobs << image}

      prepare_job
      @bat.jobs << @job if @job_condition
      images.each{|image| @job.images_for_jobs << image}
      if @payment_check
      @job.initial_image_name = @img_row.select{|image| image[0] == 'IMAGECHK'}.flatten[1] #.delete('.').gsub('tif', '.tif')
      elsif @corr_chcek 
         @job.initial_image_name = @img_row.flatten[1]
      end

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
          images.each_with_index do |image,page_index|
            if image.save
              InputBatch.log.info "Image #{image.filename} id #{image.id} batch id #{image.batch.id} job id #{image.jobs.first.id} successfully loaded"
              puts "Image #{image.filename} successfully loaded"
              image.update_attributes(:image_number => page_index + 1)
            end
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

  def prepare_image
    image_files = get_all_image_paths
    images = []
    image_files.each_with_index do |image_file, index|
      images << ImagesForJob.new(:image_file_name => File.basename(image_file), :image => File.open("#{image_file}","rb"), :image_number => index + 1)
    end

    ordered_image_names = @img_row.collect{|image_info| image_info.last}
    images.sort_by! {|image| ordered_image_names.index(image.image_file_name) }

    return images
  end

  def get_all_image_paths
    image_folder = Dir.glob("#{@location}/**/*.tif", File::FNM_CASEFOLD)
    image_names = @img_row.collect do |image|
      #if image[0].to_s.strip == 'IMAGECHK'
        #image[1].to_s.strip.delete('.').gsub('tif','.tif')
     # else
        image[1].to_s.strip
     # end
    end
    images = image_folder.select{|file| image_names.include?(File.basename(file))}
    raise "Cannot find images specified in the index file" if images.count != @img_row.count and @img_row.last[0] !="END"
    images
  end

  def find_batchid
    @zip_file_name[0...-4]  
  end
  def job_condition
    if parse(cnf['PAYMENT']['CHEQUE']['identifier'])== "CHECK"
      @payment_check = true
      @corr_chcek = false
    elsif parse(cnf['PAYMENT']['CHEQUE']['identifier'])== "CORR"
       @payment_check = false
      @corr_chcek = true
    end
    parse(cnf['PAYMENT']['CHEQUE']['identifier'])== "CHECK" || parse(cnf['PAYMENT']['CHEQUE']['identifier'])== "CORR"
  end
end
