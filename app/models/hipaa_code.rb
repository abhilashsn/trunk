class HipaaCode < ActiveRecord::Base
  has_many :reason_codes_clients_facilities_set_names
  has_many :default_codes_for_adjustment_reasons
  validates_uniqueness_of :hipaa_adjustment_code
  validates_presence_of :hipaa_adjustment_code

  def self.map_hipaa_code(hipaa_code)
    self.find_by_hipaa_adjustment_code(hipaa_code)
  end
  # The method 'qualified_for_deletion?' is a Predicate Method.
  # The Hipaa Code is qualified for deletion only when it has no reason code associated to it.
  def qualified_for_deletion?
    self.reason_codes_clients_facilities_set_names.length == 0
  end

  def valid_hipaa_adjustment_code
    unless hipaa_adjustment_code.blank? || hipaa_adjustment_code == '-'
      hipaa_adjustment_code
    end
  end

  def eligible_for_output?(eob)
    if active_indicator == false && !eob.blank?
      eob.created_at < updated_at
    elsif active_indicator == true
      true
    end
  end

  def self.collect_active_code_details
    ids_and_codes_descriptions = []
    hipaa_code_records = HipaaCode.where(:active_indicator => true).
      select("id, hipaa_adjustment_code, hipaa_code_description").order("hipaa_adjustment_code")
    hipaa_code_records.each do |record|
      ids_and_codes_descriptions << [record.id, record.hipaa_adjustment_code, record.hipaa_code_description]
    end
    ids_and_codes_descriptions
  end

  def add_to_hipaa_codes_global_variable
    inserted = false
    $HIPAA_CODES.each_with_index do |id_and_code_and_desc, index|
      if id_and_code_and_desc[0] == id
        $HIPAA_CODES[index] = [id, hipaa_adjustment_code, hipaa_code_description]
        inserted = true
        break
      end
    end
    if not inserted
      $HIPAA_CODES << [id, hipaa_adjustment_code, hipaa_code_description]
    end    
  end
  
  def delete_from_hipaa_codes_global_variable
    $HIPAA_CODES.each_with_index do |id_and_code_and_desc, index|
      if id_and_code_and_desc[0] == id
        $HIPAA_CODES.delete_at(index)
        break
      end
    end
  end
  
  def self.get_active_code_details_given_ids(ids)
    ids_and_codes_and_descriptions = $HIPAA_CODES
    hipaa_code_array = []
    ids.each do |id|
      ids_and_codes_and_descriptions.each do |id_and_code_and_description|
        if id == id_and_code_and_description[0]
          hipaa_code_array << id_and_code_and_description
        end
      end
    end
    hipaa_code_array
  end

  def self.get_active_code_details_given_adjustment_codes(codes)
    ids_and_codes_and_descriptions = $HIPAA_CODES
    hipaa_code_array = []
    codes.each do |code|
      ids_and_codes_and_descriptions.each do |id_and_code_and_description|
        if code.upcase == id_and_code_and_description[1].upcase
          hipaa_code_array << id_and_code_and_description
        end
      end
    end
    hipaa_code_array
  end
  
end
