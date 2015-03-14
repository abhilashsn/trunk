# Responsible for allocating jobs automatically to processor(s)
# Sweeps through all the jobs and fetch appropriate one to be allocated to appropriate processor(s)
module JobAllocator

  # The method which is visible to outside for Auto Job Allocation
  # This runs for an array of user.
  # For each user, an object of class AutoJobAllocator will be initiated and
  # there will be a delayed job worker allocating jobs for user.
  # *********************    RAILS_ENV=production script/delayed_job --queue=job_allocation -i=2 start  *************
  # When there is more than one user, they are ordered by their last_job_completed_at time
  # Input :
  #  user_ids : IDs of users
  def self.allocate_facility_wise(user_ids, facility_wise_queue_updated = nil)
    if !user_ids.blank?
      if user_ids.length > 1
        get_user_ids_in_the_order_of_work_completion(user_ids)
      end
      user_ids.each do |user_id|
        allocator = AutoJobAllocator.new
        if facility_wise_queue_updated
          allocator.delay(:queue => 'job_allocation').allocate_facility_wise(user_id)
        else
          idle_processor = IdleProcessor.find_by_user_id(user_id)
          if idle_processor.blank?
            allocator.allocate_facility_wise(user_id)
          end
        end
      end
    end
  end

  # This will order the user_ids in the ascending order of their last_job_completed_at time
  # Input :
  #  user_ids : IDs of user
  # Output :
  #  user_ids : Ids of users in the ascending order of last_job_completed_at time
  def self.get_user_ids_in_the_order_of_work_completion(user_ids)
    users = get_processors(user_ids)
    user_ids = users.map(&:id)
  end

  # This method obtaines the user records in the ascending order of last_job_completed_at time
  # Input :
  #  user_ids : IDs of user
  # Output :
  #  user records : User records in the ascending order of last_job_completed_at time
  def self.get_processors(user_ids)
    User.select("users.id AS id").
      where("users.id IN (#{user_ids.join(',')})").
      order("users.last_job_completed_at ASC")
  end

  # Responsible of allocating one job for one user
  class AutoJobAllocator
    
    attr_accessor :processor_id, :facility_ids, :job_id, :batch_id

    # This method allocates one job for one user
    # Input :
    #  user_id : ID of user
    def allocate_facility_wise(user_id)
      get_processor_for_facility_wise_allocation(user_id)
      if !processor_id.blank?
        find_job_and_allocate
      else
        allocation_log.info "Auto Job Allocator for user ID #{user_id} : Cannot find the user having ID in (#{user_id}) "
      end
    end

    # Logger for Auto Job Allocation
    def allocation_log
      @allocation_logger ||= RevRemitLogger.new_logger(LogLocation::ALLOCATIONLOG)
    end

    private

    # Returns the records for eligible processor having PK as user_id
    # The user records are joined with facilities_users to obtain that many records of user
    # This will set the instance variables of processor_id and facility_ids
    # Input :
    #  user_id : ID of user
    # Output :
    #  Sets the instance variables of processor_id and facility_ids
    def get_processor_for_facility_wise_allocation(user_id)
      user_records = User.select("users.id AS id,
                   facilities_users.facility_id AS facility_id").
        joins("INNER JOIN facilities_users ON facilities_users.user_id = users.id \
               INNER JOIN facilities ON facilities_users.facility_id = facilities.id \
               INNER JOIN roles_users ON roles_users.user_id = users.id
               INNER JOIN roles ON roles.id = roles_users.role_id").
        where("users.id IN (#{user_id}) AND users.login_status = 1 AND users.auto_allocation_enabled = 1 AND \
              facilities_users.eligible_for_auto_allocation = 1 AND \
              users.allocation_status = 0 AND roles.name = 'processor'")
      if !user_records.blank?
        @facility_ids = []
        user_records.each do |record|
          @processor_id ||= record.id
          @facility_ids << record.facility_id
        end
      else
        allocation_log.info "Auto Job Allocator for user ID #{user_id} : User is not eligible"
      end
    end

    # This is responsible for finding an eligible job and associating with the processor
    def find_job_and_allocate
      get_job_for_facility_wise_allocation
      if !job_id.blank?
        allocate
      end
    end

    # This obtains the eligble job for allocating to a processor
    # This sets the instance variables of job_id and batch_id
    # If there are no jobs found for the processor then the processor is listed in idle_processors
    def get_job_for_facility_wise_allocation
      job_condition = "((batches.ocr_job_auto_allocation_enabled = 1 AND \
          micr_line_informations.is_ocr = 1 AND jobs.is_ocr = 1) OR \
       (batches.facility_wise_auto_allocation_enabled = 1 AND \
          (jobs.is_ocr = 0 OR jobs.is_ocr IS NULL))) AND \
        (batches.status = '#{BatchStatus::NEW}' OR batches.status = '#{BatchStatus::PROCESSING}') AND \
        jobs.job_status = '#{JobStatus::NEW}' AND jobs.processor_id is NULL AND jobs.is_excluded = 0"
      job = Job.select("jobs.id AS id,
               batches.id AS batch_id").
        joins("INNER JOIN batches ON batches.id = jobs.batch_id \
            INNER JOIN facilities ON facilities.id = batches.facility_id \
            LEFT JOIN check_informations ON CASE WHEN parent_job_id IS NULL THEN jobs.id ELSE parent_job_id END =check_informations.job_id \
            LEFT OUTER JOIN micr_line_informations ON micr_line_informations.id = check_informations.micr_line_information_id").
        where("#{job_condition} AND \
               batches.facility_id in (#{facility_ids.join(',')})").
        order("batches.priority ASC, batches.target_time ASC, batches.id, batches.facility_id ").
        limit(1).first
      if !job.blank?
        @job_id = job.id
        @batch_id = job.batch_id
      else
        allocation_log.info "Auto Job Allocator for user ID #{processor_id} : No jobs available are for the processor. Hence the user is listed as idle processor "
        IdleProcessor.find_or_create_by_user_id(processor_id)
      end
    end

    # This is responsible for associating the eligible job to a eligible processor
    # This updates the Job, Batch and User record
    # If the update fails then another job is to be found out
    def allocate
      no_of_records_updated = Job.where(:id => job_id, :processor_id => nil).
        update_all(:processor_id => processor_id, :processor_status => "#{ProcessorStatus::ALLOCATED}",
        :job_status => "#{JobStatus::PROCESSING}", :updated_at => Time.now)
      if no_of_records_updated == 1
        update_user
        update_batch
      else
        find_job_and_allocate
      end
    end

    # This updates the user record for the eligible processor
    def update_user
      User.where(:id => processor_id).update_all(:allocation_status => 1, :updated_at => Time.now)
    end

    # This updates the batch record of the eligible job
    def update_batch
      batch = Batch.find(batch_id)
      batch.update_status
      batch.expected_completion_time = batch.expected_time
      batch.save
    end
  
  end

end
