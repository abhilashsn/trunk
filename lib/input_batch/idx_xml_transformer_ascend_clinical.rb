require 'nokogiri'
class InputBatch::IdxXmlTransformerAscendClinical< InputBatch::IndexXmlTransformer
  def transform xml
    idx_xml = File.open(xml)
    @doc = Nokogiri::XML(idx_xml)
    @jobs = []
    @job_images = []
    @payment_check_items = []
    @prev_job_index = "start"
    
    doc.xpath(cnf["ITERATORS"]["IBAT"]).each do |e|
      check_items = []
      e.xpath('//*[contains(name(.),"CheckItem")]').each do |check_item|
        if (check_item.attribute('Data2').value == "Payment" || (check_item.attribute('Data2').value == "Correspondence" and (check_item.attribute('Data1').value!= @prev_job_index)))
          check_items << check_item
          @prev_job_index = check_item.attribute('Data1').value  if check_item.attribute('Data2').value == "Correspondence"
        end
      end
      check_items.each_with_index do |chk,index|
        @chk_type = chk.attribute('Data2').value
        @chk_page_begin = chk.attribute("PageBegin").value.to_i
        @chk_bank_num = chk.attribute("BankNum").value
        @chk_num = chk.attribute("ChkNum").value
        find_type chk
        prepare_batch chk
        @job_condition = job_condition
        if @bat
          @bat.inbound_file_information = @inbound_file_information if @inbound_file_information
          @img_count = 1 if @job_condition
          if chk.attributes["Src"]
            @multi_page_image_name = chk.attribute("Src").text.split("//").last
            @new_multi_page_image = @multi_page_image_name.split(".").first+"_#{index+1}"+".#{@multi_page_image_name.split(".").last}"
            @page_from = @chk_page_begin-1
            @page_to = []
            @image_name_index = []
            @last_check_item = false
            @count = 0
            @payment_check_identifier =  @chk_num + chk.attribute("PageBegin").value
            if @payment_check_items.include?(@payment_check_identifier)
              next
            else
              e.xpath('//*[contains(name(.),"CheckItem")]').each do |job|
                check_item_type = job.attribute('Data2').value
                check_item_bank_number = job.attribute("BankNum").value
                chk_number = job.attribute("ChkNum").value
                check_item_pagebegin = job.attribute("PageBegin").text.to_i
                check_item_src = job.attribute("Src").text.split("//").last
                if check_item_type == "Correspondence" and @chk_type == "Correspondence"
                  if check_item_bank_number != @chk_bank_num and check_item_src == @multi_page_image_name and @count == 0
                    if check_item_pagebegin >= @chk_page_begin
                      number_of_pages = check_item_pagebegin - @chk_page_begin
                      @page_to = []
                      @last_check_item = false
                      if number_of_pages >= 1
                        (number_of_pages).times do |p|
                          @page_to << @chk_page_begin + p-1
                        end
                      else
                        @page_to << @chk_page_begin-1
                      end
                      @count +=1
                    end
                  elsif check_item_bank_number == @chk_bank_num and check_item_src == @multi_page_image_name and !@last_check_item
                    @page_to << @chk_page_begin-1
                    @last_check_item = true
                  end
                elsif job.attribute('Data1').value == chk.attribute('Data1').value
                  @page_to << check_item_pagebegin-1
                  if job.attribute('Data2').value == "Payment"
                    @image_name_index<< index
                  end
                  @last_check_item = false
                  @payment_check_items << chk_number + job.attribute("PageBegin").value
                end 
              end
            end
            @page_to << ',' if @last_check_item 
            if @page_to.count > 1 or !@image_name_index.blank?
              @page_to = (@page_to.last == ',' ? @page_to.join : @page_to.join(","))
              image_index= @new_multi_page_image.split(".").first.split("_").first
              image_index = image_index.split("/").last
              convert_multipage_page_to_check_eob_multipage
              Dir.glob("#{@location}/**/Data")
              images =  prepare_image @new_multi_page_image
            else
              Dir.glob("#{@location}/**/Data")
              images =  prepare_image @multi_page_image_name
            end
          end
          images.each{|image| @bat.images_for_jobs << image}
          prepare_job chk
          @bat.jobs << @job if @job_condition
          images.each{|image| @job.images_for_jobs << image}
          if @job_condition
            chq = prepare_cheque chk
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
              total_number_of_images =  number_of_pages(@job)
              check_number = chq.check_number if !chq.blank?
              estimated_eob =  @job.estimated_no_of_eobs(total_number_of_images, mic, check_number)
              @job.update_attributes(:pages_from => 1 ,:estimated_eob => estimated_eob, :pages_to => total_number_of_images)

              if chq.save
                InputBatch.log.info "Check id #{chq.id}, check_number #{chq.check_number}, Job id #{chq.job.id}, batch id #{chq.job.batch.id} successfully loaded"
                if mic and mic.save
                  InputBatch.log.info "Check #{chq.id} associated to micr #{chq.micr_line_information.id}"
                  @job.save_payer_group(mic)
                end
              end
            end
          end
          @job_images=[]
        end
      end
       
    end
    idx_xml.close
    InputBatch.log.info ">>Index Transformation Ends " + Time.now.to_s
  end

 

  def prepare_batch chk
    batch_date = chk.attribute("PostedDt").value
    @deposit_date = batch_date[0..3]+"-"+batch_date[4..5]+"-"+batch_date[6..7]
    batchid = @zip_file_name.upcase.chomp(".ZIP")
    bat = Batch.find(:first, :conditions => {:batchid => batchid, :facility_id => facility.id})
    @batch_condition = bat.nil? and @batchid != batchid
    if @batch_condition
      @bat = Batch.new
      @job_index = 0
      puts "Preparing batch #{batchid}"
      InputBatch.log.info "Preparing batch #{batchid}"
      InputBatch.log.info @type
      puts @type
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


  def prepare_cheque check
    chq = CheckInformation.new
    if check.attribute("Data4")
      check_date = check.attribute("Data4").value.split("/") unless check.attribute("Data4").value.blank?
      chq.check_date = check_date[2]+"-"+check_date[0]+"-"+check_date[1] unless check_date.blank?
    end
    check_amount = check.attribute("Amt").value
    if check_amount == "0"
      chq.check_amount = check_amount
    elsif check_amount.size >= 1
      chq.check_amount = check_amount.to_i/100.00
    end
    chq.check_number = check.attribute("ChkNum").value
    chq.transaction_id = check.attribute("BankNum").value
    return chq
  end

  def prepare_job check
    @job = Job.new
    @job.check_number = check.attribute("ChkNum").value
    return @job
  end
  
  def prepare_micr check
    aba_routing_number = check.attribute("RTN").value if check.attribute("RTN")
    payer_account_number = check.attribute("AcctNum").value if check.attribute("AcctNum")
    MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, facility.commercial_payerid)
  end

  def prepare_image file_name
    images = []
    image = ImagesForJob.new(:image_file_name => file_name)
    images,@initial_image_name =  InputBatch.convert_multipage_to_singlepage(image,@location,@img_count)
    @initial_image_name = @initial_image_name.split("/").last
    return images
  end

  
  def parse_values(data, object, tag = nil)
    conf[data].each do |k,v|
      unless v.class == Array
        object[k] = tag ? parse(v, tag) : parse(v)
      else
        if v[1] == "date"
          object[k] = v[2] ? Date.strptime(parse(v[0],tag), v[2]) : Date.parse(parse(v[0]), true) rescue nil
        elsif v[1] == "float"
          object[k] = parse_amount(parse(v[0],tag))
        end
      end
    end
  end


  def update_batch bat
    bat.file_name = @zip_file_name
    bat.arrival_time = Time.now
    bat.facility_id = facility.id
    bat.client_id = facility.client_id
    bat.contracted_time = (Time.now + facility.tat.to_i.hours)
    bat.target_time = (Time.now + facility.tat.to_i.hours)
    bat.date = @deposit_date
    bat.correspondence = true if type == 'CORRESP'
    return bat
  end

  def find_type check
    @type = (check.attribute('Data2').value == "Payment") ?  'PAYMENT' : 'CORRESP'
  end

  def convert_multipage_page_to_check_eob_multipage
    location = Dir.glob("#{@location}/*").select{|i| i.split('/').last.split('.').count == 1 }
    if location.first.split('/').last  == 'Data'
      system("tiffcp #{@location}/#{@multi_page_image_name},#{@page_to} #{@location}/#{@new_multi_page_image}")
    else
      system("tiffcp #{location.first}/#{@multi_page_image_name},#{@page_to} #{location.first}/#{@new_multi_page_image}")
    end unless location.blank?
  end
end
