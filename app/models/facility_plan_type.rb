class FacilityPlanType < ActiveRecord::Base
  belongs_to :payer
  belongs_to :client
  belongs_to :facility

  def self.get_plan_type_record_for_particular_level(payer_id, client_id = nil, facility_id = nil)
    if !payer_id.blank? && !client_id.blank? && !facility_id.blank?
      condition = "payer_id = #{payer_id} AND client_id = #{client_id} AND facility_id = #{facility_id}"
    elsif !payer_id.blank? && !client_id.blank?
      condition = "payer_id = #{payer_id} AND client_id = #{client_id} AND facility_id IS NULL"
    end
    if !condition.blank?
      self.select('plan_type').where(condition).limit(1)
    end
  end

  def self.get_client_or_site_specific_plan_type(payer_id, client_id = nil, facility_id = nil)
    priority_record = nil
    plan_type_records = self.get_plan_type_record_for_all_levels(payer_id, client_id, facility_id)
    plan_type_records.each do |plan_type_record|
      if !payer_id.blank? && !client_id.blank? && !facility_id.blank? &&
          plan_type_record.payer_id == payer_id.to_i && plan_type_record.client_id == client_id.to_i &&
          plan_type_record.facility_id == facility_id.to_i
        priority_record = plan_type_record
        break
      end
    end
    if priority_record.blank?
      plan_type_records.each do |plan_type_record|
        if !payer_id.blank? && !client_id.blank? && plan_type_record.facility_id.blank?
          plan_type_record.payer_id == payer_id.to_i && plan_type_record.client_id == client_id.to_i
          priority_record = plan_type_record
          break
        end
      end
    end
    priority_record
  end

  def self.get_plan_type_record_for_all_levels(payer_id, client_id = nil, facility_id = nil)
    if !payer_id.blank? && !client_id.blank?
      self.where("payer_id = #{payer_id} AND client_id = #{client_id}")
    end
  end
  
end
