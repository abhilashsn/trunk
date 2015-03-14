class InboundFileInformation < ActiveRecord::Base
  has_many :batches
  has_many :eras
  belongs_to :facility
  belongs_to :client
  belongs_to :revremit_exception
  
  def update_batch_loading_estimates
    if status == InboundStatus::FILE_ARRIVED
      load_start_time = Time.now
      load_end_time = Time.now + ((size.to_i/10000)*7).to_i
      update_attributes({:status => InboundStatus::BATCH_LOADING, :load_start_time => load_start_time, :estimated_load_end_time => load_end_time})
    end
  end

  def update_claim_loading_estimates        
    if status == InboundStatus::FILE_ARRIVED
      load_start_time = Time.now
      load_end_time = Time.now + ((size.to_i/10000)*7).to_i
      update_attributes({:status => InboundStatus::CLAIM_LOADING, :load_start_time => load_start_time, :estimated_load_end_time => load_end_time})
    end
  end


  def update_cut
    Batch.where(:inbound_file_information_id => self.id).update_all(:cut => self.cut, :updated_at => Time.now)
    update_effective_tat
    null_file_check
  end

  def null_file_check
    if self.batches.present? && self.batches.count == 1
      if self.batches.first.correspondence.nil? && self.batches.first.index_batch_number == "0"
        self.update_attribute(:is_nullfile, 1)
      end
    end
  end
  
  def update_effective_tat 
    if self.effective_tat_date.nil? && self.facility_id && self.arrival_time
      facility = self.facility
      tat_in_hours = facility.tat
      grouping = facility.facility_output_configs.where("eob_type = 'Insurance Eob'").first.grouping
      puts grouping
      if grouping == 'By Batch Date'
        max_arrival_time = InboundFileInformation.where("facility_id = #{self.facility_id} AND batchdate = '#{self.batchdate}'
                                             AND status != '#{InboundStatus::FILE_PENDING}' AND file_type = 'LOCKBOX' ").order('arrival_time DESC')
        if !max_arrival_time.blank?
          max_arrival_time = max_arrival_time.first.arrival_time
        else
          max_arrival_time = self.arrival_time
        end
        effective_tat = max_arrival_time + tat_in_hours.to_i.hour
        InboundFileInformation.update_all( {:effective_tat_date => effective_tat, :updated_at => Time.now},
          "facility_id = #{self.facility_id} AND batchdate = '#{self.batchdate}'
                                             AND status != '#{InboundStatus::FILE_PENDING}' AND file_type = 'LOCKBOX' ")
      else
        self.update_attribute("effective_tat_date", "#{self.arrival_time + tat_in_hours.to_i.hour}")      
      end
    end
  end

  #this methods is called when the batch has completed loading, to record status and load_end_time
  def mark_completed_loading
    self.update_attributes({:load_end_time => Time.now(), :status=>InboundStatus::BATCH_LOADED})
  end


  def mark_exception(revremit_exception)
    if self.status == InboundStatus::BATCH_LOADING        
      self.update_attributes({:status=>InboundStatus::FILE_EXCEPTION, :revremit_exception_id=>revremit_exception.id})
    end
  end
  
  def mark_batch_loading_exception exception_type, system_exception
    revremit_exception = self.revremit_exception || RevremitException.new
    revremit_exception.update_attributes({:exception_type => exception_type, :system_exception => system_exception})
    self.update_attributes({:status => InboundStatus::FILE_EXCEPTION,:revremit_exception_id => revremit_exception.id })
  end

 
  # Creates reacords for report_check_informations.
  # report_check_informations is a table purely meant for fetching data directly.
  # While creating checks and  jobs for a batch, their informations as given below are stored in this table.
  # Information stored : batch_id, job_id, check_information_id, image_count, check_amount
  # This is written in SQL to speed up the batch loading process.
  def associate_to_report_check_informations
    query = "
            INSERT INTO report_check_informations (batch_id, job_id, check_information_id,
             image_count, check_amount, created_at, updated_at)
            SELECT
              batches.id AS batch_id,
              jobs.id AS job_id,
              check_informations.id AS check_information_id,
              COUNT( DISTINCT client_images_to_jobs.images_for_job_id) AS image_count,
              check_informations.check_amount AS check_amount,
              NOW() AS created_at, NOW() updated_at
            FROM batches
            INNER JOIN jobs ON jobs.batch_id = batches.id
            INNER JOIN check_informations ON check_informations.job_id = jobs.id
            INNER JOIN client_images_to_jobs ON client_images_to_jobs.job_id = jobs.id
            WHERE inbound_file_information_id = #{id}
            GROUP BY batch_id, job_id, check_information_id
    "
    logger.info "The query to insert data to report_check_informations as follows "
    logger.info "#{query}"
    self.connection.execute(query)
  end

end
