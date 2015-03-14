
class InputBatch::IdxTxtTransformerUniversityOfPittsburghMedicalCenter< InputBatch::IndexCsvTransformer

  def process_csv cvs
    InputBatch.log.info "Opened csv file for processing"
    puts "Opened csv file for processing"
    InputBatch.log.info ">>Index Transformation Starts " + Time.now.to_s
    puts ">>Index Transformation Starts " + Time.now.to_s
    @jobs = []
    @total_jobs = 0
    @jobs_excluded = 0
    @csv = CSV.open(cvs, "r", :headers => cnf['PAYMENT']['HEADER'] || false,:col_sep => ',')
    csv.each do |row|
      @row = row
      save_records
    end
    update_batch_status
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
        era_check = nil
        era_check = EraCheck.find(:first,:conditions=>"check_number = '#{chk.check_number.to_i}'  and check_amount = #{chk.check_amount}")
        if era_check.blank? and !(chk.check_number.to_i == 0 and  chk.check_amount == 0)
          era_checks = EraCheck.find(:all,:conditions=>"check_number like '%#{chk.check_number.to_i}'  and check_amount = #{chk.check_amount}")
          era_checks.collect{|era|(era_check = era.check_number if (era.check_number.to_i == chk.check_number.to_i))}
        end
        if era_check
          @job.job_status = "INCOMPLETED"
          @job.is_excluded = 1
          @jobs_excluded += 1
          @job.processor_comments = "EDI: Duplicate"
        end
        @job.check_informations << chk
        initial_image_file_name = parse(conf['IMAGE']['image_file_name'])
        @job.initial_image_name = initial_image_file_name.strip.split("\\").last unless initial_image_file_name.blank?

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
          @total_jobs += 1
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
    batchid_from_index_file = find_batchid
    if @inbound_file_information
      batchid = parse(conf['BATCH']['lockbox'])+"_"+batch_date.to_date.strftime("%y%m%d").to_s+"_"+batchid_from_index_file+"_"+@inbound_file_information.arrival_time.utc.strftime("%y%m%d%H%M").to_s if @inbound_file_information
      bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
      @batch_condition = bat.nil? and @batchid != batchid
      if !@bat.nil? and @batchid != batchid
        update_batch_status
      end
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
    else
      InputBatch::Log.status_log.info "There is no record in inbound information table corresponding to this batch"
      puts "There is no record in inbound information table corresponding to this batch"
    end
  end

  def update_batch_status
    if @total_jobs == @jobs_excluded
      @bat.update_attributes(:status => 'COMPLETED') if @bat
    end
    @total_jobs = 0
    @jobs_excluded = 0
  end
  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.date = batch_date
    bat.bank_deposit_date = batch_date
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = Date.today if bat.date.blank?
    bat.bank_deposit_date = Date.today if bat.bank_deposit_date.blank?
    upmc_batch = Batch.find(:last,:conditions=>"ssi_batch_number is not null")
    if  upmc_batch.blank?
      ssi_number = 1
    else
      ssi_number = upmc_batch.ssi_batch_number.to_i+1
    end
    ssi_number = ssi_number.to_s.rjust(5, '0')
    bat.ssi_batch_number = ssi_number
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end

  def batch_date
    deposit_date = parse(cnf['PAYMENT']['IMAGE']['image_file_name'])
    batch_date = deposit_date.split("\\")[1]
    new_batch_date =batch_date[4..7]+"-"+batch_date[0..1]+"-" +batch_date[2..3]
    return new_batch_date
  end

  def update_job job
    job.check_number = '0' if job.check_number.blank?
    job.pages_from = 1
    job.payer = Payer.find_by_payer("No Payer")
    return job
  end

  def prepare_cheque
    chq = CheckInformation.new
    parse_values("CHEQUE", chq)
    chq = update_check chq
    return chq
  end


  def update_check chk
    chk.check_number = '0' if chk.check_number.blank? or type == 'CORRESP'
    chk.check_amount = 0.0 if chk.check_amount.blank? or type == 'CORRESP'
    chk.check_amount = chk.check_amount.to_f
    return chk
  end

  def parse(v)
    row[v].strip rescue nil
  end

  def conf
    cnf[type] rescue cnf['PAYMENT']
  end

  def find_batchid
    parse(conf['BATCH']['batchid'])
  end

end #class



