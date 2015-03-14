require "nokogiri"
include Nokogiri

##################################################################################################################################
#   Description: This class is used for extracting the data from the OCR xmls
#   This class contains following methods.
#   * initialize: Class initializing method.
#   * start_element: Parses the starting tag
#   * end_element: Parses the ending tag
#   * The other methods are given the descriptions above each methods.
##################################################################################################################################

class OcrDataParser < XML::SAX::Document
  def initialize
    @obj = nil
    @attributes = []
    @data_identifier = true
    @current_parent_element = nil
    @remark_code_identifier = false
    @remark_codes = []
    @remark_codes_with_desc = []
    @config = YAML.load(File.read("#{Rails.root}/lib/ocr/ocr.yml"))
    @date_formats = YAML::load(File.open("#{Rails.root}/config/date_formats.yml"))
  end

  def start_element(element, attrs = [])
    perform_beginning_tasks(element, attrs)
    create_eob if element == "ClaimRecord"
    create_service_line if element == "ServiceLine" and !@remark_code_grid_identifier
    @data_identifier = false if element == "OriginalValue" or element == "ErrorValue"
  end

  def end_element(element)
    perform_ending_tasks(element)
  end

  def characters(string)
  end

  #This method performs the beginning tasks which includes identification of the payer,job,check data etc and setting up of a few flags
  #based on the conditions.
  def perform_beginning_tasks(element, attrs)
    if element == "Batch"
      meta_data_from_batch = Hash[*attrs.flatten(1)]
      @job = Job.find(meta_data_from_batch["DocID"])
      @batch = @job.batch
      @facility = @batch.facility
      @check_information = @job.check_informations.first
      micr_info = @check_information.micr_line_information
      @payer = micr_info.payer if micr_info
      if ["PROCESSING", "NEW", "COMPLETED", "INCOMPLETED"].include? @job.job_status
        RevremitMailer.notify_late_ocr_xml_arrival(@check_information.check_number, @batch.id, @batch.batchid).deliver
        abort("The job is already allocated for the processing...Details are mailed to #{$RR_REFERENCES['email']['late_ocr_xml_arrival']['notification']}")
      end
      @job.update_attributes(:is_ocr => true, :ocr_status => "OCR PROCESSING", :job_status => "OCR PROCESSING")
    end

    if element == "Grid"
      attr_top_element_hash = Hash[*attrs.flatten(1)]
      @remark_code_grid_identifier = attr_top_element_hash["Name"] == "REMARKS" ? true : false
    end

    if element == "RemarkCode" or element == "RemarkCodeDescription"
      @remark_code_identifier = true
    end

    if @remark_code_identifier
      if element == "DataValue"
        @data_value_identifier = true
      end
      if element == "TEXTSTRING" and @data_value_identifier and @remark_code_grid_identifier
        attr_hash = Hash[*attrs.flatten(1)]
        @remark_codes_with_desc << attr_hash["WORD"]
      elsif element == "TEXTSTRING" and @data_value_identifier
        attr_hash = Hash[*attrs.flatten(1)]
        unless attr_hash["WORD"].blank?
          @remark_codes << attr_hash["WORD"] unless @remark_codes.include? attr_hash["WORD"]
        end
      end
    end
    construct_the_data_structures(element, attrs)
  end

  #This method construct the initial data structures..
  def construct_the_data_structures(element, attrs)
    if @config.include? element
      @data_identifier = true
      @current_parent_element = @config[element]
      @attributes << [attrs]
    end

    if @data_identifier
      if @current_parent_element
        if @current_parent_element.include? element
          @attributes  << [@current_parent_element[element], attrs]
        end
      end
    end
  end

  #This method performs the ending tasks which includes re-setting of a few flags and processing of the reason codes
  def perform_ending_tasks(element)
    if @config.include? element
      process_data(@attributes)
      @current_parent_element = []
      @attributes = []
    end
    if element == "DataValue"
      @data_value_identifier = false
    end
    if element == "RemarkCode"
      @remark_code_identifier = false
    end
    if @remark_code_grid_identifier and element == "Grid"
      process_remark_codes
    end
    if element == "Batch"
      @job.update_attributes(:ocr_status => "SUCCESS", :job_status => "NEW")
    end
    if element == "ClaimRecord"
      JobActivityLog.create_activity({:job_id => @job.id, :eob_id => @insurance_payment_eob.id, :activity => 'MPI Search Started', :start_time => Time.now, :eob_type_id => 1})
      facility_id = @facility.id  if @facility.mpi_search_type.eql?("FACILITY")
      facility_group = @facility.details[:facility_ids]
      client_id = @facility.client.id  if @facility.mpi_search_type.eql?("CLIENT")
      account_number = ClaimInformation.replace_patient_account_number_prefix(@facility.sitecode, @insurance_payment_eob.patient_account_number)
      @insurance_payment_eob.update_attribute(:patient_account_number, account_number)
      patient_last_name = @insurance_payment_eob.patient_last_name
      patient_first_name = @insurance_payment_eob.patient_first_name
      #date_of_service_from = @insurance_payment_eob.service_payment_eobs.first.date_of_service_from
      insured_id = @insurance_payment_eob.subscriber_identification_code
      total_charges = @insurance_payment_eob.total_submitted_charge_for_claim
      @mpi_results = ClaimInformation.mpi_search_for_sphinx(facility_id, client_id, account_number, patient_last_name, patient_first_name, nil, insured_id, total_charges, nil ,nil,nil,nil,nil,facility_group,nil)
      associate = false
      unless @mpi_results.empty?
        JobActivityLog.create_activity({:job_id => @job.id, :eob_id => @insurance_payment_eob.id, :activity => 'MPI Match Found', :start_time => Time.now, :eob_type_id => 1})
        associate = ClaimInformation.compare_and_associate_claim_and_eob(@mpi_results.first.id, @insurance_payment_eob.id)
      end
      if associate
        JobActivityLog.create_activity({:job_id => @job.id, :eob_id => @insurance_payment_eob.id, :activity => 'MPI Match Used', :start_time => Time.now, :eob_type_id => 1})
        MpiStatisticsReport.create_mpi_stat_report({:batch_id => @batch.id, :mpi_status => 'Success', :start_time => Time.now, :eob_id => @insurance_payment_eob.id })
      else
        JobActivityLog.create_activity({:job_id => @job.id, :eob_id => @insurance_payment_eob.id, :activity => 'MPI Failed', :start_time => Time.now, :eob_type_id => 1})
        MpiStatisticsReport.create_mpi_stat_report({:batch_id => @batch.id, :mpi_status => 'Failure', :start_time => Time.now, :eob_id => @insurance_payment_eob.id })
      end
    end
  end

  #This method processes the data and creates the data and meta data hashes.
  def process_data(attributes)
    meta_data_from_parent = Hash[*attributes.first]
    attributes.shift
    attributes.each do |element_array|
      column_name_and_obj_id = element_array.first.split(",")
      column_name = column_name_and_obj_id.first
      obj_id = column_name_and_obj_id.last.strip
      element_array.shift
      meta_data_hash = Hash[*element_array.first.flatten(1)]
      obj = identify_the_object(obj_id)
      insert_meta_data([meta_data_hash["LEFT"].to_f, meta_data_hash["TOP"].to_f, meta_data_hash["BOTTOM"].to_f, meta_data_hash["RIGHT"].to_f], meta_data_from_parent["Page"], column_name, meta_data_hash["WORD"], meta_data_from_parent["Valid"], obj, meta_data_from_parent["Score"])
    end
  end
  
  #This method identifies the object into which the data needs to be inserted based on the configs set in the yml file.
  def identify_the_object(obj_id)
    if obj_id == "1"
      @check_information
    elsif obj_id == "2"
      @insurance_payment_eob
    elsif obj_id == "3"
      @service_line
    end
  end

  def process_remark_codes
    if !@payer.blank?
      unless @remark_codes_with_desc.blank?
        @remark_codes_with_desc.pop if @remark_codes_with_desc.length.odd?
        remark_codes_with_desc_hash = Hash[*@remark_codes_with_desc.flatten(1)]
        remark_codes_with_desc_hash.each do |code, desc|
          @reason_code = ReasonCode.get_reason_code(code, desc, @payer.reason_code_set_name)
          create_reason_codes_and_descriptions(code, desc)
        end
      else
        @remark_codes.each do |code|
          @reason_code = ReasonCode.find_by_reason_code_and_reason_code_set_name_id(code, @payer.reason_code_set_name)
          create_reason_codes_and_descriptions(code, "reason code name")
        end
      end
    end
  end
  
  #This method creates the reason codes and descriptions and reason codes jobs for showing in the reason code grid based on the
  #given conditions..
  def create_reason_codes_and_descriptions(code, desc)
    if @reason_code.blank?
      @reason_code = ReasonCode.new(:reason_code => code, :reason_code_description => desc, :reason_code_set_name_id => @payer.reason_code_set_name_id, :status => "NEW")
      @reason_code.save(:validate => false)
    end
    reason_code_id = @reason_code.id
    @reason_code_job = ReasonCodesJob.find(:first,:conditions => "reason_code_id = #{reason_code_id} and parent_job_id = #{@job.id}")
    if @reason_code_job.blank?
      @reason_code_job = ReasonCodesJob.new()
      @reason_code_job.reason_code_id = reason_code_id
      @reason_code_job.parent_job_id = @job.id
      @reason_code_job.save
    end
  end

  #This method creates the eobs based on the triggers set.
  def create_eob
    @insurance_payment_eob = InsurancePaymentEob.new(:details=>{:patient_first_name_ocr_output=>""})
    @check_information.insurance_payment_eobs << @insurance_payment_eob
    @insurance_payment_eob.save(:validate => false)
    return @insurance_payment_eob
  end

  #This method creates the service lines based on the triggers set.
  def create_service_line
    @service_line = ServicePaymentEob.new(:details=>{:date_of_service_from_ocr_output=>""})
    @insurance_payment_eob.service_payment_eobs << @service_line
    @service_line.save(:validate => false)
    return @service_line
  end
  
  #This method stores the ocr data including the meta data into the system. some special conditions are also coded in this.
  def insert_meta_data(zone_value, page, field_name, field_value, account_state, record_pointer, confidence)
    if field_name == "date_of_service_from"
      svc_from_date, svc_to_date = standardize_svc_dates field_value rescue nil
      record_pointer.update_attributes(:date_of_service_from => svc_from_date, :date_of_service_to => svc_to_date)
    elsif field_name == "check_date" or field_name == "date_of_service_to"
      date = datify field_value rescue nil
      record_pointer.update_attribute("#{field_name}","#{date}")
    else
      record_pointer.update_attribute("#{field_name}","#{field_value}") unless field_value == "0.00" or field_value == "0.0"
    end
    if field_name == "patient_account_number"
      record_pointer.image_page_no = page
      record_pointer.sub_job_id = @job.id
    end
    unless field_value == "0.00" or field_value == "0.0"
      field_ocr_output=field_name +"_ocr_output"
      field_data_origin=field_name +"_data_origin"
      field_number_page=field_name +"_page"
      field_number_coordinates=field_name +"_coordinates"
      field_number_state = field_name +"_ocr_state"
      field_number_confidence = field_name +"_confidence"
      record_pointer.details[field_ocr_output.to_sym] = field_value if field_value
      confidence_value =  find_the_data_origin_of(account_state.to_s, confidence)
      record_pointer.details[field_data_origin.to_sym] = confidence_value
      record_pointer.details[field_number_page.to_sym] = page
      record_pointer.details[field_number_coordinates.to_sym] = zone_value
      record_pointer.details[field_number_state.to_sym] = account_state.to_s
      record_pointer.details[field_number_confidence.to_sym] = confidence.to_i
    end
    record_pointer.save(:validate => false)
  end

  def datify date_value
    available_date_formats = @date_formats["us_date_formats"].values
    available_date_formats.each do |format|
      if Date._strptime(date_value, format)
        date = Date.strptime(date_value, format)
      end
      return date if date
    end
  end

  def standardize_svc_dates field_value
    dates = field_value.split("-")
    if dates.length == 1
      svc_from_date = datify dates[0].strip
      svc_to_date = svc_from_date
    else
      svc_from_date = datify dates[0].strip
      svc_to_date = datify dates[1].strip
    end
    return svc_from_date, svc_to_date
  end
  
  #This is a place holder method. This method currently returns '2' regardless of the conditions.
  #But will return 1,2,3 respectively once the scoring(confidence feature) is done by RMS OCR Generator.
  def find_the_data_origin_of(value, confidence)
    confidence_value = 79
    if (value == "True" and confidence.to_i > confidence_value)
      return 1
    elsif (value == "False" or (confidence.to_i < confidence_value))
      return 2
    elsif value == "Empty"
      return 2
    end
  end

end

