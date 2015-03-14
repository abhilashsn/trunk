class IndexedImageFile::UniversityOfPittsburghMedicalCenterCheck
  attr_reader :check, :index
  def initialize(check, index)
    @check = check
    @index = index
    @batch = check.batch
    @facility = @batch.facility
    @insurance_eob_output_config = FacilityOutputConfig.insurance_eob(@facility.id).first
    @batchid_array = @batch.batchid.split('_') unless @batch.batchid.blank?
    @deposit_date = Date.strptime @batchid_array[1], "%y%m%d" unless @batchid_array.blank?
    @original_facility = UpmcFacility.find_by_name(@check.payee_name)
    @check_date = check.check_date unless check.check_date.blank?
    @is_correspndence_check = check.correspondence?
    #Update the transaction reference number to make it unique accorss o/p files
    reference_sequence = Sequence.find('UPMC_REF_NUMBER')
    reference_sequence.value += 1 if @is_correspndence_check
    reference_sequence.save!
    check_number = check.check_number unless check.check_number.blank?
    @check_number_formatted = @is_correspndence_check ? "-#{reference_sequence.value}" : check_number.gsub(/^[0]*/,"")
    @batch_lockbox = @batch.lockbox
    @bank_batch_number = @batchid_array[2].gsub(/^[0]*/,"")
    @check_transaction_id = @check.transaction_id
    @job = check.job
    job_image_name = @job.initial_image_name
    @job_image_name_formatted = job_image_name.gsub(/^[0]*/,"")
  end

  # Generate Method to invoke the Content for Indexed Image file
  def generate
    index_image_string = ""
    index_image_string << index_image_string_content
    index_image_string unless index_image_string.blank?
  end

  # Method to create the content for Indexed Image file
  def index_image_string_content
    index_image_content_string = [renamed_file_name, lockbox_batch_seq_number,
      check_eft_number, deposit_date, facility_entity_code, check_date,
      payer_name, elbm_code, translated_facility_check_date].
      flatten.compact.join("~") + "\n"
    index_image_content_string unless index_image_content_string.blank?
  end

  def renamed_file_name
    deposit_date_formatted = (@deposit_date.blank? ? '' : @deposit_date.strftime("%Y%m%d"))
    @batch_lockbox + deposit_date_formatted + @job_image_name_formatted
  end

  def lockbox_batch_seq_number
    @batch_lockbox + ' ' + @bank_batch_number + ' ' + @check_transaction_id
  end

  def check_eft_number
    @check_number_formatted.blank? ? '' : @check_number_formatted
  end
  
  def deposit_date
    @deposit_date.blank? ? '' : @deposit_date.strftime("%m/%d/%Y")
  end
  
  def facility_entity_code
    @original_facility.facility_abbreviation unless @original_facility.blank?
  end

  def check_date
    @check_date.blank? ? @batch.date.strftime("%m/%d/%Y") : @check_date.strftime("%m/%d/%Y")
  end

  def payer_name
    micr_line_information = check.micr_line_information
    if micr_line_information && micr_line_information.payer
      payer = micr_line_information.payer
    else
      payer = check.payer
    end
    payer.blank? ? '' : payer.payer.strip[0...60].strip
  end

  def elbm_code
    lockbox_batch_num_sequence = @batch_lockbox + @bank_batch_number + @check_transaction_id
    'ELBM' + ' ' + lockbox_batch_num_sequence + ' ' + @check_number_formatted
  end

  def translated_facility_check_date
    check_date_formatted = @check_date.blank? ? @batch.date.strftime("%Y%m%d") : @check_date.strftime("%Y%m%d")
    translation = @original_facility.translation unless @original_facility.blank?
    facility_traslation = translation.blank? ? '' : translation
    facility_traslation + check_date_formatted
  end
  
end
