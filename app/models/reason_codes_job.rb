class ReasonCodesJob < ActiveRecord::Base  
  belongs_to :reason_code, :include => [:ansi_remark_codes, :reason_code_set_name, 
    {:reason_codes_clients_facilities_set_names => :hipaa_code} ]
  belongs_to :job, :foreign_key => 'parent_job_id'
  # to associate columns that are read by the OCR with their metadata column "details"
  #Fields listed below will have their meta data stored in "details"
  has_details :reason_codes
   
  def get_hipaa_code_of_reason_code(job, reason_code, options = {})

    payer = options[:payer]
    client = options[:client]
    facility = options[:facility]
    
    facility ||= job.batch.facility
    client ||= facility.client
    payer ||= job.check_information.payer
    if !payer.blank?
      reason_code_crosswalk = ReasonCodeCrosswalk.new(payer, nil, client, facility)
      reason_code_crosswalk.get_crosswalked_codes_for_reason_code(reason_code)
    end
  end
  
  #This is for association of default reason codes with jobs.
  def self.create_default_records(default_reason_code_id_list, parent_job_id)
    available_rc_ids = select("reason_code_id").where(["reason_code_id in (?) and parent_job_id = ?", default_reason_code_id_list, parent_job_id]).collect(&:reason_code_id)
    
    new_rc_jobs = []
    (default_reason_code_id_list - available_rc_ids).each do | r |
      new_rc_jobs << new(:reason_code_id => r, :parent_job_id => parent_job_id)
    end
    import new_rc_jobs unless new_rc_jobs.blank?
    
  end

  def self.create_default_records_OLD(default_reason_code_id_list, parent_job_id)
    unless default_reason_code_id_list.blank?
      default_reason_code_id_list.each do |reason_code_id|
        self.find_or_create_by_reason_code_id_and_parent_job_id(reason_code_id, parent_job_id)
      end
    end
  end

  def self.get_valid_reason_codes parent_job_id
    valid_reason_codes = []
    reason_code_ids = self.find(:all, :select => "reason_code_id", 
      :conditions => ["parent_job_id = ? ", parent_job_id], :order => "id DESC")
    reason_code_ids = reason_code_ids.map(&:reason_code_id)
    actual_reason_codes = ReasonCode.find(reason_code_ids)
    
    reason_code_ids.each do |id|
      actual_reason_codes.each do |rc|
        if rc.id == id
          if !rc.active && !rc.replacement_reason_code_id.blank?            
            reason_code_record = rc
            replacement_reason_code_id = rc.replacement_reason_code_id
            if replacement_reason_code_id.present?
              active_record = ReasonCode.find_active_record(rc, replacement_reason_code_id)
              reason_code_record = active_record if active_record.present?
            end
            valid_reason_codes << reason_code_record
          else
            valid_reason_codes << rc
          end
          break
        end
      end
    end
    valid_reason_codes.uniq
  end

  def self.get_reason_codes_for_uc_auto_complete parent_job_id
    reason_code_ids = self.where(:parent_job_id => parent_job_id).map(&:reason_code_id)
    rcs_for_auto_complete = ReasonCode.get_vaild_reason_codes reason_code_ids
    rcs_for_auto_complete.each_with_index do |rc, i|
      rc.id = reason_code_ids[i]
    end
    rcs_for_auto_complete
  end
end
