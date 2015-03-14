# == Schema Information
# Schema version: 69
#
# Table name: jobs
#
#  id                    :integer(11)   not null, primary key
#  batch_id              :integer(11)
#  check_number          :string(255)
#  tiff_number           :string(255)
#  count                 :integer(11)
#  processor_status      :string(255)
#  processor_id          :integer(11)
#  processor_flag_time   :datetime
#  processor_target_time :datetime
#  qa_flag_time          :datetime
#  qa_target_time        :datetime
#  qa_id                 :integer(11)
#  payer_id              :integer(11)
#  estimated_eob         :integer(11)
#  adjusted_eob          :integer(11)
#  image_count           :integer(11)
#  comment               :string(255)
#  job_status            :string(255)   default(New)
#  qa_status             :string(255)   default(New)
#  updated_by            :integer(11)
#  updated_at            :datetime
#  created_by            :integer(11)
#  created_at            :datetime
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.
require 'OCR_Data'
include OCR_Data
class Job < ActiveRecord::Base
  attr_accessor :style,:coordinates, :page, :guid_number
  belongs_to :batch
  belongs_to :payer
  has_many :eob_qas, :dependent => :destroy
  has_many :cms1500s
  has_many :check_informations, :dependent => :destroy
  #  belongs_to :images_for_jobs
  has_many :client_images_to_jobs, :dependent => :destroy
  has_many :images_for_jobs,:through=>:client_images_to_jobs, :dependent => :destroy
  
  belongs_to :processor, :class_name => "User", :foreign_key => :processor_id
  belongs_to :qa, :class_name => "User", :foreign_key => :qa_id
  belongs_to :sqa, :class_name => "User", :foreign_key => :sqa_id
  belongs_to :hlsc, :class_name => "User", :foreign_key => :hlsc_id
  has_many :cms1500s
  has_many :reason_codes_jobs, :foreign_key => 'parent_job_id', :dependent => :destroy
  has_many :reason_codes, :through => :reason_codes_jobs
  has_many :provider_adjustments
  has_many :completed_checks, :class_name => 'CheckInformation'
  has_many :incompleted_checks, :class_name => 'CheckInformation'
  has_one :report_check_information, :dependent => :destroy
  has_many :job_activity_logs
  has_many :completed_checks_without_exclusion, :class_name => 'CheckInformation'
  has_many :incompleted_checks_without_exclusion, :class_name => 'CheckInformation'
  has_many :checks_for_eob_report, :class_name => 'CheckInformation'

  has_many :temp_jobs

  #  has_many :client_images_to_sub_job, :class_name => 'ClientImagesToJob', :foreign_key => 'sub_job_id'
  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details" 
  has_details  :check_number,
    :envelope_sequence,
    :envelope_number,
    :transaction_number,
    :batch_item_sequence

  # fields specific to a client which is for printing in output purpose only is stored here
  serialize :client_specific_fields, Hash
  validates_inclusion_of :count, :in => 0..99999,  :message => "Count is not in the Range"
  validate :check_number_validate
  alias_attribute :original_job_id, :split_parent_job_id

  before_save :set_associated_entity_updated_at, :set_batch_associated_entity_updated_at
  before_validation :strip_whitespace

  def set_associated_entity_updated_at
    self.associated_entity_updated_at = Time.now + 4.second
  end

  def set_batch_associated_entity_updated_at
    if payer_group_changed?
      Batch.where(:id => batch_id).update_all(:associated_entity_updated_at => Time.now)
    end
  end

  def is_ocr?
    return self.is_ocr == "OCR"
  end

  def incomplete_count
    if self.is_ocr?
      return self.check_informations.map {|c| c.insurance_payment_eobs}.flatten.select {|eob| eob.processing_completed.nil?}.length
    else
      return read_attribute(:incomplete_count)
    end
  end
  
  
  def save_payer_group(mic)
    payer_group = "--"
    payer_group = mic.payer.payer_type if mic.payer
    if ((payer_group == "Commercial") or (payer_group.match(/(^\d+$)/)))
      payer_group = "Insurance"
    end
    Batch.where(:id => batch_id).update_all(:associated_entity_updated_at => Time.now)
    self.update_attributes(:payer_group => payer_group)
  end
   
  def processor_complete_shift
    if (self.processor_status != "#{ProcessorStatus::COMPLETED}" || self.processor_flag_time.nil?) then 
      return 'Undefined'
    end
    
    hours_minutes = self.processor_flag_time.strftime("%H:%M")
    
    case hours_minutes
    when "05:30" .. "13:29"
      return "Afternoon"
    when "13:30" .. "21:29"
      return "Evening"
    when "21:30" .. "23:59"
      return "Morning"
    when "00:00" .. "05:29"
      return "Morning"
    else
      return "Unknown"
    end
  end

  def self.payer_job_count
    find(:all, :conditions => "batch_id = batches.id and batches.status != '#{BatchStatus::COMPLETED}'",
      :joins => "LEFT JOIN batches on batch_id = batches.id",
      :group => "jobs.payer_id",
      :select => "sum(jobs.estimated_eob) eobs, count(*) count, jobs.payer_id payer_id")
  end
  
  # TODO: Move this into a more appropriate place
  def self.export_processor_productivity(start_date = Time.now.yesterday.to_date, end_date = Time.now.yesterday.to_date)
    time_from = start_date.to_time.midnight
    time_to = end_date.to_time.tomorrow - 1.second

    filter = Filter.new
    filter.less time_to.to_s(:db), 'jobs.processor_flag_time'
    filter.great time_from.to_s(:db), 'jobs.processor_flag_time'

    e = Excel::Workbook.new
    jobs_array = Array.new
    jobs = Job.find(:all, :include => [{:batch => :facility}, :payer, :processor], :conditions => filter.conditions)
    unless jobs.empty?
      jobs.each do |j|
        h = Hash.new
        h["Processor"] = j.processor.nil? ? "Unknown" : j.processor.userid
        h["Batch ID"] = j.batch.batchid
        h["Batch Date"] = j.batch.date
        h["Site Number"] = j.batch.facility.sitecode
        h["Facility Name"] = j.batch.facility.name
        h["Check Number"] = j.check_number
        h["EOBs"] = j.count
        h["Payer"] = "#{j.payer.payer}(#{j.payer.supply_payid})"
        h["Shift"] = j.processor_complete_shift
        h["Job Completion Time"] = j.processor_flag_time.strftime("%m/%d/%y %H:%M")
        jobs_array << h
      end
      e.addWorksheetFromArrayOfHashes("Productivity", jobs_array)
    
      timestamp =  "#{time_from.strftime("%Y%m%d")}_#{time_to.strftime("%Y%m%d")}"
      report_filename = "public/reports/processor_productivity_#{timestamp}.xls"

      File.open(report_filename, 'w') {|f| f.puts(e.build)}
    end
  end

  # creating sub jobs
  def self.create_splited_job(jobid, jobsplitrange, processor, qa, image_type, allocating_user_id)
    if processor != "--"
      processor_id = User.find_by_name(processor).id
    end
    
    if qa != "--"
      qa_id = User.find_by_name(qa).id
    end
    
    job_id =  jobid[0].to_i
    count = 1
    parent_job = Job.find(job_id)
    job_activity_records = []
    
    jobsplitrange.each do |job_range|
      child_job = Job.new
      image_range = job_range.split("-")
      child_job.pages_from = image_range[0]
      child_job.pages_to = image_range[1]
      child_job.parent_job_id = job_id
      child_job.initial_image_name = parent_job.initial_image_name
      if(!processor_id.blank?)
        child_job.processor_id = processor_id
        child_job.processor_flag_time = Time.now
        child_job.processor_status = ProcessorStatus::ALLOCATED
        child_job.job_status = JobStatus::PROCESSING
      end
      
      if !qa_id.blank?
        child_job.qa_id = qa_id
        child_job.qa_flag_time = Time.now
        child_job.qa_status = QaStatus::ALLOCATED
        child_job.job_status = JobStatus::PROCESSING
      end
      child_job.is_ocr = parent_job[:is_ocr]
      child_job.is_excluded = parent_job.is_excluded
      child_job.batch_id = parent_job.batch_id
      child_job.payer_group = parent_job.payer_group
      child_job.check_number = (parent_job.check_number + "_" + count.to_s)
      no_of_images = child_job.pages_to - child_job.pages_from + 1
      micr = parent_job.check_information.micr_line_information
      child_job.estimated_eob = child_job.estimated_no_of_eobs(no_of_images, micr, parent_job.check_number)
      child_job.save
      
      parent_job.estimated_eob = 0
      parent_job.save
      
      if image_type == 0
        no_of_images = (image_range[1].to_i - image_range[0].to_i) + 1
        client_images = ClientImagesToJob.find(:all,
          :conditions => ["job_id =?", job_id], :limit => no_of_images,
          :offset => image_range[0].to_i-1) 
        client_images.each do |client_image|
          client_image.sub_job_id  = child_job.id
          client_image.save
        end
      end
      if(parent_job.is_ocr == "OCR")
        check_id = CheckInformation.find_by_job_id("#{parent_job.id}").id
        InsurancePaymentEob.where("check_information_id = '#{check_id}' AND image_page_no >= '#{child_job.pages_from}' AND image_page_no <= '#{child_job.pages_to}'" ).update_all(:sub_job_id  => "#{child_job.id}", :updated_at => Time.now)
      end
      count += 1
      if processor_id.present?
        activity_hash = { :job_id => child_job.id, :allocated_user_id => allocating_user_id,
          :activity => 'Allocated Job', :start_time => Time.now, :processor_id => processor_id }
      elsif qa_id.present?
        activity_hash = { :job_id => child_job.id, :allocated_user_id => allocating_user_id,
          :activity => 'Allocated Job', :start_time => Time.now, :qa_id => qa_id }
      end
      job_activity_records << JobActivityLog.create_activity(activity_hash, false) if activity_hash.present?
    end
    JobActivityLog.import job_activity_records if job_activity_records.present?
    batch = parent_job.batch
    batch.expected_completion_time = batch.expected_time
    batch.save
    return true
  end

  def update_parent_job_status(parent_job_id)
    @sub_job_count = Job.count(:all, :conditions => "parent_job_id = #{parent_job_id}")
    @completed_sub_job_count = Job.count(:all, :conditions => "parent_job_id = #{parent_job_id} and job_status = '#{JobStatus::COMPLETED}'")
    @check_amount = CheckInformation.find_by_job_id(parent_job_id).check_amount
    @amount_sofar_entered = InsurancePaymentEob.find(:all,:conditions=>"check_information_id=#{parent_job_id}",:select=>"sum(total_amount_paid_for_claim) payment_amount",:group=>"check_information_id")
    @amount_sofar_entered.each do|total_amount|
      @total_entered_amount = total_amount.payment_amount.to_f
    end
    @balance = @check_amount.to_f - @total_entered_amount.to_f
    if((@sub_job_count == @completed_sub_job_count) and @balance == 0)
      @job = Job.find(parent_job_id)
      @job.update_status(JobStatus::COMPLETED, @current_user.roles.first.name)
      @job.save
      return true
    else
      return true
    end
  end
  
    
  def self.do_auto_split_job(job_id, job_split_count, image_type)
    i = 1
    image_setting_limit_first = 0
    incrimented_split_count = 1
    parent_job = Job.find(job_id[0])
    
    if image_type == 1
      all_job_image_count = parent_job.pages_to.to_i
    else
      all_job_image_count = ClientImagesToJob.count(:all,
        :conditions =>["job_id =?", job_id[0]])
    end
    
    newly_creating_job_count =  all_job_image_count / job_split_count.to_i
    remaining_count = all_job_image_count % job_split_count.to_i
    for job_count in (1..newly_creating_job_count)
      child_job = Job.new
      child_job.pages_from = incrimented_split_count
      incrimented_split_count = (incrimented_split_count + job_split_count.to_i )
      child_job.pages_to = incrimented_split_count - 1
      child_job.parent_job_id = job_id[0]
      child_job.batch_id = parent_job.batch_id
      child_job.payer_group = parent_job.payer_group
      child_job.is_ocr = parent_job[:is_ocr]
      child_job.is_excluded = parent_job.is_excluded
      child_job.check_number = (parent_job.check_number + "_" + i.to_s)
      no_of_images = child_job.pages_to - child_job.pages_from + 1
      micr = parent_job.check_information.micr_line_information
      child_job.initial_image_name = parent_job.initial_image_name
      child_job.estimated_eob = child_job.estimated_no_of_eobs(no_of_images, micr, parent_job.check_number)
      child_job.save
      
      parent_job.estimated_eob = 0
      parent_job.save
      
      client_images = ClientImagesToJob.find_by_sql("select * from client_images_to_jobs  where job_id=#{job_id[0]} limit #{image_setting_limit_first},#{image_setting_limit_first+job_split_count.to_i}")
      client_images.each do |client_image|
        client_image.sub_job_id  = child_job.id
        client_image.save
      end
      i += 1
      image_setting_limit_first = image_setting_limit_first + job_split_count.to_i
    end
    
    if(remaining_count > 0)
      remaining_job = Job.new
      remaining_job.pages_from = incrimented_split_count
      remaining_job.pages_to = all_job_image_count
      remaining_job.parent_job_id = job_id[0]
      remaining_job.batch_id = parent_job.batch_id
      remaining_job.check_number = (parent_job.check_number+"_"+i.to_s)
      remaining_job.initial_image_name = parent_job.initial_image_name
      no_of_images = remaining_job.pages_to - remaining_job.pages_from + 1
      micr = parent_job.check_information.micr_line_information
      remaining_job.estimated_eob = remaining_job.estimated_no_of_eobs(no_of_images, micr, parent_job.check_number)
      remaining_job.payer_group = parent_job.payer_group
      remaining_job.save
      
      parent_job.estimated_eob = 0
      parent_job.save
      
      client_images_new = ClientImagesToJob.find_by_sql("select * from client_images_to_jobs  where job_id =#{job_id[0]} limit #{incrimented_split_count - 1 },#{all_job_image_count-1}")
      client_images_new.each do |item|
        item.sub_job_id  = remaining_job.id
        item.save
      end
    end
    Batch.where(:id => parent_job.batch_id).update_all(:associated_entity_updated_at => Time.now)
    return true
  end

  # Provides the check details for a normal and a split job.
  def check_information
    if parent_job_id.blank?
      check_informations.first
    else
      (Job.find(parent_job_id)).check_informations.first
    end
  end

  def check_amount_old(job)
    parent_job_id = Job.find(job).parent_job_id
    if (parent_job_id.blank?)
      check_info = CheckInformation.find_by_job_id(job)
      @check_amount = check_info.check_amount if check_info
      if(@check_amount)
        return @check_amount
      else
        return 0
      end
    end
  end

  def check_amount(job)
    parent_job_id = self.parent_job_id
    if (parent_job_id.blank?)
      check_info = self.check_information
      @check_amount = check_info.check_amount if check_info
      return @check_amount.to_f
    end
  end

  # Gets the check number for the job from Check Information record
  def get_checknumber
    check_number = check_information.check_number if !check_information.blank?
    !check_number.blank? ? check_number : ""
  end

  def display_check_number 
    unless parent_job_id
      check_informations.present? ? check_informations.first.check_number : ""
    else
      check_number
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
 
  def payer_name
    if (self.parent_job_id)
      check_info = (Job.find(self.parent_job_id)).check_informations
    else
      check_info = self.check_informations
    end
    if check_info && check_info.first
      if !check_info.first.micr_line_information.blank? and !check_info.first.micr_line_information.payer.blank?
        payer = check_info.first.micr_line_information.payer.payer
      elsif !check_info.first.payer.blank?
        payer = check_info.first.payer.payer
      else
        payer = "UNKNOWN"
      end
    else
      payer = "UNKNOWN"
    end
  end
  
  def is_ocr
    begin
      check = check_information
      check_content = check.details unless check.blank?
      unless check_content.blank?
        is_ocr = (check_content.has_key?(:check_number_coordinates) &&
            check_content.has_key?(:check_number_confidence))
      end
      if is_ocr.blank?
        eobs = check.insurance_payment_eobs
        is_ocr = eobs.first.details.has_key?(:patient_account_number_coordinates)
      end
      is_ocr.blank? ? "NON OCR" : "OCR"      
    end
  rescue
    "NON OCR"
  end

  def ocr_comment(check_details_column, eob_details_column)
    begin      
      unless check_details_column.blank?
        is_ocr = (check_details_column.has_key?(:check_number_coordinates) &&
            check_details_column.has_key?(:check_number_confidence))
      end
      if is_ocr.blank?
        eob_details_column.has_key?(:patient_account_number_coordinates)
      end
      is_ocr.blank? ? "NON OCR" : "OCR"
    end
  rescue
    "NON OCR"
  end

  # Calculates the estimated no of EOBs in a job
  # Input :
  # total_number_of_images : pages_to column of the jobs
  # micr : micr_line_information object
  # check_number : check number of the check
  #
  # Output :
  # estimated no of EOBs in a job
  def estimated_no_of_eobs(total_number_of_images, micr, check_number)
    total_number_of_images = total_number_of_images.to_f
    normalized_check_number = check_number.to_s.gsub(/^[0]+/, '')
    if normalized_check_number.length == 4 || total_number_of_images.to_f.zero?
      estimated_eob = 1
    else
      if !micr.blank?
        payer = micr.payer
        eobs_per_image = payer.eobs_per_image.to_f if !payer.blank?
      end
      if job_status.to_s.upcase == JobStatus::EXCLUDED
        estimated_eob = 0
      elsif !eobs_per_image.to_f.zero?
        estimated_eob = eobs_per_image * total_number_of_images
      else
        estimated_eob = ((50.00 * total_number_of_images) / 100.00).round
      end
    end
    estimated_eob
  end

  # Returns false unless the batch has been completed
  def incomplete?
    job_status != JobStatus::COMPLETED
  end

  # Returns checks with job_status != JobStatus::COMPLETED/JobStatus::INCOMPLETED
  # Inorder to avoid checks which are not in the JobStatus::COMPLETED/JobStatus::INCOMPLETED 
  # status, in the operation log
  def not_qualified?
    job_status != JobStatus::COMPLETED and job_status != JobStatus::INCOMPLETED and job_status != JobStatus::EXCLUDED
  end
  
  def not_qualified_for_aggr_835_report?
    job_status != JobStatus::COMPLETED and job_status != JobStatus::INCOMPLETED and
      job_status != JobStatus::PROCESSING and job_status != JobStatus::ADDITIONAL_JOB_REQUESTED
  end
  
  def guid_number
    return self.client_specific_fields[:guid_number] unless self.nil? or self.client_specific_fields.nil?
  end

  def guid_number=(guid_number)
    client_specific_fields = {}
    client_specific_fields[:guid_number] = guid_number
    self.client_specific_fields = client_specific_fields
  end

  # The method 'get_exact_images_for_job_reference' returns the exact image
  # reference which is associated with a job
  # It takes 1 parameter image_page_no as follows :
  def get_exact_images_for_job_reference(image_page_no)
    if !images_for_jobs.blank?
      first_image_for_job = images_for_jobs.first
      page_count = first_image_for_job.page_count.to_i
      is_multi_page =  page_count > 1
      if is_multi_page
        images_for_job_id = first_image_for_job.id
      else
        images_for_jobs.each do |images_for_job|
          if image_page_no.to_i == images_for_job.image_number
            images_for_job_id = images_for_job.id
          end
          if !images_for_job_id.blank?
            break
          end
        end
      end
    end
    images_for_job_id
  end
  
  # Returns 'image_type_obj_array' - an array of all image type objects of a 
  # job obtained through images_for_job_id.
  def get_all_image_type_obj_for_job
    image_type_obj_array = []
    images_for_jobs.each do |images_for_job|
      image_type_obj_array << ImageType.where(["images_for_job_id = ?", images_for_job.id])
    end
    image_type_obj_array = image_type_obj_array.flatten
    image_type_obj_array
  end
  #
  # Returns 'partial_eob_image_type_obj_array' - an array of all image type objects 
  # (ie:containing image types other than EOB, OTH with full EOB)
  # of a job obtained through images_for_job_id.
  def get_all_partial_eob_image_type_obj_for_job
    partial_eob_image_type_obj_array = []
    images_for_jobs.each do |images_for_job|
      partial_eob_image_type_obj_array << ImageType.find(:all, :conditions => ["images_for_job_id = ? and insurance_payment_eob_id is null", images_for_job.id] )
    end
    partial_eob_image_type_obj_array = partial_eob_image_type_obj_array.flatten
    partial_eob_image_type_obj_array
  end
  
  # Returns array with image type values only for that job
  # (ie:contains image types other than EOB, OTH with full EOB)
  def get_partial_eob_image_types_for_job(partial_eob_image_type_obj_array)
    partial_eob_image_type_array = partial_eob_image_type_obj_array.map {|image_type| image_type.image_type} unless partial_eob_image_type_obj_array.blank?
    partial_eob_image_type_array
  end
  
  # Returns array with image page number value only for that job
  # (ie:for image types other than EOB, OTH with full EOB)
  def get_partial_eob_image_page_nos_for_job(partial_eob_image_type_obj_array)
    partial_image_page_nos_array = partial_eob_image_type_obj_array.map {|image_type| image_type.image_page_number} unless partial_eob_image_type_obj_array.blank?
    partial_image_page_nos_array
  end
  
  # Returns array with image page number value only for that job.
  def get_all_image_page_numbers_for_job(image_type_obj_array)
    image_page_number_array = image_type_obj_array.map {|image_type| image_type.image_page_number} unless image_type_obj_array.blank?
    image_page_number_array
  end
  
  # Returns array with image type values only for that job.
  def get_all_image_types_for_job(image_type_obj_array)
    image_type_array = image_type_obj_array.map {|image_type| image_type.image_type} unless image_type_obj_array.blank?
    image_type_array
  end
  
  # Returns the total image page count of a job
  def get_total_image_page_count
    total_page_count = 0
    images_for_jobs.each do |images_for_job|
      total_page_count += images_for_job.page_count.to_i
    end
    total_page_count
  end
  
  # Returns the total provider_adjustment_amount of a job
  def get_provider_adjustment_amount
    amount = ProviderAdjustment.where(["job_id in (?)", get_ids_of_all_jobs]).sum(:amount)
    amount.to_f
  end
   
  def get_provider_adjustment_amount_old
    amount = 0
    ids_of_all_jobs = get_ids_of_all_jobs
    
    conditions = "provider_adjustments.job_id IN (#{ids_of_all_jobs.uniq.join(',')})"
    provider_adjustment_amounts = ProviderAdjustment.select("provider_adjustments.amount").where(conditions).all
    unless provider_adjustment_amounts.blank?
      provider_adjustment_amounts.each do |provider_adj|
        amount += provider_adj.amount
      end
    end
    
    amount.to_f
  end
  
  # Returns the serial numbers of all eobs in a job which has an association 
  # with the reason code.
  def get_eob_slno_for_reason_codes(reason_code_id)
    eob_slno_for_secondary_reason_codes = []
    eob_slno_for_primary_reason_codes = []
    eob_slno_for_primary_and_secondary_reason_codes = []
    
    insurance_payment_eobs = check_information.eobs
    insurance_payment_eobs.each_with_index do |insurance_payment_eob, index|
      primary_reason_code_ids = []
      if insurance_payment_eob.category == "claim"
        primary_reason_code_ids = insurance_payment_eob.get_primary_reason_code_ids_of_eob
        if (!primary_reason_code_ids.blank? && primary_reason_code_ids.include?(reason_code_id.to_i))
          eob_slno_for_primary_reason_codes << index + 1
        elsif $IS_PARTNER_BAC
          insurance_payment_eobs_reason_codes = InsurancePaymentEobsReasonCode.find_by_reason_code_id_and_insurance_payment_eob_id(reason_code_id, insurance_payment_eob.id)
          eob_slno_for_secondary_reason_codes << index + 1 unless insurance_payment_eobs_reason_codes.blank?
        end
      else
        service_payment_eobs = insurance_payment_eob.service_payment_eobs
        unless service_payment_eobs.blank?
          service_payment_eobs.each do |service_payment_eob|
            primary_reason_code_ids = service_payment_eob.get_primary_reason_code_ids_of_svc
            if (!primary_reason_code_ids.blank? && primary_reason_code_ids.include?(reason_code_id.to_i))
              eob_slno_for_primary_reason_codes << index + 1
            elsif $IS_PARTNER_BAC
              service_payment_eobs_reason_codes = ServicePaymentEobsReasonCode.find_by_reason_code_id_and_service_payment_eob_id(reason_code_id, service_payment_eob.id)
              eob_slno_for_secondary_reason_codes << index + 1 unless service_payment_eobs_reason_codes.blank?
            end
          end
        end
      end    
    end
   
    eob_slno_for_primary_and_secondary_reason_codes = eob_slno_for_primary_reason_codes + eob_slno_for_secondary_reason_codes
    return eob_slno_for_primary_and_secondary_reason_codes.uniq
  end
  
  # The method 'retrieve_transaction_type' obtains the saved transaction_type in the table 'images_for_jobs' for the EOB.
  # For Multi page image, there will be a single images_for_jobs record for such EOB.
  # So all the images will have the same Transaction Type.
  # Retrieval of 'transaction_type' for Multi page image is obtained directly without any condition.
  # For Single page image,  'transaction_type' is different for different images. 
  # Retrieval of 'transaction_type' for Single page image is obtained where 'image_page_no' of the EOB and 'image_number' from the 'images_for_jobs' matches.  
  def retrieve_transaction_type(insurance_eob, facility = nil)
    facility ||= batch.facility
    transac_type = nil
    images_for_jobs.each do |images_for_job|
      is_multi_page = facility.image_type == 1
      if is_multi_page
        transac_type = images_for_job.transaction_type
      else
        if insurance_eob.image_page_no == images_for_job.image_number
          transac_type = images_for_job.transaction_type
        end        
      end      
    end
    transac_type
  end

  # Returns the count of insurance or patient EOBs
  # Output :
  # total count of EOBs processed for the job
  def eob_count
    count = count_of_insurance_eobs
    if count == 0
      count = count_of_patpay_eobs
    end
    count
  end

  # Returns the EOBs of insurance type
  # Output :
  #  count of insurance EOBs processed for the job
  def count_of_insurance_eobs
    InsurancePaymentEob.count(:id, :conditions => ["sub_job_id = ?", id])
  end

  # Returns the EOBs of patient type
  # Output :
  #  count of patient EOBs processed for the job
  def count_of_patpay_eobs
    count = 0
    eobs = PatientPayEob.where("jobs.id = ?", get_parent_job_id).
      joins("join check_informations on check_informations.id = patient_pay_eobs.check_information_id \
        join jobs on jobs.id = check_informations.job_id")
    if !eobs.blank?
      count = get_count_of_eobs_containing_image_numbers_that_of_job(eobs)
    end
    count
  end

  # Returns the eob count having the image number range that of the job
  # Input :
  # eobs : objects of InsurancePaymentEob or  PatientPaymentEob
  # Output :
  # count of EOBs of InsurancePaymentEob or  PatientPaymentEob having the appropriate image number
  def get_count_of_eobs_containing_image_numbers_that_of_job(eobs)
    eobs = eobs.select do |eob|
      (pages_from..pages_to).include?(eob.image_page_no)
    end
    eobs.length
  end
  
  # This is a special scenario in OCR mode where EOBs
  # get spanned across pages in the image.
  # The OCR Engine may create more than 1 EOB in this case.
  # The patient account number of redundant EOBs will be blank.
  # This method deletes such EOBs.

  def delete_invalid_eobs(check, client_id, facility_id)
    insurance_eobs_count = InsurancePaymentEob.count(:conditions => [ "check_information_id = ?", check.id ] )
    if insurance_eobs_count != 0
      deleted_eobs = InsurancePaymentEob.destroy_all(:check_information_id =>  check.id, :patient_account_number => nil)
      entity = 'insurance_payment_eobs'
    else
      deleted_eobs = PatientPayEob.destroy_all(:check_information_id =>  check.id, :account_number => nil)
      entity = 'patient_pay_eobs'
    end
    if deleted_eobs.length > 0
      deleted_entity_records = []
      deleted_eobs.each do |deleted_eob|
        parameters = { :entity => entity, :entity_id => deleted_eob.id,
          :client_id => client_id, :facility_id => facility_id }
        deleted_entity_records << DeletedEntity.create_records(parameters)
      end
      if deleted_entity_records.present?
        DeletedEntity.import(deleted_entity_records)
      end
    end
  end

  def original_job
    Job.find(:first, :conditions => ["id = #{original_job_id}"], :include => :images_for_jobs)
  end

  def sibling_count
    Job.count(:conditions => ["split_parent_job_id = ?", original_job_id])
  end

  def children_count
    Job.count(:conditions => ["split_parent_job_id = ?", id])
  end

  def micr_applicable?
    facility = batch.facility
    facility.details[:micr_line_info]
  end

  def correspondence?
    check_information.correspondence?
  end

  def aba_validation
    (micr_applicable? && !correspondence?) ? "required validate-aba" : " "
  end

  def payer_acc_no_validation
    (micr_applicable? && !correspondence?) ? "required validate-payer-acc-num" : " "
  end

  def get_parent_job_id
    parent_job_id || id
  end

  # This is for getting the list of id of all child jobs, belonging to the same
  # parent as that of the current job.
  def get_ids_of_all_child_jobs_old
    ids_of_child_jobs = []
    if parent_job_id.blank?
      child_jobs = Job.where("jobs.parent_job_id = #{id}").all
      child_jobs.each do |child_job|
        ids_of_child_jobs << child_job.id
      end
    end
    
    ids_of_child_jobs
  end

  def get_ids_of_all_child_jobs
    result = []
    result = Job.where(["parent_job_id =?",id]).select(:id).collect(&:id) if parent_job_id.blank?
    result.flatten.uniq
  end

  #This is for getting ids of parent job and its child jobs
  def get_ids_of_all_jobs_old
    ids_of_jobs = []
    
    if parent_job_id.blank?
      child_jobs = Job.where("jobs.parent_job_id = #{id}").all      
      ids_of_jobs << id
    else
      child_jobs = Job.where("jobs.parent_job_id = #{parent_job_id}").all
      ids_of_jobs << parent_job_id
    end

    child_jobs.each do |child_job|
      ids_of_jobs << child_job.id
    end

    ids_of_jobs
  end

  def aba_validation_for_upmc
    micr_applicable? ? " validate-aba" : " "
  end

  def payer_acc_no_validation_for_upmc
    micr_applicable? ? " validate-payer-acc-num" : " "
  end

  #This is for getting ids of parent job and its child jobs
  def get_ids_of_all_jobs
    result = [id, parent_job_id].compact
    result << Job.where(["parent_job_id in (?)",result]).select(:id).collect(&:id)
    result.flatten.uniq
  end
  
  def update_status(status, current_user_role)
    processor = current_user_role == 'processor'
    qa = current_user_role == 'qa'
    self.processor_flag_time = Time.now if processor
    
    if status == JobStatus::COMPLETED
      if processor
        self.job_status = status if qa_status == QaStatus::NEW || qa_status == QaStatus::COMPLETED
        self.processor_status = ProcessorStatus::COMPLETED
      elsif qa
        self.job_status = status if processor_status == ProcessorStatus::COMPLETED
        self.qa_status = QaStatus::COMPLETED
      end
    elsif status == JobStatus::INCOMPLETED
      self.qa_status = QaStatus::INCOMPLETED if qa
      self.processor_status = ProcessorStatus::INCOMPLETED if processor
      self.job_status = status
    end
    self.save!
  end

  def set_total_edited_fields(insurance_eobs)
    total_edited_fields = 0
    unless insurance_eobs.blank?
      total_edited_fields = insurance_eobs.sum('total_edited_fields').to_i
    end
    self.total_edited_fields = total_edited_fields
    self.save
  end

  # This is a predicate method of checking whether the job is a parent job or not
  # Output :
  #  True if the job is a parent job, else False
  def is_a_parent?
    count_of_sub_jobs = Job.where("parent_job_id = #{id}").count
    if count_of_sub_jobs == 0
      false
    else
      true
    end
  end

  # get all provider adjustments of the current job and child jobs
  def get_all_provider_adjustments
    ProviderAdjustment.joins(" INNER JOIN jobs ON jobs.id= provider_adjustments.job_id ").where("jobs.id = #{self.id}  OR jobs.parent_job_id=#{self.id}")
  end

  # Returns the job ids related to a check.
  # This will provide job ids including mormal jobs or parent and child jobs together.
  # Input :
  #  job : The current object of job. It can be a normal job or child job or parent job
  #  If job is of normal job, it returns the records related to that job.
  #  If job is of parent job, it returns the records of child job and parent job.
  #  If job is of child job, it returns the records of that child job only.
  # Output :
  #  ids_of_all_jobs : Array of IDs of jobs related to a check
  def job_ids_for_check
    ids_of_all_jobs = []
    ids_of_all_child_jobs = get_ids_of_all_child_jobs
    ids_of_all_jobs += ids_of_all_child_jobs unless ids_of_all_child_jobs.blank?
    ids_of_all_jobs << id
    ids_of_all_jobs.uniq
  end
  
  def get_amount_so_far
    InsurancePaymentEob.amount_so_far(CheckInformation.check_information(self.id), Facility.find(self.facility))
  end

  # 'Splitter' script duplicates image file name in some cases.
  # This method returns the original image file name.
  def original_file_name
    file_name_parts = initial_image_name.split('_')
    if file_name_parts.length > 0
      last_occurrence = nil
      first_element = file_name_parts[0]
      if Output835.element_duplicates?(first_element, file_name_parts)
        last_occurrence = file_name_parts.rindex(first_element)
      end
      last_occurrence ||= file_name_parts.length
      # Fetch the first n ( where n = last_occurrence ) elements of the array, until the first element duplicates.
      normalized_file_name_parts = file_name_parts.first(last_occurrence)
      normalized_file_name = normalized_file_name_parts.join('_')
      if Output835.element_duplicates?(first_element, file_name_parts)
        # Only for the duplicating file names, the extension of the file is appended to the normalized_file_name.
        # For others, the normalized_file_name itself has the extension.
        image_format_extension = batch.facility.image_file_format
        normalized_file_name << '.' << image_format_extension.downcase
      end
      normalized_file_name
    else
      initial_image_name
    end
  end

  def set_image_numbers(image_ids_being_added)
    last_index = self.images_for_jobs.count
    image_ids_being_added.each_with_index do |image_id, i|
      ImagesForJob.where(:id => image_id).update_all(:image_number => (last_index + 1 + i), :updated_at => Time.now)
    end
  end

  def orbograph_correspondence?(client_name)
    client_name = client_name.to_s.upcase
    ((client_name == 'ORBOGRAPH' || client_name == 'ORB TEST FACILITY') &&
        is_correspondence)
  end

  ##################################################  PRIVATE ######################################
  private
  
  def check_number_validate
    check_number = check_number.to_s
    existing_check_numbers = []
    if check_number_changed?
      if not check_number.include?(".")
        if not (split_parent_job_id.blank? && check_number.to_f.zero?)
          jobs = Job.find(:all, :conditions => "batch_id = #{batch_id}")
          existing_check_numbers = jobs.map do |job|
            job.check_number.to_s if not job.check_number.to_f.zero?
          end

          if existing_check_numbers && existing_check_numbers.include?(check_number)
            errors[:base] << "Check Number #{check_number} is already taken"
          end
        end
      else
        errors[:base] << "Period is not allowed in check number"
      end
    end
  end

  def strip_whitespace
    self.check_number.to_s.gsub!(/\s+/, "") unless self.check_number.blank?
  end
end


