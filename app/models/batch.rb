# == Schema Information
# Schema version: 69
#
# Table name: batches
#
#  id              :integer(11)   not null, primary key
#  batchid         :integer(11)
#  date            :date
#  facility_id     :integer(11)
#  arrival_time    :datetime
#  target_time     :datetime
#  status          :string(255)   default(New)
#  eob             :integer(11)
#  completion_time :datetime
#  payer_id        :integer(11)
#  comment         :string(255)
#  contracted_time :datetime
#  manual_override :boolean(1)
#  source          :string(255)   default(Manual)
#  updated_by      :integer(11)
#  updated_at      :datetime
#  created_by      :integer(11)
#  created_at      :datetime
#  hlsc_id         :integer(11)
#

# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class Batch < ActiveRecord::Base

  # include OutputBatch
  
  belongs_to :updated_by, :class_name => "User", :foreign_key => "updated_by"
  belongs_to :created_by, :class_name => "User", :foreign_key => "created_by"
  has_many :jobs, :dependent => :destroy
  has_many :images_for_jobs, :dependent => :destroy
  has_many :output_activity_logs
  has_many :capitation_accounts
  
  has_many :check_informations,:through=>:jobs, :dependent => :destroy
  belongs_to :facility
  delegate :client, :to => :facility
  belongs_to :payer
  belongs_to :client
  belongs_to :inbound_file_information
  has_many :mpi_statistics_reports, :dependent => :destroy
  validates_presence_of :batchid
  #validates_uniqueness_of :batchid, :scope => :facility_id
  validate :validation_for_priority
  has_one :meta_batch_information
  has_many :user_activity_logs, :conditions => {:entity_name => 'BATCH'}, :foreign_key => "entity_id"
  has_many :report_check_informations, :dependent => :destroy
  alias_attribute :bank_deposit_date, :date
  has_many :completed_jobs, :class_name => 'Job', :conditions => {:job_status => 'COMPLETED'}
  has_many :completed_checks, :through => :completed_jobs
  has_many :incompleted_jobs, :class_name => 'Job', :conditions => {:job_status => 'INCOMPLETED'}
  has_many :incompleted_checks, :through => :incompleted_jobs
  has_many :completed_jobs_without_exclusion, :class_name => 'Job', :conditions => ["jobs.job_status = 'COMPLETED' and jobs.is_excluded = false"]
  has_many :completed_checks_without_exclusion, :through => :completed_jobs_without_exclusion
  has_many :incompleted_jobs_without_exclusion, :class_name => 'Job', :conditions => ["jobs.job_status = 'INCOMPLETED' and jobs.is_excluded = false"]
  has_many :incompleted_checks_without_exclusion, :through => :incompleted_jobs_without_exclusion

  has_many :jobs_for_eob_report, :class_name => 'Job', :conditions => ["(jobs.job_status = 'COMPLETED' or jobs.job_status = 'INCOMPLETED'
    or jobs.job_status = 'PROCESSING' or jobs.job_status = 'ADDITIONAL_JOB_REQUESTED')"]
  has_many :checks_for_eob_report, :through => :jobs_for_eob_report

  has_details :provider_id,
    :group_id,
    :interchange_sender_id,
    :interchange_receiver_id

  NOMINAL_PROCESSOR_RATE = 12.5
  NOMINAL_QA_RATE = 10

  scope :work_list_collection, lambda {|conditions|
    select("  batches.id as id \
            , batches.batchid as batchid \
            , batches.date as date \
            , batches.batch_type \
            , batches.correspondence as correspondence \
            , batches.completion_time as completion_time \
            , batches.arrival_time as arrival_time \
            , batches.expected_completion_time as expected_completion_time \
            , batches.tat_comment as tat_comment \
            , batches.priority as priority \
            , batches.status as status \
            , batches.facility_id as facility_id \
            , batches.facility_wise_auto_allocation_enabled as facility_wise_auto_allocation_enabled \
            , batches.payer_wise_auto_allocation_enabled as payer_wise_auto_allocation_enabled \
            , batches.ocr_job_auto_allocation_enabled as ocr_job_auto_allocation_enabled \
            , batches.target_time as target_time \
            , batches.contracted_time as contracted_time \
            , (batches.arrival_time + INTERVAL facilities.tat HOUR) AS batch_target_time \
            , clients.internal_tat as client_internal_tat \
            , facilities.sitecode as facility_sitecode \
            , facilities.name as facility_name \
            , facilities.tat as facility_tat \
            , meta_batch_informations.provider_code as provider_code \
            , SUM(if(jobs.job_status = '#{JobStatus::PROCESSING}', 1, 0)) as allocated \
            , SUM(if(jobs.is_excluded = 1, 1, 0)) as excluded_job_count \
            , SUM(if(jobs.processor_status = '#{ProcessorStatus::COMPLETED}', 1, 0)) as processor_completed \
            , SUM(if(jobs.processor_status = '#{ProcessorStatus::INCOMPLETED}', 1, 0)) as processor_incompleted \
            , SUM(if(jobs.processor_id IS NULL AND jobs.processor_status = '#{ProcessorStatus::INCOMPLETED}', 1, 0)) as admin_incompleted \
            , SUM(CASE WHEN (check_informations.payment_method = 'CHK' or \
              check_informations.payment_method = 'OTH') THEN \
              ((IFNULL(insurance_payment_eobs.total_amount_paid_for_claim,0)) - \
              (IFNULL(insurance_payment_eobs.over_payment_recovery, 0))) + \
              CASE WHEN LOCATE('interest_in_service_line: false',facilities.details) THEN IFNULL(insurance_payment_eobs.claim_interest,0) \
                   WHEN LOCATE('interest_in_service_line: true',facilities.details) THEN 0 END + \
              IFNULL(insurance_payment_eobs.late_filing_charge,0) + \
              IFNULL(patient_pay_eobs.stub_amount,0) ELSE 0 END) as tot_amount_so_far \
            , count(jobs.id) as job_count \
            , count(DISTINCT check_informations.id) as checks_count \
            , count(insurance_payment_eobs.id) + count(patient_pay_eobs.id) as total_completed_eobs").
      where(conditions).
      joins(" INNER JOIN facilities ON facilities.id = batches.facility_id \
              INNER JOIN clients ON clients.id = facilities.client_id \
              LEFT OUTER JOIN meta_batch_informations ON meta_batch_informations.batch_id = batches.id \
              LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id \
              LEFT OUTER JOIN check_informations ON check_informations.job_id = jobs.id \
              LEFT OUTER JOIN insurance_payment_eobs ON insurance_payment_eobs.check_information_id = check_informations.id \
              LEFT OUTER JOIN patient_pay_eobs ON patient_pay_eobs.check_information_id = check_informations.id").
      group("batches.id").
      order("priority asc, batch_target_time asc, batches.id")
  }

  scope :work_list_estimated_eob_count_collection, lambda { |conditions|
    select("batches.id as id, sum(jobs.estimated_eob) as tot_estimated_eobs, \
        (batches.arrival_time + INTERVAL facilities.tat HOUR) AS batch_target_time, \
         batches.priority as priority").\
      where(conditions).joins("LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id \
        INNER JOIN facilities ON facilities.id = batches.facility_id \
        INNER JOIN clients ON clients.id = facilities.client_id \
        LEFT OUTER JOIN meta_batch_informations ON meta_batch_informations.batch_id = batches.id").
      group("batches.id").order("priority asc, batch_target_time asc, batches.id")
  }

  scope :work_list_image_count_collection, lambda { |conditions|
    select("batches.id as id, count(DISTINCT images_for_jobs.id) as batch_image_count, \
        (batches.arrival_time + INTERVAL facilities.tat HOUR) AS batch_target_time, \
         batches.priority as priority").\
      where(conditions).joins("LEFT OUTER JOIN jobs ON jobs.batch_id = batches.id \
        INNER JOIN facilities ON facilities.id = batches.facility_id \
        INNER JOIN clients ON clients.id = facilities.client_id \
        INNER JOIN images_for_jobs ON images_for_jobs.batch_id = batches.id \
        LEFT OUTER JOIN meta_batch_informations ON meta_batch_informations.batch_id = batches.id").
      group("batches.id").order("priority asc, batch_target_time asc, batches.id")
  }

  # Named scopes to return results limited by the grouping defined for output generation
  scope :by_batch_date, lambda {|batch| {:conditions => {:date => batch.date, :facility_id => batch.facility_id}}}

  scope :by_batch_date_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => batch.date, \
        :facility_id => batch.facility_id) }

  scope :by_lockbox_and_date_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facilities_npi_and_tins, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => batch.date, \
        :lockbox => batch.lockbox) }

  scope :by_batch_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:id => batch.id, \
        :facility_id => batch.facility_id) }
  scope :by_batch_date_and_facility, lambda {|batch,facility| {:conditions => {:date => batch.date, :facility_id => facility.id}}}
  scope :by_cut, lambda {|batch| {:conditions => {:cut => batch.cut,:date => batch.date, :facility_id => batch.facility_id }}}

  scope :by_cut_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:cut => batch.cut,:date => batch.date, :facility_id => batch.facility_id)}
 
  scope :by_lockbox_cut, lambda {|batch| {:conditions => {:lockbox => batch.lockbox,:date => batch.date, :facility_id => batch.facility_id },:group=>:cut}}

  scope :by_lockbox_cut_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:lockbox => batch.lockbox,:date => batch.date, :facility_id => batch.facility_id).group("cut")}

  scope :by_cut_and_payerid, lambda {|batch| 
    {:conditions => {:facility_id => batch.facility_id,:date => batch.date, :cut => batch.cut },
      :joins=>[:jobs,:check_informations],
      :group=>"check_informations.payer_id"}}

  scope :by_cut_and_payerid_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:facility_id => batch.facility_id, \
        :date => batch.date, :cut => batch.cut).joins(:jobs,:check_informations).group("check_informations.payer_id")}

  scope :by_cut_and_extension, lambda {|batch| {:conditions => {:facility_id => batch.facility_id,:date => batch.date,:cut => batch.cut}}}
  scope :by_cut_and_extension_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:facility_id => batch.facility_id,\
        :date => batch.date,:cut => batch.cut)}

  scope :by_payer_id_by_batch_date, lambda {|batch| {:conditions => {:date => batch.date, :facility_id => batch.facility_id},
      :joins => "LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id",
      :group=>"batches.id"}}

  scope :by_payer_id_by_batch_date_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => batch.date, :facility_id => \
        batch.facility_id).joins("LEFT JOIN jobs on jobs.batch_id = batches.id \
             LEFT JOIN check_informations on check_informations.job_id = jobs.id \
             LEFT JOIN payers on payers.id = check_informations.payer_id").group("batches.id")}

  scope :by_payer_by_batch_date, lambda {|batch| {:conditions => {:date => batch.date, :facility_id => batch.facility_id},
      :joins => "LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id",
      :group=>"batches.id"}}

  scope :by_payer_by_batch_date_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => \
        batch.date, :facility_id => batch.facility_id).joins("LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id").group("batches.id")}

  scope :nextgen_grouping, lambda {|batch| {:conditions => {:date => batch.date, :facility_id => batch.facility_id},
      :joins => "LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id",
      :group=>"batches.id"}}

  scope :nextgen_grouping_group, lambda {|batch| includes([{:facility => [:facility_output_configs, :facility_lockbox_mappings]}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => \
        batch.date, :facility_id => batch.facility_id).joins("LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id").group("batches.id")}

  scope :by_output_payer_id_by_batch_date, lambda {|batch| {:conditions => {:date => batch.date, :facility_id => batch.facility_id},
      :joins => "LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id",
      :group=>"batches.id"}}
  
  scope :nextgen_group_for_client_level, lambda {|batch| includes([{:client => :client_output_configs}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => \
        batch.date, :client_id => batch.client_id).joins("LEFT JOIN jobs on jobs.batch_id = batches.id \
                LEFT JOIN check_informations on check_informations.job_id = jobs.id \
                LEFT JOIN payers on payers.id = check_informations.payer_id").group("batches.id")}
  
  scope :batch_date_group_for_client_level, lambda {|batch| includes([{:client => :client_output_configs}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => batch.date, \
        :client_id => batch.client_id) }

  scope :client_and_deposit_date_group_for_client_level, lambda {|batch| includes([{:client => :client_output_configs}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:date => batch.date, \
        :client_id => batch.client_id) }

  scope :batch_group_for_client_level, lambda {|batch| includes([{:client => :client_output_configs}, {:completed_jobs => :provider_adjustments}, {:completed_checks => \
            [:payer,{:insurance_payment_eobs => [:service_payment_eobs , :patients, :claim_information]}, {:micr_line_information => :payer}]}]).where(:id => batch.id, \
        :client_id => batch.client_id) }


  before_save :set_associated_entity_updated_at
  after_update :generate_output, :if => proc{|obj| obj.status_changed? && obj.status == 'OUTPUT_READY'}

  def set_associated_entity_updated_at
    self.associated_entity_updated_at = Time.now + 4.second
  end

  def to_s
    "#{batchid} (#{client.name} - #{facility.name})"
  end

  def validation_for_priority
    if !(1..5).include?(priority)
      errors.add(:base, "Priority should be from 1 to 5")
    end
  end

  # Determines if a batch and its peers (as per the grouping applied)
  # are ready to be sent out for output generation
  def qualified_for_output_generation?    
    !batch_bundle.detect { |batch| batch.incomplete? }
  end

  # Determines if a batch and its peers (as per the grouping applied)
  # are ready to be sent out for supplimental output generation
  def qualified_for_supplimental_output_generation?
    !batch_bundle_for_supplemental_output.detect { |batch| !batch.eligible_for_supplimental_output? }
  end
  
  # adding more status to regenerate output
  def eligible_for_supplimental_output?
    [BatchStatus::OUTPUT_READY, BatchStatus::OUTPUT_GENERATED, BatchStatus::OUTPUT_EXCEPTION].include?(status)
  end

  alias_method :eligible_for_output_generation?, :eligible_for_supplimental_output?
  
  # Returns all the batches for which the output is to be generated
  # by applying the corresponding named scope for the given grouping
  # For example, if a batch's facility's output configuration specifies
  # that files should be created by cut, this method will gather all
  # batches that should be a part of that cut.
  def batch_bundle
    return @batch_bundle if @batch_bundle
    grouping = widest_grouping("Output")
    if ['by_batch_date', 'by_cut','by_lockbox_cut','by_cut_and_payerid', "nextgen_grouping",
        'by_payer_id_by_batch_date','by_payer_by_batch_date','by_cut_and_extension','by_output_payer_id_by_batch_date'].include? grouping
      @batch_bundle = Batch.send(grouping, self)
    else
      @batch_bundle = [self]
    end
  end
  
  def batch_bundle_for_supplemental_output
    return @batch_bundle_supplemental_output if @batch_bundle_supplemental_output
    if ['by_batch_date'].include? widest_grouping("Operation Log")
      @batch_bundle_supplemental_output = Batch.send(widest_grouping("Operation Log"), self)
    else
      @batch_bundle_supplemental_output = [self]
    end
  end

  # Returns the larger of the two kinds of grouping defined for Insurance and Patient Payment EOBs
  # by applying sorting, which will return an array in ascending order based on the wight of the grouping
  # ex: ['by_batch_date', 'by_cut', 'by_batch', 'by_payer', 'by_check']
  # If insurance eob's grouping is 'by_batch' and patient eob's grouping is 'by_batch_date'
  # this will return 'by_batch_date'
  # If there's no output config defined for a facility, it returns the default grouping 'by_batch'
  def widest_grouping(report_type)
    if report_type == 'Output'
      output_configs = FacilityOutputConfig.where(:report_type => 'Output', :facility_id => facility_id)
    elsif report_type == 'Operation Log'
      output_configs = FacilityOutputConfig.where(:report_type => 'Operation Log', :facility_id => facility_id)
    end
    unless output_configs.blank?
      grouping = output_configs.sort_by {|fc| fc.grouping_weight}.last.grouping
      grouping = grouping.downcase.gsub(' ','_')
    else
      puts "No output configuration defined for #{facility.name}, grouping 'By Batch' by default"
      'by_batch'
    end
  end
  
  # Get complete number of EOBs for a batch
  def get_completed_eobs
    completed_eobs = 0
    self.jobs.each do |job|
      # job.eob_count will fetch total EOB count for the job based on count of database table records for EOBs
      completed_eobs = job.eob_count + completed_eobs
    end
    return completed_eobs
  end
  
  def expected_time
    #Processor completion time calculation
    proc_id, max_assigned_eobs = Job.sum(:estimated_eob, :joins => "left join batches on batches.id = jobs.batch_id", :conditions => ["batches.id = ? and jobs.processor_id is not NULL", self.id], :group => "processor_id").max do |a,b|
      begin
        user_a = User.find(a[0])
        user_a_rate = user_a.processing_rate_for_client(self.client)
      rescue
        # If the user is deleted after assignment
        user_a_rate = User.default_processing_rate_for_client(self.client)
      end
      begin
        user_b = User.find(b[0])
        user_b_rate = user_b.processing_rate_for_client(self.client)
      rescue
        # If the user is deleted after assignment
        user_b_rate = User.default_processing_rate_for_client(self.client)
      end
      a[1].to_f / user_a_rate <=> b[1].to_f / user_b_rate
    end
    processor_time_to_complete = nil
    if proc_id != nil and max_assigned_eobs != nil
      begin
        processor = User.find(proc_id)
        processing_rate = processor.processing_rate_for_client(self.client)
      rescue
        processing_rate = User.default_processing_rate_for_client(self.client)
      end
      processor_time_to_complete = (max_assigned_eobs.to_f / processing_rate).hours
    end
    
    #QA completion time calculation
    # We assumed that QA is already assigned to jobs
    qa_id, qa_max_assigned_eobs = Job.sum(:estimated_eob,
      :joins => "left join batches on batches.id = jobs.batch_id",
      :conditions => ["batches.id = ? and jobs.qa_id is not NULL", self.id],
      :group => "qa_id").max do |a,b|
      a[1] <=> b[1]
    end
    if qa_id != nil and qa_max_assigned_eobs != nil
      qa_time_to_complete = (qa_max_assigned_eobs.to_f / NOMINAL_QA_RATE.to_f).hours
    end
    
    if processor_time_to_complete.nil? and qa_time_to_complete.nil?
      computed_expected_time = nil
    elsif qa_time_to_complete.nil?
      computed_expected_time = Time.now + processor_time_to_complete
    elsif processor_time_to_complete.nil?
      computed_expected_time = Time.now + qa_time_to_complete
    else
      computed_expected_time = Time.now + processor_time_to_complete + qa_time_to_complete
    end
    
    return computed_expected_time
  end
  
  # Batch Status to be 'NEW'
  # - There are no jobs created
  # - All the sub jobs are in new status
  
  # Batch Status to be 'OUTPUT_READY'
  # This status should be automatically set to batches when Processor as well as QA 'Completes' / 'Incompletes' each and every job within the batch 
  # Output generation should only be possible when all batches within the group are all in 'OUTPUT_READY' status 
 
  # Batch Status to be 'COMPLETED'
  # This status should be automatically set to batches when Processor 'Completes' / 'Incompletes' each and every job within the batch 
  # Output generation should not be allowed for a batch in 'COMPLETED' status 
  # Unless all jobs within the batch are 'QA Completed', batch remains in 'Completed' status, provided Processor had 'Completed' / 'Incompleted' each and every job within the batch. 

  # Batch Status to be 'PROCESSING'
  # - If the above condition is not satisfied
 
  def update_status
    self.reload
    jobs = self.jobs
    complete_jobs = get_complete_jobs(jobs, JobStatus::COMPLETED, ProcessorStatus::COMPLETED)      
    incomplete_jobs = get_complete_jobs(jobs, JobStatus::INCOMPLETED, ProcessorStatus::INCOMPLETED) unless self.facility.client.name == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'
    incomplete_jobs = get_upmc_incomplete_jobs(jobs, JobStatus::INCOMPLETED) if self.facility.client.name == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'
    complete_output_ready_jobs = get_output_ready_jobs(jobs, JobStatus::COMPLETED, ProcessorStatus::COMPLETED, QaStatus::COMPLETED)    
    incomplete_output_ready_jobs = get_output_ready_jobs(jobs, JobStatus::INCOMPLETED, ProcessorStatus::INCOMPLETED, QaStatus::INCOMPLETED)

    excluded_jobs = jobs.select do |job|
      job.job_status.upcase == JobStatus::EXCLUDED
    end
    
    new_jobs = jobs.select do |job|
      job.job_status == JobStatus::NEW
    end

    allocated_jobs = jobs.select do |job|
      job.job_status == JobStatus::PROCESSING
    end

    excluded_processing_or_new_jobs = jobs.select do |job|
      ((job.job_status == JobStatus::NEW || job.job_status == JobStatus::PROCESSING) &&
          job.is_excluded == true)
    end

    previous_status = self.status
    if jobs.size == new_jobs.size or jobs.size == 0
      self.status = BatchStatus::NEW
      self.completion_time = nil
    elsif jobs.size ==  (complete_output_ready_jobs.size + excluded_jobs.size +
          incomplete_output_ready_jobs.size + excluded_processing_or_new_jobs.size)
      self.completion_time = Time.now
      self.status = BatchStatus::OUTPUT_READY
    elsif jobs.size ==  (complete_jobs.size + excluded_jobs.size +
          incomplete_jobs.size + excluded_processing_or_new_jobs.size)
      self.completion_time = Time.now
      self.status = BatchStatus::COMPLETED
    else
      self.status = BatchStatus::PROCESSING
      self.completion_time = nil
    end
    if previous_status == BatchStatus::NEW && self.status == BatchStatus::PROCESSING &&
        self.processing_start_time.blank?
      self.processing_start_time = Time.now
    end
    if previous_status == BatchStatus::PROCESSING && self.status == BatchStatus::COMPLETED
      self.processing_end_time = Time.now
    end
    set_qa_status
    self.save 
  end
  
  def get_complete_jobs(jobs, job_status, processor_status)
    final_jobs = jobs.select do |job|
      job.job_status == job_status && job.processor_status == processor_status  
    end
    final_jobs
  end

  def get_upmc_incomplete_jobs(jobs, job_status)
    final_jobs = jobs.select do |job|
      job.job_status == job_status 
    end
    final_jobs
  end

  def get_output_ready_jobs(jobs, job_status, processor_status, qa_status)
    final_jobs = jobs.select do |job|
      job.job_status == job_status && job.processor_status == processor_status  &&
        job.qa_status == qa_status
    end
    final_jobs
  end
  
  # Class level method to update all the batch's status within 4 days
  def Batch.update_status
    Batch.find(:all, :conditions => "(To_days(now()) - To_days(completion_time)) <= 4").each do |batch|
      batch.update_status
    end
  end
  
  
  # Class level method to update all the batch's etc within 4 days
  def Batch.update_etc
    Batch.find(:all, :conditions => "status = '#{BatchStatus::PROCESSING}' and 
          (To_days(now()) - To_days(completion_time)) <= 4").each do |batch|
      batch.expected_completion_time = batch.expected_time
      batch.save
    end
  end
  
  def contract_time(role)
    if role == "HLSC"
      self.arrival_time + self.facility.client.contracted_tat.hours
    else
      self.arrival_time + self.facility.client.tat.hours
    end
  end
  
  def estimated_eobs
    Job.find(:all, :conditions => "batch_id = #{self.id}").inject(0) do |sum, job|
      sum + job.estimated_eob
    end
  end
  
  # Returns the number of check in complete status
  def complete_check_count
    check_number = []
    self.jobs.each do |job|
      if job.job_status = JobStatus::COMPLETED
        check_number <<  job.check_number
      end
    end
    check_number.uniq!
    if check_number.nil?
      return 0
    else
      return check_number.size
    end
  end
  
  # Returns the total number of checks in the batch
  def total_check_count
    check_number = []
    self.jobs.each do |job|
      if job.parent_job_id.blank?
        check_number << job.check_number
      end
    end
    check_number.uniq!
    if check_number.nil?
      return 0
    else
      return check_number.size
    end
  end

  # Returns the Sum of all checks within the batch
  def slow_total_check_amount
    total_chk_amount = 0
    self.jobs.each do |job|
      check_amount = 0
      if job.parent_job_id.blank?
        check_amount = CheckInformation.find_by_job_id(job.id).check_amount if CheckInformation.find_by_job_id(job.id)
      end
      total_chk_amount += check_amount.to_f
    end
    return total_chk_amount
  end
  
  def total_check_amount
    CheckInformation.find_by_sql(["select sum(check_amount) as total_check_amount from check_informations c join jobs j on j.id = c.job_id join batches b on b.id = j.batch_id where b.id = ?", self.id]).first.total_check_amount.to_f
  end

  def totals
    total_amounts = CheckInformation.find_by_sql(["select sum(CASE WHEN (payment_method = 'CHK' or payment_method = 'OTH') THEN check_amount ELSE 0 END) as total_chk_amount, sum(CASE WHEN (payment_method = 'EFT' or payment_method = 'ACH') THEN check_amount ELSE 0 END) as total_eft_amount from check_informations c join jobs j on j.id = c.job_id join batches b on b.id = j.batch_id where b.id = ? and j.is_excluded = 0", self.id]).first
    return total_amounts.total_chk_amount, total_amounts.total_eft_amount
  end

  def get_total_index_file_amount
    total_index_file_amount = CheckInformation.find_by_sql(["select sum(IFNULL(index_file_check_amount, check_amount)) as total_index_file_check_amount from check_informations c join jobs j on j.id = c.job_id join batches b on b.id = j.batch_id where b.id = ?", self.id]).first
    return total_index_file_amount.total_index_file_check_amount
  end

  #Completed Batches list
  def self.completed_batches
    Batch.find(:all,
      :order => "status, comment desc, completion_time desc",
      :conditions => "(status = '#{BatchStatus::COMPLETED}')
                                and (To_days(now()) - To_days(completion_time)) <= 4")
  end

  def self.sum_check_amount batch_ids, status
    CheckInformation.sum(:check_amount, :joins=>",`jobs` j", 
      :conditions => ["j.id = check_informations.job_id AND j.batch_id in(?) AND j.job_status=?", batch_ids,status]).to_f
  end
  
  def least_eobs
    count_to_compare = self.jobs[0].count unless self.jobs[0].count.nil?
    self.jobs.each do |j|
      unless j.count.nil?
        if j.count < count_to_compare
          count_to_compare = j.count
        end
      else
        count_to_compare = 0
      end
    end
    return count_to_compare
  end
  
  # Filter wrappers
  def facility_for_filter
    self.facility.name
  end
  
  def client_for_filter
    self.facility.client.name
  end
  
  # Returns false unless the batch has been OUTPUT_READY
  # adding the status OUTPUT_GENERATED, EXCEPTION so that we can regenerate outputs
  def incomplete?
    ![BatchStatus::OUTPUT_READY, BatchStatus::OUTPUT_GENERATED, BatchStatus::OUTPUT_EXCEPTION].include?(status)
  end

  def excluded?
    non_excluded_jobs = jobs.select {|j| j.is_excluded == false}
    non_excluded_jobs.empty? ? true : false
  end
  
  # returns the original batch id by splitting batchid and batch date. 
  # For some facilities batch date is appended to batchid to avoid duplication. 
  # In output, we have to trim batch date and get the original batch id
  def real_batch_id
    begin
      if self.batchid.include?("_")
        batch_id_array = self.batchid.split('_')
        if batch_id_array.last.to_s.match(/^\d{8}$/)
          Date.strptime(batch_id_array.last, "%m%d%Y")
          self.batchid[0...-9]
        else
          self.batchid
        end
      else
        self.batchid
      end
    rescue
      self.batchid
    end
  end

  # Returns the images belonging to this batch
  def images_count
    images_count = 0
    jobs.each do |job|
      images_count += job.images_for_jobs.count
    end
    images_count
  end

  # Returns the checks belonging to this batch
  def checks
    checks = []
    jobs.each do |job|
      checks << job.check_informations.first
    end
    checks = checks.flatten.compact
  end

  # Returns the checks belonging to this batch
  def checks_having_payers
    checks = []
    jobs.each do |job|
      check = job.check_informations.first
      checks << check if !check.payer.blank?
    end
    checks = checks.flatten.compact
  end

  # Returns the EOBs (insurance and patient) belonging to this batch
  def eobs
    eobs = []
    checks.each do |check|
      eobs << check.eobs
    end
    eobs = eobs.flatten.compact
  end

  # Returns the sum of payment of all checks belonging to this batch
  def total_payment
    checks.inject(0.00){|sum, check| sum += check.check_amount.to_f}
  end

  def batches_within_same_deposit_date
    Batch.find_all_by_bank_deposit_date(bank_deposit_date)
  end

  def src_file_name
    site_code = facility.sitecode
    site_code = site_code.length > 3 ? site_code.slice(-3, 3) : site_code.rjust(3, '0')
    "#{date.strftime("%m%d")}" + cut.to_s + "#{site_code}" + '.' + "#{"%03d" % index_batch_number.to_i}"
  end

  def primary_output_files
    primary_output_file_formats = ['835_source', 'A37']
    output_activity_logs.all(:conditions => {:file_format => primary_output_file_formats})
  end
  
  # Returns the EDC Batch XML batch_set node
  def batch_xml(xml)    
    xml.batch(:ID => 1) do
      xml.tag!(:bat_date, date)
      xml.tag!(:bat_id, batchid)
      xml.tag!(:site_num, facility.sitecode.rjust(5, '0'))
      xml.tag!(:bat_time, (batch_time.strftime("%H:%M:%S") unless batch_time.blank?))
      xml.tag!(:chk_vol, (correspondence == true) ? 0 : checks.count)
      xml.tag!(:eob_vol, eobs.count)
      xml.tag!(:img_vol, images_count)
      xml.tag!(:total_pay_amt, sprintf('%.02f', total_payment.to_f))
      xml.tag!(:lockbox, lockbox)
      xml.tag!(:bank_bat_id, index_batch_number)
      xml.tag!(:bat_type, (correspondence == true) ? 'C' : 'P')
      xml.tag!(:src_file, src_file_name)
      xml.tag!(:process_dt, (created_at.strftime("%Y-%m-%d %H:%M:%S")))
      xml.tag!(:rework, '0')
    end
  end

  # Returns the EDC Batch XML doc_set node
  def doc_xml(xml)
    primary_output_files.each_with_index do |output, i|
      xml.doc(:ID => i + 1) do
        xml.tag!(:batch_attrib, 1)
        xml.tag!(:doc_cont_cd, doc_cont_cd(output))
        xml.tag!(:subtype_cd, 'PLN')
        xml.tag!(:filename, output.file_name)
        xml.tag!(:file_size, output.file_size)
      end
    end
    xml
  end

  def doc_cont_cd(output_file)
    if output_file.file_format == '835_source'
      'EDC'
    elsif output_file.file_format == 'A37'
      'LLC'
    end
  end

  def self.count_of_urgent_batches_for_payer(payer_id, threshold_time_to_tat)
    self.count(:all,
      :include => [{:jobs => {:check_informations => :payer}} ], :conditions => [
        "batches.status = '#{BatchStatus::COMPLETED}' and batches.output_835_generated_time is NULL and
         jobs.job_status = '#{JobStatus::COMPLETED}' and payers.id = ? and
         (SELECT NOW() >= DATE_SUB(batches.completion_time, INTERVAL #{threshold_time_to_tat} HOUR )) ",
        payer_id])
  end

  
  def self.update_batch_total_charges(inbound_file_information)
    batches = Batch.where("inbound_file_information_id =#{inbound_file_information.id}")
    batches.each do |batch|
      total_excluded_amount = 0
      check_informations = CheckInformation.joins(" INNER JOIN jobs ON check_informations.job_id = jobs.id").where("jobs.batch_id = #{batch.id} ")
      total_check_amount = check_informations.sum("check_amount")
      payers_to_exclude = batch.facility.excluded_payers.collect(&:id)
      check_informations.each do |check_payer|
        check_payer_id = check_payer.get_payer.id unless check_payer.get_payer.blank?
        if payers_to_exclude.include?(check_payer_id)
          total_excluded_amount += check_payer.check_amount
        end
      end
      batch.update_attributes(:total_charge=>total_check_amount,:total_excluded_charge=>total_excluded_amount)
    end    
  end


  # This will make the batches to be available for facility wise auto job allocation
  # Sets the the facility_wise attribute and unset the payer_wise attribute
  # Input :
  # batch_ids : IDs of batches in an array
  # Output :
  # Number of records the query updated
  def self.add_to_facility_wise_allocation_queue(batch_ids)
    self.where(:id => batch_ids).update_all(:facility_wise_auto_allocation_enabled => true,
      :payer_wise_auto_allocation_enabled => false, :updated_at => Time.now)
  end

  # This will make the batches to be available for payer wise auto job allocation
  # Sets the the payer_wise attribute and unset the facility_wise attribute
  # Input :
  # batch_ids : IDs of batches in an array
  # Output :
  # Number of records the query updated
  def self.add_to_payer_wise_allocation_queue(batch_ids)
    self.where(:id => batch_ids).update_all(:facility_wise_auto_allocation_enabled => false,
      :payer_wise_auto_allocation_enabled => true, :updated_at => Time.now)
  end

  # This will remove the batches from auto job allocation process
  # Unsets both facility_wise and payer_wise attribute
  # These bacthes are to be manually allocated for processing
  # Input :
  # batch_ids : IDs of batches in an array
  # Output :
  # Number of records the query updated
  def self.remove_from_allocation_queue(batch_ids)
    self.where(:id => batch_ids).update_all(:facility_wise_auto_allocation_enabled => false,
      :payer_wise_auto_allocation_enabled => false, :updated_at => Time.now)
  end
  
  def self.enable_ocr_job_allocation(batch_ids)
    self.where(:id => batch_ids).update_all(:ocr_job_auto_allocation_enabled => true, :updated_at => Time.now)
  end

  def self.disable_ocr_job_allocation(batch_ids)
    self.where(:id => batch_ids).update_all(:ocr_job_auto_allocation_enabled => false, :updated_at => Time.now)
  end

  # This will make the status of batches from 'COMPLETED' to 'OUTPUT_READY'
  # Input :
  # batch_ids : IDs of batches in an array
  # Output :
  # Number of records the query updated
  def self.change_status_to_output_ready(batch_ids)
    self.where(:id => batch_ids, :status => "#{BatchStatus::COMPLETED}").each do |batch|
      batch.update_attributes(:status => "#{BatchStatus::OUTPUT_READY}")
    end
  end

  # get_all the batches which have atleast one job in completed status
  # argument: batch_ids
  #
  def self.batches_with_qualified_jobs(batch_ids)
    self.joins(", jobs ").where(" batches.id = jobs.batch_id AND 
                jobs.job_status = '#{JobStatus::COMPLETED}' AND batches.id in (#{batch_ids.join})").select(" DISTINCT batches.*")

  end

  # Provides you the Internal TAT for the batch in time
  # Internal TAT for the batch in time  = Arrival Time + Client Internal TAT in hours
  # Input :
  # internal_tat : client's internal TAT in hours
  # Output :
  # Internal TAT for the batch in time
  def batch_internal_tat(internal_tat)
    internal_tat ||= facility.client.internal_tat
    if !internal_tat.blank? && !arrival_time.blank?
      arrival_time  + internal_tat * 3600
    end
  end
  
  # Provides you the Client TAT for the batch in time
  # Client TAT for the batch in time = Arrival Time + Client TAT in hours
  # Input :
  # client_tat : client's TAT in hours
  # Output :
  # Client TAT for the batch in time
  def batch_client_tat(client_tat)
    client_tat ||= facility.client.tat
    if !client_tat.blank? && !arrival_time.blank?
      arrival_time  + client_tat * 3600
    end
  end

  # Provides you the Facility TAT for the batch in time
  # Facility TAT for the batch in time = Arrival Time + Facility TAT in hours
  # Input :
  # client_tat : client's TAT in hours
  # Output :
  # Facility TAT for the batch in time
  def batch_facility_tat(facility_tat)
    facility_tat ||= facility.tat
    if !facility_tat.blank? && !arrival_time.blank?
      arrival_time  + facility_tat.to_i * 3600
    end
  end

  # Provides the Allocation Type
  # Allocation Type can be 'Facility wise', 'Payer wise' or 'Manual'
  # Output : Allocation Type based on the condition
  def allocation_type
    if facility_wise_auto_allocation_enabled
      'Facility Wise'
    elsif payer_wise_auto_allocation_enabled
      'Payer Wise'
    else
      'Manual'
    end
  end

  def set_qa_status
    all_jobs_qa_statuses = jobs.map(&:qa_status)
    allocated = all_jobs_qa_statuses.include?(QaStatus::ALLOCATED)
    processing = all_jobs_qa_statuses.include?(QaStatus::PROCESSING)
    new = all_jobs_qa_statuses.compact.uniq.length == 1 && all_jobs_qa_statuses.include?(QaStatus::NEW)
    completed = !all_jobs_qa_statuses.include?(QaStatus::ALLOCATED) &&
      !all_jobs_qa_statuses.include?(QaStatus::PROCESSING) &&
      all_jobs_qa_statuses.include?(QaStatus::COMPLETED)
    if new
      self.qa_status = QaStatus::NEW
    elsif processing
      self.qa_status = QaStatus::PROCESSING
    elsif allocated
      self.qa_status = QaStatus::ALLOCATED
    elsif completed
      self.qa_status = QaStatus::COMPLETED
    end
    self.save if self.changed?
  end

  def batch_group type
    facility_configs = FacilityOutputConfig.where(:facility_id => facility_id, :report_type => type)
    output_grouping = facility_configs.sort_by {|fc| fc.grouping_weight}.last.grouping
    output_grouping = output_grouping.downcase.gsub(" ", "_")
    
    if ['by_batch_date', 'by_cut','by_lockbox_cut','by_cut_and_payerid',
        'by_payer_id_by_batch_date','by_payer_by_batch_date','by_cut_and_extension', 'nextgen_grouping', 'by_lockbox_and_date'].include? output_grouping
      Batch.send("#{output_grouping}_group", self)
    else
      Batch.by_batch_group self
    end
  end

  def batch_group_client_level type
    client_configs = ClientOutputConfig.where(:client_id => client_id, :report_type => type)
    unless client_configs.blank?
      oplog_grouping = client_configs.sort_by {|c| c.grouping_weight}.last.operation_log_config[:group_by]["0"]

      oplog_grouping = oplog_grouping.downcase.gsub(" ", "_")

      if ['batch_date', 'nextgen', 'client_and_deposit_date'].include? oplog_grouping
        Batch.send("#{oplog_grouping}_group_for_client_level", self)
      else
        Batch.batch_group_for_client_level self
      end
    end
  end

  # Returns the total provider_adjustment_amount of a batch
  def get_provider_adjustment_amount
    net_plb_amt_of_batch = 0
    conditions = "jobs.is_excluded = 0
      and (check_informations.payment_method = 'CHK' or check_informations.payment_method = 'OTH')"
    jobs = Batch.select("provider_adjustments.id as plb_id, provider_adjustments.amount as plb_amt"). \
      where(conditions).\
      joins("LEFT OUTER JOIN jobs ON jobs.batch_id = #{self.id} \
                    LEFT OUTER JOIN check_informations ON check_informations.job_id = jobs.id \
                    LEFT OUTER JOIN provider_adjustments ON provider_adjustments.job_id = jobs.id").
      group("provider_adjustments.id").each do |job| net_plb_amt_of_batch += job.plb_amt.to_f end
    net_plb_amt_of_batch
  end

  def get_lockbox_number
    if batchid.include?("_")
      batch_id_array = batchid.split('_')
      lockbox_number = batch_id_array[1].to_i
      lockbox_number
    end
  end

  def create_output_notification_file(ack_latest_count, processed_batch_id = nil, group_batchids = nil)
    begin
      self.reload
      selected_output_activity_logs = OutputActivityLog.
        select("id,file_location,file_name,file_format,start_time, end_time, batch_id")
      .where("ack_latest_count=#{ack_latest_count} and file_format <> '835_source'")
      .order("id desc")
      unless selected_output_activity_logs.blank?
        notification_params = []
        count = 0
        file_names = selected_output_activity_logs.map(&:file_name).uniq
        file_names.each do |file_name|
          id_array = []
          batch_id_array = []
          selected_output_activity_logs.each do |output_activity_log|
            if output_activity_log.file_name == file_name
              batch_id_array << output_activity_log.batch_id
              id_array << output_activity_log.id
            end
          end
          
          id_array.delete_at(0)
          selected_output_activity_logs.delete_if do |record|
            !id_array.blank? && id_array.include?(record.id)
          end
          
          selected_output_activity_logs.each do |output_activity_log|
            if output_activity_log.file_name == file_name
              notification_params[count] = {}
              notification_params[count][:file_path] = output_activity_log.file_location
              notification_params[count][:file_name] = output_activity_log.file_name
              notification_params[count][:file_format] = output_activity_log.file_format
              if batch_id_array.length > 1
                batch_names = Batch.find(batch_id_array).map(&:batchid)
                notification_params[count][:batch_id] = batch_id_array.join(';')
                notification_params[count][:batch_name] = batch_names.join(';')
              else
                batch_name = Batch.find(output_activity_log.batch_id).batchid
                notification_params[count][:batch_id] = output_activity_log.batch_id
                notification_params[count][:batch_name] = batch_name
              end
              notification_params[count][:output_start_time] = output_activity_log.start_time
              notification_params[count][:output_end_time] = output_activity_log.end_time
              notification_params[count][:client_name] = self.facility.client.name
              notification_params[count][:facility_name] = self.facility.name
            end
          end
          count +=1
        end
        NotificationGenerator.create_notification_file(ack_latest_count, notification_params)
      end
      Batch.notify_successful_output_generation(processed_batch_id, group_batchids) if processed_batch_id
    rescue => e
      puts e.message
      puts e.backtrace
    end
  end

  def generate_output
    if facility.automate_output_generation && ready_for_output_generation
      batch_ids = @batch_group.map(&:id)
      tolerance_time = facility.generation_tolerance || 0
      self.delay({:run_at => tolerance_time.minutes.from_now, :queue => 'generating_output'}).check_and_generate_output(batch_ids)
      Output835.log.info "Batches #{batch_ids.join(',')} are moved to delayed jobs queue for output generation"
    end
  end

  def check_and_generate_output(batch_ids)
    if ready_for_output_generation
      batch_ids = @batch_group.collect(&:id)
      Batch.delay({:queue => 'generating_output'}).start_generating_output(batch_ids, @batch_group, self.id, nil, nil, true)
    else
      Output835.log.info "Output Generation of batches #{batch_ids.join(',')} are skipped"
    end
  end

  def ready_for_output_generation
    if eligible_for_output_generation?
      @batch_group = self.batch_group('Output').to_a
      !@batch_group.detect { |batch| batch.incomplete? }
    end
  end

  #below class methods will run using delayed jobs and class method definition should be as follows
  class << self
    def start_generating_output(batch_ids, batch_group, id, url, current_user, automated = nil)
      begin
        batch = Batch.find(id)
        facility_details = batch.facility.details
        batch_id = batch.batchid
        group_batchids = Batch.where(:id => batch_ids).map(&:batchid)
        ack_latest_count = OutputActivityLog.get_latest_number
        check_segregator = CheckGrouper.new(batch_group, ack_latest_count, current_user)
        check_segregator.segregate_checks
        OperationLog::Generator.new(batch_ids, ack_latest_count, current_user).generate
        @message = "Output generated successfully"
      rescue Exception => e
        Batch.where("id in (?)", batch_ids).update_all(:status => BatchStatus::OUTPUT_EXCEPTION, :updated_at => Time.now)
        et_params = {} #error_trace_params
        et_params[:last_check] = check_segregator.try(:last_check)
        et_params[:last_job] =  et_params[:last_check].try(:job)
        et_params[:last_batch] = et_params[:last_job].try(:batch)
        et_params[:last_eob] = check_segregator.try(:last_eob)
        et_params[:url] = url
        emails = Batch.get_recipient_emails
        subject = "Output generation(delayed job) of #{batch_id} failed."
        RevremitMailer.notify_output_generation_status(emails, subject, batch_id, group_batchids, e, et_params, false).deliver
      else
        Batch.where("id in (?)", batch_ids).update_all(:status => BatchStatus::OUTPUT_GENERATED, :output_835_generated_time => Time.now, :updated_at => Time.now)

        if facility_details[:output_notification_file] == true
          if automated
            tolerance_time = batch.facility.posting_tolerance || 0
            batch.delay({:run_at => tolerance_time.minutes.from_now, :queue => 'generating_output'}).create_output_notification_file(ack_latest_count, batch_id, group_batchids)
          else
            batch.create_output_notification_file(ack_latest_count, batch_id, group_batchids)
          end
        end
      end 
    end

    def notify_successful_output_generation(batch_id, group_batchids)
      emails = Batch.get_recipient_emails
      subject = "Output generation(delayed job) of #{batch_id} completed."
      RevremitMailer.notify_output_generation_status(emails, subject, batch_id, group_batchids, nil, nil, true).deliver
    end

    def mark_output_generating batch_ids
      Batch.update_all({:output_835_start_time => Time.now, :status => BatchStatus::OUTPUT_GENERATING, :updated_at => Time.now}, {:id => batch_ids})
    end
    
    def get_recipient_emails
      email_cnf = YAML::load(File.open("#{Rails.root}/config/references.yml"))
      email_cnf['email']['output_generation_status']['notification']
    end
    #    handle_asynchronously :start_generating_output, :queue => 'generating_output'
  end

  def qa_rejected_jobs
    self.jobs.where(:job_status => 'QA Rejected')
  end
  
  def set_batch_type
    check_amounts  = check_informations.map(&:check_amount).map(&:to_f)
    self.batch_type = if check_amounts.blank?
      'Correspondence'
    elsif check_amounts.uniq.count == 1 and check_amounts.include?(0)
      'Correspondence'
    elsif !check_amounts.include?(0)
      'Payment'
    elsif check_amounts.uniq.count > 1 and check_amounts.include?(0)
      'All'
    else
      'All'
    end
    self.save
  end

  def self.build_hash_of_batch_attribute(batches, attribute)
    hash_of_batch_attribute = {}
    batches.each do |batch|
      hash_of_batch_attribute[batch.id] = batch.send(attribute)
    end
    hash_of_batch_attribute
  end


  # 835 Output Related ... Need to move to seperate module

  def get_batch_date(format)
    self.date.strftime(format)
  end

  def get_batchid(length)
    self.batchid.to_s.first(length.to_i)
  end
  # End of 835 Output related code #
  end
  
