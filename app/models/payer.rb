
# == Schema Information
# Schema version: 69
#
# Table name: payers
#
#  id                :integer(11)   not null, primary key
#  date_added        :date          
#  initials          :string(255)   
#  from              :string(255)   
#  gateway           :string(255)   
#  payid             :string(255)   
#  payer             :string(255)   
#  gr_name           :string(255)   
#  pay_address_one   :text          
#  pay_address_two   :text          
#  pay_address_three :text         
#  phone             :string(255)   

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
require File.join(Rails.root, 'lib', 'OCR_Data.rb')
require 'utils/rr_logger'
include OCR_Data
class Payer < ActiveRecord::Base
  include DcGrid
  include OutputPayer
  
  attr_accessor :style,:coordinates, :page
  validates_presence_of :payer
  validates :payid, :presence => true



  has_many :era_checks
  has_many :check_informations
  has_many :facilities_payers_informations
  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details" 
  has_details  :payid,
    :payer,
    :pay_address_one,
    :pay_address_two,
    :payer_city,
    :payer_state,
    :payer_zip
  has_many :micr_line_informations
  has_many :payer_exclusions
  has_many :facilities ,:through => :payer_exclusions
  has_many :reason_codes, :through => :reason_code_set_name
  has_many :facility_plan_types
  belongs_to :reason_code_set_name
  after_save :create_reason_code_set_name
  alias_attribute :name, :payer
  alias_attribute :address_one, :pay_address_one
  alias_attribute :address_two, :pay_address_two
  alias_attribute :city, :payer_city
  alias_attribute :state, :payer_state
  alias_attribute :zip_code, :payer_zip
  validate :validate_payid
  NEW = "NEW"
  CLASSIFIED = "CLASSIFIED"
  CLASSIFIED_BY_DEFAULT = "CLASSIFIED_BY_DEFAULT"
  APPROVED = "APPROVED"
  PATPAY = "PatPay"
  COMMERCIAL = "Commercial"
  MAPPED = "MAPPED"
  UNMAPPED = "UNMAPPED"

  after_update :create_qa_edit, :record_changed_values
  
  before_save do |obj|
    obj.upcase_grid_data(['details','payer_type'])
  end
  
  def create_qa_edit
    QaEdit.create_records(self)
  end

  def record_changed_values
    JobActivityLog.record_changed_values(self)
  end

  scope :none, where('1 = 0')
  
  scope :approved_payers_begins_with_name_or_address, lambda {|name, address_one|
    values = {}
    conditions = "(status = 'APPROVED' OR status = 'MAPPED' OR status = 'UNMAPPED') \
          AND gr_name is null"
    if name.present?
      conditions += " AND LOWER(payer) like :name "
      values[:name] = "%#{name.downcase}%"
    end
    if address_one.present?
      conditions += " AND LOWER(pay_address_one) like :address_one "
      values[:address_one] = "%#{address_one}%"
    end
    
    where(conditions, values).limit(10)
  }

  scope :exclude_payids, lambda {|payids|
    {:conditions => ["payid not in (?)", payids]}}
  
  #a named scope for Comercial payers only
  scope :commercial_payers, :conditions => ["gr_name is null and gateway = 'client' and payer_type = 'commercial'"] do
    def match_commpayer_name(name)
      find(:all, :conditions => ['LOWER(payer) LIKE ? ', "%#{name.downcase}%" ])
    end
  end

  def create_reason_code_set_name
    if self.reason_code_set_name.blank?
      self.reason_code_set_name = ReasonCodeSetName.find_or_create_by_name("DEFAULT_#{self.id}")
      self.save
    end
  end

  def self.payer_id(payer,payeradressone,payeraddresstwo)
    payer_id = Payer.find(:first,:conditions => "payer = '#{payer}' and pay_address_one ='#{payeradressone}' and pay_address_two='#{payeraddresstwo}'").id
    return payer_id
  end
  
  def self.count_by_status(status)
    Payer.count(:all, :conditions=>["status=?",status])
  end

  def excluded_facilities
    Facility.find(payer_exclusions.find_all_by_status('EXCLUDED').collect(&:facility_id))
  end

  #finds job with minimum estimated_eobs for the payer and returns expected time for job's batch
  def least_time
    payer = self
    job = Job.find(:first, 
      :conditions => "jobs.payer_id = #{payer.id} and batches.status != '#{BatchStatus::COMPLETED}'",
      :include => :batch,
      :order => "batches.arrival_time, jobs.estimated_eob")
    unless job.nil?
      return job
    else
      return nil
    end
  end
    
  def commercial?
    if self.payer_type.strip.upcase=='COMMERCIAL'
      return true
    else
      return false
    end
  end

  #TODO: Remove this method
  def least_times(pgid)
    payer = self
    job = Job.find(:first,
      :conditions => "jobs.payer_id= #{payer.id} and batches.status != '#{BatchStatus::COMPLETED}' where payer.payer_group_id=#{pgid}",
      :include => :batch,
      :order => "batches.arrival_time, jobs.estimated_eob")
    unless job.nil?
      return job
    else
      return nil
    end
  end
  
  def popup
    "#{payer.to_s} + #{pay_address_one} + #{pay_address_two} + #{id}"
  end
  
  def self.payer_details(payer, client, facility)
    payer_details = {}
    payer_info = payer.split('+')
    payer_id = payer_info[3].to_i
    
    if(!payer_id.blank?)
      payer = Payer.find(payer_id)
      payer_details["payer_id"] =  payer_info[3]
      payer_details["payer_address_one"] = payer.pay_address_one
      payer_details["payer_address_two"] = payer.pay_address_two
      payer_details["payer_city"] = payer.payer_city
      payer_details["payer_city"] = payer.payer_city
      payer_details["payer_state"] = payer.payer_state
      payer_details["payer_zip"] = payer.payer_zip
      payer_details["payer_tin"] = payer.payer_tin
      plan_type_config = facility.plan_type.to_s.upcase
      if plan_type_config == 'PAYER SPECIFIC ONLY'
        plan_type = payer.normalized_plan_type(client.id, facility.id, facility.details[:default_plan_type])
        payer_details["plan_type"] = plan_type if !plan_type.blank?
      end
      payer_details["payer_type"] = payer.payer_type
      payer_details["status"] = payer.status
      payer_details["payid"] = payer.payid
      payer_details["reason_code_set_name_id"] = payer.reason_code_set_name_id

      return payer_details.to_json
    else
      return "Newpayer"
    end
  end
  
  #This will return the stle for an OCR data, depending on its origin
  #4 types of origins are :
  #0 = imported from 837
  #1= read by OCR with 100% confidence (questionables_count =0)
  #2= read by OCR with < 100% confidence (questionables_count >0)
  #3= blank data
  #param 'column'  is the name of the database column of which you want to get the style
  def style(column)
    method_to_call = "#{column}_data_origin"
    begin
      case self.details[method_to_call.to_sym]
      when OCR_Data::Origins::IMPORTED
        "ocr_data imported"
      when OCR_Data::Origins::CERTAIN
        "ocr_data certain"
      when OCR_Data::Origins::UNCERTAIN
        "ocr_data uncertain"
      when OCR_Data::Origins::BLANK
        "ocr_data blank"
      else
        "ocr_data blank"
      end
    rescue NoMethodError
      # Nothing matched, assign default
      OCR_Data::Origins::BLANK
    end
  end
 
  #This will return the coordinates for an OCR'd field
  #OCR  engine returns the coordinates in terms of
  # top, bottom, left and right, in that order
  def coordinates(column)
    method_to_call = "#{column}_coordinates"
    begin
      coordinates = self.details[method_to_call.to_sym]
      coordinates_appended = ""
      coordinates.each do |coordinate|
        coordinates_appended += "#{coordinate} ,"
      end
      coordinates_appended
    rescue NoMethodError
      # Nothing matched, send nil object so that the attribute in the view it will be dropped
      nil
    end
  end
 
  #This will return the page number on the image of an OCR'd field
  def page(column)
    method_to_call = "#{column}_page"
    begin
      self.details[method_to_call.to_sym]
    rescue NoMethodError
      # Nothing matched, send nil object so that the attribute in the view it will be dropped
      nil
    end
  end
  
  # Calculating processor_input_field_count in payer level
  # by checking constant fields in grid as well as configured fields populated through FCUI.
  def processor_input_field_count
    constant_fields = [payer_type, payer, pay_address_one, pay_address_two,
      payer_city, payer_state, payer_zip]
    fc_ui_fields = [payer_tin]
    total_field_array = constant_fields.concat(fc_ui_fields)
    total_field_array_with_data = total_field_array.select{|field| !field.blank?}
    total_field_count_with_data = total_field_array_with_data.length
    total_field_count_with_data
  end

  # Log for Payer Mapping
  def payer_log
    RevRemitLogger.new_logger(LogLocation::PYRLOG)
  end

  # The method that starts the classification process of payer to a footnote or not.
  # Initiate the classification for the when the required conditions are met and
  # obtains the configuration parameters.
  # Input :
  # facility : facility for which the checks belong to. Classification depends upon FC.
  # check : Payer's check.
  # Output :
  # send out a 'classify' process as a background job using DJ.
  def commence_classification(is_partner_bac, facility)
    if footnote_indicator.blank? && status.to_s.upcase == 'NEW'
      if is_partner_bac
        configs = {}
        configs[:min_reason_codes] = facility.details[:min_reason_codes] || 10
        configs[:min_percentage_of_reason_codes] = facility.details[:min_percentage_of_reason_codes] || 70
        configs[:min_number_of_eobs] = facility.details[:min_number_of_eobs] || 3
        configs[:threshold_time_to_tat] = facility.details[:threshold_time_to_tat] || 3
        self.delay(:queue => 'payer_classification').classify(configs)
      else
        self.footnote_indicator = false
        self.status = 'CLASSIFIED_BY_DEFAULT'
        if self.valid?
          self.save
          self.reload
        end
        self
      end
    end
  end

  # This method classify the payer to a footnote or not and is saved to the payer object.
  # The status of the payer depends upon the classification.
  # If classification is possible by the given input, then status is 'CLASSIFIED'.
  # Else, the classification is done by default, then status is 'CLASSIFIED_BY_DEFAULT'.
  # Input :
  # configs : configuration parameters in FC.
  # Output :
  # classified or unclassified payer object.
  def classify configs
    footnote_indicator = nil
    payer_log.debug "----------------------------------------------------------"
    payer_log.debug "Starting Payer Classification at #{Time.now} for the payer ID : #{id}, name : #{name}"
    footnote_indicator, payer_status = run_min_eob_condition_and_classify(configs)
    payer_log.debug "----------------------------------------------------------"
    self.footnote_indicator = footnote_indicator
    self.status = payer_status || status
    self.save!
    self
  end

  # This method verifies if the EOB condition is met to classify.
  # Input :
  # configs : configuration parameters in FC.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  # If classification is possible by the given input, then status is 'CLASSIFIED'.
  # Else, the classification is done by default, then status is 'CLASSIFIED_BY_DEFAULT'.
  def run_min_eob_condition_and_classify(configs)
    eobs_for_the_payer = InsurancePaymentEob.count(:all,
      :include => [{:check_information => :payer}], :conditions => ["payers.id = ?", id])
    payer_log.debug "There are #{eobs_for_the_payer} number of EOBs having the payer in process."
    if eobs_for_the_payer >= configs[:min_number_of_eobs].to_i
      payer_log.debug "Minimun EOBs are met to continue the classification."
      footnote_indicator, payer_status = run_min_reason_code_condition_and_classify(configs)
    else
      payer_log.debug "Minimun EOBs are not met to continue the classification."
      footnote_indicator, payer_status = force_classifiy configs
    end
    return footnote_indicator, payer_status
  end
  
  # This method verifies if the reason code condition is met to classify.
  # Input :
  # configs : configuration parameters in FC.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  def run_min_reason_code_condition_and_classify(configs)
    distinct_reason_code_ids = reason_codes.map(&:id).compact.uniq
    if distinct_reason_code_ids.length >= configs[:min_reason_codes].to_i
      payer_log.debug "Minimum reason codes are met to continue the classification."
      footnote_indicator, payer_status = run_threshold_condition_and_classify(configs,
        distinct_reason_code_ids)
    else
      payer_log.debug "Minimum reason codes are not met to continue the classification."
      footnote_indicator, payer_status = force_classifiy configs
    end
    return footnote_indicator, payer_status
  end

  # This method verifies if the threshold condition is met to classify.
  # Input :
  # configs : configuration parameters in FC.
  # distinct_reason_code_ids : Distinct reason codes IDs for the payer.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  def run_threshold_condition_and_classify(configs , distinct_reason_code_ids)
    reason_codes = ReasonCode.find(distinct_reason_code_ids).map(&:reason_code)
    count_of_reason_codes = ReasonCode.count_of_reason_codes_with_one_description(reason_codes)
    payer_log.debug "The are #{count_of_reason_codes} reason codes with one description."
    footnote_indicator = !(count_of_reason_codes / distinct_reason_code_ids.length >=
        configs[:min_percentage_of_reason_codes].to_i / 100)
    if footnote_indicator
      payer_log.debug "The payer : #{name},with ID : #{id} is a footnote payer."
    else
      payer_log.debug "The payer : #{name},with ID : #{id} is a non-footnote payer."
    end
    payer_status = 'CLASSIFIED'
    return footnote_indicator, payer_status
  end

  # This method force fully classify the payer by default if
  #  the input values for classification are not met.
  # The classification is done by default, then status is 'CLASSIFIED_BY_DEFAULT'
  # Input :
  # configs : configuration parameters in FC.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  def force_classifiy(configs)
    payer_log.debug "System is forced to make a classification."
    footnote_indicator, payer_status = force_classify_for_urgent_batches(configs[:threshold_time_to_tat])
    return footnote_indicator, payer_status
  end

  # This method force fully classify for urgent batches waiting for output, if any.
  # Input :
  # threshold_time_to_tat : configuration parameter in FC for the threshold time in hours before TAT.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  def force_classify_for_urgent_batches(threshold_time_to_tat)
    urgent_batches = Batch.count_of_urgent_batches_for_payer(id,
      threshold_time_to_tat)
    if urgent_batches > 0
      payer_log.debug "There are urgent batches with payer same as the payer in process. "
      footnote_indicator, payer_status = default_classification
    else
      footnote_indicator, payer_status = force_classify_if_no_more_checks_to_process
    end
    return footnote_indicator, payer_status
  end

  # This method force fully classify if no more checks are available to process.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  def force_classify_if_no_more_checks_to_process
    count_of_checks_with_payer = CheckInformation.count_of_unfinished_checks_for_payer(id)
    unless count_of_checks_with_payer > 0
      payer_log.debug "There are no unprocessed checks having the payer same as the payer in process."
      footnote_indicator, payer_status = default_classification
    else
      payer_log.debug "There are unprocessed checks having the payer same as the payer in process. So payer is not classified."
    end
    return footnote_indicator, payer_status
  end

  # Classify the payer by default.
  # Output :
  # footnote_indicator : Indicates whether the payer is footnote or not.
  # payer_status : status of the payer after classification process.
  def default_classification
    payer_log.debug "System is forced to make a classification for #{name} with ID #{id} as non-footnote."
    footnote_indicator = false
    payer_status = 'CLASSIFIED_BY_DEFAULT'
    return footnote_indicator, payer_status
  end

  # Predicate method for a payer which is accepted or not.
  def accepted?   
    ["MAPPED","UNMAPPED","APPROVED"].include?(status.to_s.upcase)
  end

  def save_patient_payer_status_and_indicator(check_information, pat_pay_eob)
    unless self.blank?
      if payer_type.to_s.upcase == 'PATPAY'
        self.footnote_indicator = false
        if status.to_s.upcase == 'NEW' && !check_information.blank?
          patient_name = pat_pay_eob.patient_name unless pat_pay_eob.blank?
          if patient_name != name.to_s.upcase
            self.status = 'CLASSIFIED'
          else
            self.status = 'MAPPED' # Such payers do not go through approval
          end
        end
        self.save
      end
    end
    self
  end

  def excluded?(facility)
    result = false
    payer_exclusions.each do |pe|
      result ||= (pe.facility_id == facility.id)
    end
    result
  end

  
  #This for getting payid of payer.
  def get_payid(payer_type, facility_payids)
    if payer_type == 'Commercial'
      facility_payids[:commercial_payid]
    elsif payer_type == 'PatPay'
      facility_payids[:patient_payid]
    end
  end

  def get_status_and_footnote_indicator(is_correspondence_check, is_partner_bac)
    if !is_correspondence_check
      status = 'NEW'
      footnote_indicator = nil
    elsif is_correspondence_check
      if is_partner_bac
        status = 'MAPPED' # BAC COR checks' payers do not go through approval
        footnote_indicator = false
      else
        status = 'NEW'
        footnote_indicator = nil
      end
    end
    return status, footnote_indicator
  end
  
  def self.get_payer_object(payer_demographics)
    payer_object = Payer.find_by_payer_and_pay_address_one_and_pay_address_two_and_payer_city_and_payer_state_and_payer_zip(
      payer_demographics[:name],
      payer_demographics[:address_one],
      payer_demographics[:address_two],
      payer_demographics[:city],
      payer_demographics[:state],
      payer_demographics[:zip])
    payer_object
  end

  # Returns the payid based on the status of the payer.
  # Input :
  # micr_line_information : micr data of the check
  # Output :
  # Capitalized payid of the payer
  def payer_identifier(micr_line_information)
    payerid = nil
    if status.to_s.upcase == 'MAPPED'
      payerid = payid
    else
      unless micr_line_information.blank?
        payerid = micr_line_information.payid_temp
      end      
    end
    payerid.to_s.upcase
  end

  # Return the PayerAddressDTO for the payer
  def payer_address_dto
    dto = PayerMappingService::PayerAddressDTO.new
    dto.streetAddressLine1 = address_one
    dto.streetAddressLine2 = address_two
    dto.streetAddressLine3 = pay_address_three
    dto.cityNm = city
    dto.stateCode = state
    dto.zipCode = zip_code    
    dto.companyWebsite = website
    dto
  end

  # update payer from the mapping (PayerMappingService::PayerMappingEdcDto) and rcsn (ReasonCodeSetName)
  def save_mapped_payer dto, rcsn
    self.payer = dto.payer_name
    new_footnote_indicator = dto.footnote_payer_indicator
    if !cleanup_reason_codes_before_reclassification(new_footnote_indicator).blank?
      self.footnote_indicator = new_footnote_indicator
    end
    self.gateway = dto.gateway
    self.gateway_temp = dto.original_gateway
    if !dto.payer_address_info.blank?
      self.pay_address_one = dto.payer_address_info.streetAddressLine1
      self.pay_address_two = dto.payer_address_info.streetAddressLine2
      self.pay_address_three = dto.payer_address_info.streetAddressLine3
      self.payer_city = dto.payer_address_info.cityNm
      self.payer_state = dto.payer_address_info.stateCode
      self.payer_zip = dto.payer_address_info.zipCode
    end
    self.website = dto.payer_address_info ? dto.payer_address_info.companyWebsite : ""
    self.reason_code_set_name = rcsn
    self.status = 'MAPPED'
    self.payer_type = id
    is_payer_saved = self.valid? ? self.save : false
    if not is_payer_saved
      logger.debug "\n Save failed due to invalid Payer record "
      errors.each_full { |msg| logger.debug msg }
    else
      logger.debug "\n Payer successfully saved "
    end
    is_payer_saved
  end

  def switch_associations_and_destroy(old_payer, micr)
    result = false
    if old_payer && old_payer.id != self.id
      error_popups_saved = true
      checks_saved = CheckInformation.update_payer_of_check_information micr
      old_payer.error_popups.each do |err|
        err.payer = self        
        is_saved = err.save
        error_popups_saved &&= is_saved
      end
      logger.debug "error_popups saved : #{error_popups_saved}"
      if error_popups_saved && checks_saved
        old_payer.reload
        unless old_payer.micr_line_informations.length > 0 || old_payer.status == 'MAPPED'
          old_payer.destroy
          logger.debug "old_payer.destroyed? : #{old_payer.destroyed?}"
          result = old_payer.destroyed?
        else
          result = true
        end        
      end
    else
      result = true
    end
    result
  end

  def supply_payid micr=nil
    normalized_payer_type = payer_type.to_s.upcase
    commercial_or_patpay = normalized_payer_type == 'COMMERCIAL' || normalized_payer_type == 'PATPAY'
    micr = micr_line_informations.first unless micr
    if !$IS_PARTNER_BAC || status.to_s.upcase == 'MAPPED' || commercial_or_patpay
      attributes["payid"]
    else
      micr ? micr.payid_temp : nil
    end
  end

  #This is for getting gateway of payer.
  def get_gateway
    $IS_PARTNER_BAC ? "HLSC" : "REVMED"
  end

  def check_payer_status(facility_payids)
    payer_status = status
    if ((payid != facility_payids[:commercial_payid] || payid != facility_payids[:patient_payid]) && footnote_indicator != nil)
      payer_status = "MAPPED" if payer_status.blank?
    end
    payer_status
  end

  # The reason codes can be entered as footnote or non-footnote from grid if the payer is new.
  # Only when the payers gets approved the footnote indicator is actually set and the cleanup should happen
  # This method should be called when we approve a payer without changing the footnote indicator.
  # When footnote indicator is changed then the clean up is called.
  # Input :
  # old_status : old status value
  # old_footnote_indicator : old footnote_indicator
  def clean_up_rcs_if_status_has_changed(old_status, old_footnote_indicator)
    logger.debug "clean_up_rcs_if_status_has_changed"
    if (old_footnote_indicator == footnote_indicator && reason_code_set_name_id)
      if !status.nil? && status != old_status
        reason_codes_without_default_codes = ReasonCode.find(:all, :conditions =>
            ["reason_code_set_name_id = #{reason_code_set_name_id} and unique_code NOT IN ('1','2','3','4','5')"])
        if footnote_indicator == false
          ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes_without_default_codes, 'reason_code')
        elsif footnote_indicator == true
          ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes_without_default_codes, 'reason_code_description' )
        end
        ReasonCode.remove_cyclic_replacement_references(reason_code_set_name_id)
      end
    end
  end

  # Cleans up the reason codes and makes them consistent with that of the payer's footnote indicator
  # non-footnote payer reclassified as footnote: soft deletes all but the first record sharing the same code
  # footnote payer reclassified as non-footnote: soft deletes all but the first record sharing the same description
  # Input:  The new footnote indicator that the payer needs to have
  # Output: True/ False indicating if all the clean up activities were successful
  def cleanup_reason_codes_before_reclassification(new_footnote_indicator)
    logger.debug "cleanup_reason_codes_before_reclassification"
    success = true
    if !footnote_indicator.nil? && footnote_indicator != new_footnote_indicator      
      logger.info "\n Cleaning up reason codes before reclassification"
      success = false
      footnote_to_nonfootnote = footnote_indicator && !new_footnote_indicator
      nonfootnote_to_footnote = !footnote_indicator && new_footnote_indicator
      
      if nonfootnote_to_footnote
        logger.info "\n nonfootnote to footnote reclassification"
        success ||= ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes, 'reason_code_description' )
      elsif footnote_to_nonfootnote
        logger.info "\n footnote to nonfootnote reclassification"
        success ||= ReasonCode.cleanup_duplicate_reason_codes_group_by(reason_codes, 'reason_code')
      end
      ReasonCode.remove_cyclic_replacement_references(reason_code_set_name_id)
      time = Time.now.to_s
      time.slice!(19 .. -1)
      success &&= reason_codes.update_all ["notify = 1, reason_codes.updated_at = '#{time}'"] if success
    end
    if success != false && !success.nil?
      true
    end
  end

  # Cleans up the reason codes and makes them consistent with that of the payer's footnote indicator
  # This is called during PE/PM when a temporary payer record gets replaced with the payer recieved from WS
  # At that time if the old set name (of temp payer) is different from that of the new set name (of payer from WS)
  # then RCs from old set are merged into new set and this method is called
  # It looks at footnote indicator of payer from WS and ensures there are no duplicate RCs created due to the merging
  # non-footnote payer: cleans up a group of RCs sharing the same code
  # footnote payer: cleans up a group of RCs sharing the same description
  # Clean up is done based on business rules
  # Input:  The new footnote indicator that the payer needs to have
  # Output: True/ False indicating if all the clean up activities were successful
  def cleanup_reason_codes_after_porting_to_new_set
    logger.info "cleaning up reason codes after porting to new set"
    success = true
    if !footnote_indicator.nil?
      success = false
      logger.info "footnote_indicator : #{footnote_indicator}"
      logger.info "reason_code_set_name_id : #{reason_code_set_name_id}"
      reason_codes_without_default_codes = ReasonCode.find(:all, :conditions =>
          ["reason_code_set_name_id = #{reason_code_set_name_id} and unique_code NOT IN ('1','2','3','4','5')"])
      default_reason_codes = ReasonCode.find(:all, :conditions =>
          ["reason_code_set_name_id = #{reason_code_set_name_id} and unique_code IN ('1','2','3','4','5')"])
      if !default_reason_codes.blank?
        cleanup_default_codes = ReasonCode.cleanup_duplicate_default_reason_codes(default_reason_codes)
      else
        cleanup_default_codes = true
      end
      if footnote_indicator
        success ||= ReasonCode.cleanup_duplicate_reason_codes_retain_mapped_or_accepted_or_first(reason_codes_without_default_codes, 'reason_code_description' )
      elsif !footnote_indicator
        success ||= ReasonCode.cleanup_duplicate_reason_codes_retain_mapped_or_accepted_or_first(reason_codes_without_default_codes, 'reason_code')
      end
      ReasonCode.remove_cyclic_replacement_references(reason_code_set_name_id)
      success = success && cleanup_default_codes
    end
    if success != false && !success.nil?
      true
    end
  end

  # This provides the default payer address configured in FC UI,
  #  if any of the address field is blank
  # Input :
  # facility : Facility object
  # Output : default_payer_address from FC UI
  def default_payer_address(facility, check)
    default_payer_address = nil
    are_all_address_fields_present = !address_one.blank? && !city.blank? && !state.blank? && !zip_code.blank?
    if not are_all_address_fields_present
      facility_details = facility.details if !facility.blank?
      if !facility_details.blank?
        default_payer_address = {
          :address_one => facility_details[:default_payer_address_one].to_s,
          :city => facility_details[:default_payer_city].to_s,
          :state => facility_details[:default_payer_state].to_s,
          :zip_code => facility_details[:default_payer_zip_code].to_s
        }
      end
    end
    if facility.client.group_code == 'CNS' && check.correspondence?
      default_payer_address = {:address_one => 'PO BOX 9999', :city =>  'ATLANTA',
        :state => 'GA', :zip_code => '12345' }
    end
    default_payer_address
  end

  def update_temp_payer_details(results)
    rcsn_new = ReasonCodeSetName.find_or_create_by_name(results["reasonCodeSetName"])
    reason_code_set_name.switch_rcs_to_new_set_and_destroy(rcsn_new, id)
    self.update_attributes({"gateway_temp" => results["originalGateway"],
        "reason_code_set_name" => rcsn_new,
        "status"=>"UNMAPPED"})
  end


  # Overriding 5 attributes of Payer model dynamically as we move these attributes
  # to  model FacilitiesPayersInformation.
  methods = ["in_patient_payment_code", "out_patient_payment_code", "in_patient_allowance_code","out_patient_allowance_code", "capitation_code"]
  methods.each do |method|
    define_method method do |*args|
      fac_payer_info = []
      unless args.empty?
        fac_payer_info = FacilitiesPayersInformation.where("payer_id = ? AND facility_id = ?", id, args[0].id)
      end
      fac_payer_info.empty? ? nil : fac_payer_info.first.send(method)
    end
  end

  #This is for setting payer type of payer
  def get_payer_type(payid)
    ((payer_type == 'PatPay') ? 'PatPay' : ((payid == "D9998") ? 'Commercial' : id))
  end

  def validate_payid
    if attributes["payid"].blank?
      errors.add(:base, "Payer ID cant't be blank!")
    end
  end

  def output_payid facility
    client = facility.client
    if client.name.upcase == "BARNABAS" && payer_type == "PatPay"
      "CO001"
    else
      output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(id, client.id, facility.id)
      (output_payid_record ? output_payid_record.output_payid : 'D9998')
    end
  end

  # Cleans up the reason codes and makes them consistent with that of the payer's set name and footnote indicator
  # The Set Name for a payer is getting changed, so the reasoncodes are to be imported from the old set name to new set name
  # And reason codes are cleaned up in consistent with the footnote indicator
  # Input :
  # new_set_name : new set name object for payer
  # saves the payer object after successful cleaning up of reason codes
  def clean_up_the_rcs_if_set_name_has_changed(new_set_name)
    logger.debug "clean_up_the_rcs_if_set_name_has_changed"
   
    success = true
    old_set_name = reason_code_set_name
    logger.debug " old_set_name : #{old_set_name.id if old_set_name}"
    logger.debug " new_set_name : #{new_set_name.id if new_set_name}"
    if !old_set_name.blank? && old_set_name != new_set_name
      success = old_set_name.switch_rcs_to_new_set_and_destroy(new_set_name, id)
      if success
        self.reason_code_set_name = new_set_name
        success = cleanup_reason_codes_after_porting_to_new_set
      end
    end
    success 
  end

  # Validates the payid
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def validate_payer_id(payer_id)
    result = true
    error_message = nil
    if payer_id.blank?
      result = false
      error_message = 'Payer ID cannot be blank.'
    end
    return result, error_message
  end

  # Validates whether the given payer is a duplication of an approved payer
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def validate_against_payer_duplication(payer_details, payer_id, micr_details)
    result = true
    error_message = nil
    payer_name = !payer_details[:payer].blank? ? payer_details[:payer].strip : nil
    payid = !payer_details[:payid].blank? ? payer_details[:payid].strip : nil
    address_one = !payer_details[:pay_address_one].blank? ? payer_details[:pay_address_one].strip : nil
    city = !payer_details[:payer_city].blank? ? payer_details[:payer_city].strip : nil
    state = !payer_details[:payer_state].blank? ? payer_details[:payer_state].strip : nil
    zip_code = !payer_details[:payer_zip].blank? ? payer_details[:payer_zip].strip : nil
    existing_payers = Payer.where(["payer = ? AND payid = ? AND pay_address_one = ? AND \
        payer_city = ? AND payer_state = ? AND payer_zip = ? AND \
        status in ('APPROVED', 'UNMAPPED', 'MAPPED')", payer_name, payid,
        address_one, city,
        state, zip_code])

    another_payer_with_same_details_exist = !existing_payers.blank? && (existing_payers.length > 1 ||
        (existing_payers.first && existing_payers.first.id != payer_id.to_i))
    if another_payer_with_same_details_exist
      if !payer_id.blank?
        if(existing_payers.length == 1 && existing_payers.first.id != payer_id.to_i)
          existing_payer = existing_payers.first
          existing_payer_id = existing_payer.id
        elsif(existing_payers.length > 1)
          existing_payers.each do |payer|
            if payer.id != payer_id.to_i
              existing_payer = payer
              existing_payer_id = existing_payer.id
              break
            end
          end
        end

        new_micr_is_matching_with_existing_payer = false
        unless existing_payer.blank?
          duplicate_payer_id = payer_id
          duplicate_payer = Payer.find(duplicate_payer_id)
          if !duplicate_payer_id.blank?
            if !micr_details.blank?
              micr_given_to_duplicate_payer_array = MicrLineInformation.where(
                :aba_routing_number => micr_details[:aba_routing_number],
                :payer_account_number => micr_details[:payer_account_number],
                :status => "#{MicrLineInformation::APPROVED}")
              micr_given_to_duplicate_payer = micr_given_to_duplicate_payer_array.first
            end

            if !micr_given_to_duplicate_payer.blank?
              actual_payer_of_micr = micr_given_to_duplicate_payer.payer
              if actual_payer_of_micr
                if actual_payer_of_micr.id != existing_payer_id
                  result = false
                  error_message = "Error the micr given is attached to a different payer !!"
                  return result, error_message if not result
                else
                  new_micr_is_matching_with_existing_payer = true
                end
              end

              if new_micr_is_matching_with_existing_payer
                CheckInformation.where(:payer_id => duplicate_payer_id, :micr_line_information_id => micr_given_to_duplicate_payer.id).
                  update_all(:payer_id => existing_payer_id, :updated_at => Time.now)
                MicrLineInformation.destroy_all(:payer_id => duplicate_payer_id)
              end
            end

            CheckInformation.where(:payer_id => duplicate_payer_id).
              update_all(:payer_id => existing_payer_id, :updated_at => Time.now)
            MicrLineInformation.where(:payer_id => duplicate_payer_id).
              update_all(:payer_id => existing_payer_id, :updated_at => Time.now)

            if !payer_details[:set_name].blank?
              duplicate_payer.cleanup_reason_codes_before_reclassification(payer_details[:footnote_indicator])
              set_name_obj = ReasonCodeSetName.find_by_name(payer_details[:set_name])
              if !set_name_obj.blank?
                duplicate_payer.reason_code_set_name.switch_rcs_to_new_set_and_destroy(set_name_obj, duplicate_payer.id)
                if duplicate_payer.reason_code_set_name.name != payer_details[:set_name]
                  existing_payer.cleanup_reason_codes_after_porting_to_new_set
                end
              end
            end
            duplicate_payer.switch_associations_and_destroy(duplicate_payer, micr_given_to_duplicate_payer)

            set_name = duplicate_payer.reason_code_set_name
            if set_name && set_name.name.start_with?('DEFAULT')
              set_name.destroy
            end
            duplicate_payer.destroy
            error_message = 'This payer was duplicate, hence was not created / updated.'
          end
        end 
      else
        result = false
        error_message = 'This payer was duplicate, hence was not created / updated.'
        return result, error_message if not result
      end
    end
    return result, error_message
  end

  # Validates whether the given micr record belongs to another payer
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def validate_unique_payer_for_micr(routing_number, account_number)
    error_message = nil
    result = true
    if !routing_number.blank? && !account_number.blank?
      micr_record = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(
        routing_number, account_number)
      if !micr_record.blank? && !micr_record.payer_id.blank?
        if micr_record.payer_id != id
          error_message = 'Another payer has this MICR. Please provide valid data.'
          result = false
        end
      end
    end
    return result, error_message
  end

  # Validates for the payer change event
  # Output :
  # result : result of validation or updation
  # error_message : cause for the error
  def validate_presence_of_eobs_when_payer_type_changes(new_payer_type)
    error_message = nil
    result = true
    if new_payer_type == 'Insurance'      
      normalized_new_payer_type = id if id
    else
      normalized_new_payer_type = new_payer_type
    end

    if payer_type == "#{Payer::PATPAY}"
      normalized_old_payer_type = payer_type
    else
      normalized_old_payer_type = id if id
    end
    if !id.blank? && !payer_type.blank? && normalized_old_payer_type.to_s != normalized_new_payer_type.to_s
      count_of_eobs_present_for_payer = InsurancePaymentEob.count(:id,
        :joins => "INNER JOIN check_informations AS checks \
            on checks.id = insurance_payment_eobs.check_information_id \
            INNER JOIN payers on payers.id = checks.payer_id",
        :conditions => ["payers.id = ?", id])
      if count_of_eobs_present_for_payer > 0
        error_message = 'Please delete the EOBs attached for this payer to change the payer type'
        result = false
      end
    end
    return result, error_message
  end

  # Provides the set name
  # Output :
  # set_name : reason code set name
  def get_set_name(new_payer_type, payid)
    if !$IS_PARTNER_BAC
      if new_payer_type != "#{Payer::PATPAY}"
        if ((attributes["payid"].blank? || !attributes["payid"].blank? ) && !payid.blank? && payid != attributes["payid"])
          set_name = payid
        end
      else
        if !id.blank?
          set_name = "DEFAULT_#{id}"
        else
          set_name = nil
        end
      end
    elsif !reason_code_set_name.blank?
      set_name = reason_code_set_name.name
    end
    if set_name.blank?
      set_name = reason_code_set_name.name unless reason_code_set_name.blank?
    end
    set_name
  end

  #TODO : Old 835 Output Code : Rule Violation
  def gcbs_output_payid facility
    client = facility.client
    output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(id, client.id, facility.id)
    (output_payid_record ? output_payid_record.output_payid : payid)
  end

  def output_payid_for_aggregate_report(facility_id, client_id)
    output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(id, client_id, facility_id)
    (output_payid_record ? output_payid_record.output_payid : "")
  end

  # Obtain the payer_group from payer_type
  def get_payer_group
    case payer_type
    when 'PatPay'
      'PatPay'
    else
      'Insurance'
    end
  end

  def normalized_plan_type(client_id, facility_id, default_plan_type)
    plan_type_record = FacilityPlanType.get_client_or_site_specific_plan_type(id, client_id, facility_id)
    plan_type = plan_type_record.plan_type if !plan_type_record.blank?
    
    plan_type = self.plan_type if plan_type.blank?
    plan_type = default_plan_type if plan_type.blank?  
    plan_type
  end

end

