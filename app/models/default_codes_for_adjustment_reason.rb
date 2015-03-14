class DefaultCodesForAdjustmentReason < ActiveRecord::Base
  
  belongs_to :facility
  belongs_to :hipaa_code
  validates_presence_of :adjustment_reason
  validates_presence_of :group_code

  def self.create_or_update(facility_id, parameters = {})
    default_adjustment_code_records_hash = get_default_codes_for_adjustment_reason(facility_id)
    parameters.each do |adjustment_reason, values|  
      default_adjustment_code_record = default_adjustment_code_records_hash[adjustment_reason]
      default_adjustment_code_record = self.new if default_adjustment_code_record.blank?
      default_adjustment_code_record.save_record(adjustment_reason, facility_id, values)
    end
  end

  def self.get_default_codes_for_adjustment_reason(facility_id)
    default_adjustment_code_records_hash = {}
    default_adjustment_code_records = self.where(:facility_id => facility_id)
    default_adjustment_code_records.each do | record |
      default_adjustment_code_records_hash[record.adjustment_reason.to_sym] = record
    end
    default_adjustment_code_records_hash
  end

  def save_record(adjustment_reason, facility_id, parameter_values = [])
    hipaa_adjustment_code = parameter_values[0]
    hipaa_code_id = self.class.get_hipaa_code_id_to_associate(hipaa_adjustment_code)
    self.adjustment_reason = adjustment_reason.to_s
    self.hipaa_code_id = hipaa_code_id
    self.group_code = parameter_values[1].to_s.upcase
    self.enable_crosswalk = parameter_values[2]
    self.facility_id = facility_id
    if self.changed?
      self.save
    end
  end

  def self.get_hipaa_code_id_to_associate(hipaa_adjustment_code)
    if hipaa_adjustment_code.present?
      standard_hipaa_codes_hash = get_standard_hipaa_codes
      hipaa_code_id = standard_hipaa_codes_hash[hipaa_adjustment_code]
      if hipaa_code_id.blank?
        hipaa_code_record = HipaaCode.create(:hipaa_adjustment_code => hipaa_adjustment_code.to_s.upcase)
        hipaa_code_id = hipaa_code_record.id
        hipaa_code_record.add_to_hipaa_codes_global_variable
      end
    end
    hipaa_code_id
  end

  def self.get_standard_hipaa_codes
    standard_hipaa_codes_hash = {}
    $HIPAA_CODES.each do |id_and_code_and_description|
      standard_hipaa_codes_hash["#{id_and_code_and_description[1]}"] = id_and_code_and_description[0]
    end
    standard_hipaa_codes_hash
  end
  
end
