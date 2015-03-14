require 'nokogiri'
#require 'yaml'

class  InputBatch::IdxXmlTransformerAmericanHealthNetwork< InputBatch::IndexXmlTransformer
  def transform xml
    idx_xml = File.open(xml)
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    doc.xpath(cnf["ITERATORS"]["IBAT"]).each do |e|
      InputBatch.log.info "Number of cheques: #{e.xpath(cnf["ITERATORS"]['ICHK']).size}"
      e.xpath(cnf["ITERATORS"]["ICHK"]).each do |chk|
        find_type chk
        prepare_batch e
        @job_condition = job_condition
        if @bat
          @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
          @img_count = 1 if @job_condition

          images = prepare_image chk
          images.each{|image| @bat.images_for_jobs << image}

          payer = prepare_payer chk

          prepare_job chk
          @bat.jobs << @job if @job_condition
          images.each{|image| @job.images_for_jobs << image}
          

          if @job_condition
            chq = prepare_cheque chk
            chq.payer_id = payer.id if payer
            @job.check_informations << chq
              @job.initial_image_name = @initial_image_name
            if type == "PAYMENT"
              mic = prepare_micr chk
              if mic
                payer = mic.payer
                chq.payer_id = mic.payer_id if mic.payer_id
                if !facility.payer_ids_to_exclude.blank?
                  @job.job_status = JobStatus::EXCLUDED if payer && payer.excluded?(facility)
                elsif !facility.payer_ids_to_include.blank?
                  @job.job_status = JobStatus::EXCLUDED if !facility.included_payers.include?(payer)
                end
                mic.check_informations << chq
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
              check_number = chq.check_number if !chq.blank?
              estimated_eob = @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
              @job.update_attributes(:pages_from => 1 ,:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

              if chq.save
                InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
                if mic and mic.save
                  InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}"
                  @job.save_payer_group(mic)
                end
                InputBatch.log.info "Check #{chq.id} associated to micr #{chq.payer.id}" if payer and payer.save
              end
            end
          end
        end
      end
    end
    idx_xml.close
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end



  def prepare_batch chk
    batchid = find_batchid chk
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
      @bat = Batch.new
      @job_index = 0
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      InputBatch.log.info type
      puts type
      parse_values("BATCH", @bat, chk)
      @bat = update_batch @bat
      @bat.batchid = batchid
      @bat.file_meta_hash = file_meta_hash
      prepare_blow_back chk, @bat
    else
      if @batchid != batchid
        puts "Batch #{batchid} already loaded"
        @bat = nil
      end
    end
    @batchid = batchid
  end
  #

  def prepare_payer chk
    payer_name = parse(conf["PAYER"]["payer"], chk)
    payer = Payer.find_by_payer(payer_name)
    return payer
  end

  #
  def prepare_eob svc, chq
    pat_acc_no = parse(conf['CLAIM']['patient_account_number'], svc)
    unless @pat_acc_nos.include?(pat_acc_no)
      eob = InsurancePaymentEob.new
      eob = return_data svc, cnf["CLAIM"], eob
    else
      eob = chq.insurance_payment_eobs.find_by_patient_account_number(pat_acc_no)
    end
    @pat_acc_nos << pat_acc_no
    return eob
  end

  def prepare_svc sc
    svc = ServicePaymentEob.new
    svc = return_data sc, cnf["SVC"], svc
    return svc
  end

  def find_batchid chk
    batchid = parse(conf["BATCH"]["batchid"], chk).split("\\").last rescue nil
    return batchid
  end

  def return_data chk, hash, record
    hash.each do |k,v|
      data = chk.xpath(v).text.strip
      unless data.squeeze == "9" or data == "0"
        record[k] = data
      else
        record[k] = ""
      end
    end
    return record
  end

  def parse_values(data, object, tag = nil)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = tag ? parse(v, tag) : parse(v)
      else
        if v[1] == "date"
          object[k] = v[2] ? Date.strptime(parse(v[0],tag), v[2]) : Date.rr_parse(parse(v[0]), true) rescue nil
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0],tag))
        end
      end
    end
  end

  def prepare_blow_back e, bat
    loc = "#{Rails.root}/private/data/blowback/"
    unless @batch_type.blank?
      loc += "#{facility.name}_test/"
    else
      loc += "#{facility.name}/"
    end
    loc += "#{Time.now.strftime("%d%m%Y")}"
    img_count = parse("@ImageCount", e)
    trn_count =  parse("@TransactionCount", e)
    file_name = bat.file_name.split(".")[0]
    FileUtils.mkdir_p(loc)
    File.open("#{loc}/#{file_name}.RESULTS", 'w+') do |file|
      file.puts "<Header ImageCount=\"#{img_count}\" TransactionCount=\"#{trn_count}\">"
      file.puts "</Header>"
    end
    puts "Blowback file #{file_name}.RESULTS created"
    InputBatch.log.info "Blowback file #{file_name}.RESULTS created"
  end


end
