class FacilitiesUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :facility
  
  def self.is_facility(userid)
    facility = FacilitiesUser.find_by_user_id(userid).facility_id
    facility_name = Facility.find(facility).name  
    return facility_name    
  end

  # Stores count of EOBs processed by the processor for a facility
  # This is to be called after the processor completes the processing of the check
  # Input :
  # user_id : User Id
  # facility_id : Facility Id
  # count_of_eobs : Number of EOBs processed by user
  # Output :
  # Returns the object of FacilitiesUser for the processor and client
  def self.save_eobs_processed(user_id, facility_id, count_of_eobs)
    count_of_eobs = count_of_eobs.to_i
    if count_of_eobs > 0 && !user_id.blank? && !facility_id.blank?
      user_related_client_record = self.find_by_user_id_and_facility_id(user_id, facility_id)
      if !user_related_client_record.blank?
        total_eobs_processed_for_client = user_related_client_record.eobs_processed.to_i + count_of_eobs
        user_related_client_record.eobs_processed = total_eobs_processed_for_client
        user_related_client_record.save
        user_related_client_record
      else
        self.create(:facility_id => facility_id, :user_id => user_id, :eobs_processed => count_of_eobs)
      end
    end
  end

  def self.update_facilities_to_user(facility_ids_to_update, processor_id, allocation_flag )
    unless facility_ids_to_update.blank?
      self.where(:user_id => processor_id, :facility_id => facility_ids_to_update).
        update_all(:eligible_for_auto_allocation => allocation_flag)
    end
  end

  def self.create_facilities_to_user(facility_ids_to_create, processor_id, allocation_flag )
    facility_user_create = []
    if !facility_ids_to_create.blank? && allocation_flag != false
      facility_ids_to_create.each do |facility_id|
        facility_user_create << self.new(:user_id => processor_id,
          :facility_id => facility_id,
          :eligible_for_auto_allocation => true)
      end
      self.import facility_user_create
    end
  end

end
