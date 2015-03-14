class IndexedImageFile::Check
  attr_reader :check, :index, :eob
  def initialize(check, index, eob)
    @check = check
    @index = index
    @eob = eob
    @batch = check.batch
    @facility = @batch.facility
    @insurance_eob_output_config = FacilityOutputConfig.insurance_eob(@facility.id).first
  end

  # Generate Method to invoke the Content for Indexed Image file
  def generate
    index_image_string = ""
    index_image_string << index_image_string_content
    index_image_string unless index_image_string.blank?
  end

  # Method to create the content for Indexed Image file
  def index_image_string_content
    index_image_content_string = [deposit_date, batch_id, insurance_type, check_number, encounter_number, file_location, lockbox_number, check_amount, check_date, check_serial_number].flatten.compact.join(",") + "\n"
    index_image_content_string unless index_image_content_string.blank?
  end
  
  def deposit_date
    check.batch.bank_deposit_date.blank? ? format_field("NA") : format_field(check.batch.bank_deposit_date.strftime("%m/%d/%Y"))
  end

  def batch_id
    check.batch.batchid.blank? ? format_field("NA") : format_field(check.batch.batchid.split("_").first)
  end

  def insurance_type
    micr_line_information = check.micr_line_information
    facilities_micr_information = micr_line_information.facilities_micr_informations.find_by_facility_id(@facility.id) unless micr_line_information.blank?
    onbase_name = facilities_micr_information.onbase_name unless facilities_micr_information.blank?

    if micr_line_information && micr_line_information.payer
      payer = micr_line_information.payer
    else
      payer = check.payer
    end
        
    if payer.blank?
      format_field("Others")
    elsif !onbase_name.blank?
      format_field(payer.payer.strip)
    else
      format_field("Others")
    end
  end

  def check_number
    (check.check_number.blank? || check.check_number == '0') ? format_field("NA") : format_field(check.check_number)
  end
  
  def encounter_number
    eob.blank? ? format_field("NA") : get_account_number
  end

  def get_account_number
    if eob.class == InsurancePaymentEob
      acc_no = eob.patient_account_number if !eob.patient_account_number.blank?
    elsif eob.class == PatientPayEob
      acc_no = eob.account_number if !eob.account_number.blank?
    end
    acc_no.blank? ? format_field("NA") : format_field(acc_no)
  end
  
  #1. for a check record search for "*_T.*" from the folder specified in #{job_path}.
  #ie: (check image name with "_T" appended with it. For ex: C2291009147F_T.tif ).
  #2. for a single page EOB record, it is the file name in images_for_jobs table, 
  #where the index of the records corresponding to this job matches with that of 
  #eob_page_number in the insurance_payment_eobs.
  #3. for eobs spanning pages, identify the file name in images_for_jobs table, 
  #where the index of the records corresponding to this job matches with that of
  # eob_page_number in the insurance_payment_eobs, and then search for a file with
  # name of the pattern "<file_name>_M.*" in the folder specified in #{job_path}.
  #4. At last the resultant filename is shown in indexed image file along with the
  #  path "c:\\import\\#{filename}"
  
  def file_location
    image = ""
    actual_image = ""
    payer = "-"
    batch = check.batch
    payer = check.payer.payer.strip unless check.payer.blank?
    batchid = batch.batchid
    batch_date = batch.date
    deposit_date = batch.bank_deposit_date.strftime("%m%d%Y")
    facility_name = batch.facility.name.upcase
    root_path = "private/data/#{facility_name.downcase.gsub(' ', '_')}/indexed_image"
    batch_path = root_path + "/#{batch_date}/#{batchid}"
    
    batch_path_for_rejected_images = root_path + "/#{batch_date}" unless batch_date.blank?
    if eob
      spanning_eob_condition = false
      if eob.class == InsurancePaymentEob
        spanning_eob_condition = (eob.image_page_no != eob.image_page_to_number) && (eob.image_page_to_number > eob.image_page_no) unless eob.image_page_to_number.blank?
      end
      check.job.images_for_jobs.each_with_index do |images_for_job, index|
        if eob.image_page_no == index + 1
          break if actual_image = images_for_job.filename
        end
      end
      if spanning_eob_condition
        image = Dir.glob("#{batch_path}/#{actual_image.chomp(".tif")}_M.*") 
        format_field("c:\\import\\#{image.to_s.split("/").last}")
      else
        format_field("c:\\import\\#{actual_image}")
      end
    else
      
      if check.job.job_status == "#{JobStatus::INCOMPLETED}" and payer and payer.upcase == "CORR" and check.correspondence?
      
        image = "#{batch_path_for_rejected_images}/#{deposit_date}_CORR.tif"
        
        
        format_field("c:\\import\\#{image.to_s.split("/").last}")
      elsif check.job.job_status == "#{JobStatus::INCOMPLETED}" and payer and payer.upcase != "CORR" and check.correspondence?
      
        
        image = "#{batch_path_for_rejected_images}/#{deposit_date}_#{payer.gsub(' ','_').upcase}.tif"
        
        format_field("c:\\import\\#{image.to_s.split("/").last}")
      else
        actual_image = check.job.images_for_jobs.first.filename
        image = Dir.glob("#{batch_path}/#{actual_image.chomp(".tif")}_T.*")
        format_field("c:\\import\\#{image.to_s.split("/").last}")
      end
    end
  
  end

  def lockbox_number
    check.batch.facility.lockbox_number.blank? ? format_field("NA") : format_field(check.batch.facility.lockbox_number)
  end

  def check_amount
    (check.check_amount.blank? || check.check_amount == 0.0) ? format_field("0") : format_field(check.check_amount)
  end

  def check_date
    date = check.check_date unless check.check_date.blank?
    # correspondence checks will be incompleted w/o a date,
    # in that case assume batch date
    date ||= check.job.batch.date
    date.blank? ? format_field("NA") : format_field(date.strftime("%m/%d/%Y"))
  end

  def check_serial_number
    format_field(index)
  end

  
  def format_field(field_value)
    field_value = field_value.to_s.gsub('.tif', '.jpg') if @insurance_eob_output_config.details[:convert_tiff_to_jpeg]
    '"' + "#{field_value}" + '"'
  end

end
