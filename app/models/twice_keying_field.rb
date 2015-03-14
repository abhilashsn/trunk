class TwiceKeyingField < ActiveRecord::Base
  validates_presence_of :field_name, :start_date, :end_date, :client_id
  
  belongs_to :facility
  belongs_to :client
  belongs_to :reason_code_set_name
  belongs_to :processor, :class_name => "User", :foreign_key => :processor_id

  def self.create_or_update(twice_keying_records, previous_field_name = nil)
    if !twice_keying_records.blank?
      group_no = twice_keying_records[0][:group_no]
      records_to_create, existing_twice_keying_record_ids = [], []
      twice_keying_records.each do |twice_keying_field_attributes|
        condition = self.get_conditions(twice_keying_field_attributes)         
        existing_twice_keying_records = self.where(condition)
        existing_twice_keying_record = existing_twice_keying_records.first
        record_to_create = self.new(twice_keying_field_attributes)
        records_to_create << record_to_create
        if existing_twice_keying_records
          unless  existing_twice_keying_record.blank?
            existing_twice_keying_record_ids << existing_twice_keying_record.id
          end
        end
      end
    end

    if !existing_twice_keying_record_ids.blank?
      existing_twice_keying_record_ids.each do |record_id|
        self.destroy(record_id)
      end
    end
   
    unless previous_field_name.blank?
      self.where(:field_name => previous_field_name, :group_no => group_no).delete_all
    end
    self.import(records_to_create) if !records_to_create.blank?
    
  end

  def self.formulate_array_of_attributes(parameters)
    payer_id = parameters[:payer_id]
    duration_number = parameters[:duration_number]
    duration_type = parameters[:duration_type]
    if !payer_id.blank?
      payer = Payer.find(:first, :conditions => ["id = ?" , payer_id], :select => "reason_code_set_name_id")
      reason_code_set_name_id = payer.reason_code_set_name_id if payer
    end
    start_date = Time.now
    end_date = parameters[:end_date]
    if end_date.blank? # From create UI
      duration = case duration_type
      when 'week'
        eval("#{duration_number.to_i * 7}.days")
      when 'month'
        eval("#{duration_number}.months")
      when 'year'
        eval("#{duration_number}.years")
      end
      end_date = start_date + duration
    end
    
    records = []
    attribute_hash = {
      :client_id => parameters[:client_id],
      :reason_code_set_name_id => reason_code_set_name_id,
      :start_date => start_date,
      :end_date => end_date,
      :group_no => parameters[:group_no]
    }
    
    user_ids = parameters[:user_ids].class == Array ? parameters[:user_ids] : [parameters[:user_ids]]
    field_names = parameters[:field_names].class == Array ? parameters[:field_names] : [parameters[:field_names]]

    field_names.each do |field_name|
      field_name = self.normalized_field_name(field_name)
      if !field_name.blank?
        attribute_hash[:field_name] = field_name
        if !user_ids.blank?
          user_ids.each do |user_id|
            if !parameters[:facility].blank? && !parameters[:facility][:id].blank?
              parameters[:facility][:id].each do |facility_id|
                records << self.get_attributes(attribute_hash, user_id, facility_id)
              end
            else
              records << self.get_attributes(attribute_hash, user_id)
            end
          end
        else
          if !parameters[:facility].blank? && !parameters[:facility][:id].blank?
            parameters[:facility][:id].each do |facility_id|
              records << self.get_attributes(attribute_hash, nil, facility_id)
            end
          else
            records << self.get_attributes(attribute_hash)
          end
        end
      end
    end
    records.compact.uniq
  end


  # Creating another hash for storing attributes is necessary to create a array of hashes.
  # If the same hash is used to append to a array, the following behavior of hash will override the existing hashes in the array.
  # array = []              => []
  # hash = {'a' => 'a'}     => {"a"=>"a"}
  # array << hash           => [{"a"=>"a"}]
  # hash['a'] = 'b'         => "b"
  # array                   => [{"a"=>"b"}]
  #
  #
  def self.get_attributes(attribute_hash, user_id = nil, facility_id = nil)
    attributes = {
      :client_id => attribute_hash[:client_id],
      :reason_code_set_name_id => attribute_hash[:reason_code_set_name_id],
      :start_date => attribute_hash[:start_date],
      :end_date => attribute_hash[:end_date],
      :field_name => attribute_hash[:field_name],
      :processor_id => user_id,
      :facility_id => facility_id,
      :group_no => attribute_hash[:group_no]
    }
    attributes
  end

  def self.update_attributes_without_updating_key(attribute_hash)
    attributes = {
      :client_id => attribute_hash[:client_id],
      :reason_code_set_name_id => attribute_hash[:reason_code_set_name_id],
      :start_date => attribute_hash[:start_date],
      :end_date => attribute_hash[:end_date],
      :field_name => attribute_hash[:field_name],
      :processor_id =>  attribute_hash[:processor_id],
      :facility_id =>  attribute_hash[:facility_id]
    }
    attributes
  end


  def self.normalized_field_name(field_name)
    if !field_name.blank?
      case field_name
      when 'dateofservicefrom'
        normalized_field_name = 'dateofservicefrom,date_service_from'
      when 'dateofserviceto'
        normalized_field_name = 'dateofserviceto,date_service_to'
      when 'payment'
        normalized_field_name = 'payment,service_paid_amount'
      when 'co_insurance'
        normalized_field_name = 'co_insurance,coinsurance'
      when 'non_covered'
        normalized_field_name = 'non_covered,noncovered'
      when 'deductable'
        normalized_field_name = 'deductable,deductible'
      when 'copay'
        normalized_field_name = 'copay,co_pay'
      when 'primary_payment'
        normalized_field_name = 'primary_payment,primary_pay_payment,submitted_charge_for_claim'
      else
        normalized_field_name = field_name
      end
    end
    normalized_field_name
  end

  def self.get_conditions(twice_keying_field_attributes)
    condition_string, condition_fields = [], []
    attributes = {
      :field_name => twice_keying_field_attributes[:field_name],
      :client_id => twice_keying_field_attributes[:client_id],
      :facility_id => twice_keying_field_attributes[:facility_id],
      :reason_code_set_name_id => twice_keying_field_attributes[:reason_code_set_name_id],
      :processor_id => twice_keying_field_attributes[:processor_id]}
    attributes.each do |key, value|
      if value.blank?
        condition_string << "#{key.to_s} IS NULL"
      else
        condition_string << "#{key.to_s} = ?"
        condition_fields << value
      end
    end
    condition_string = condition_string.join(' AND ')
    condition = condition_fields.insert(0, condition_string)
    condition
  end

  def self.get_all_twice_keying_fields(client_id, facility_id, user_id, rc_set_name_id)
    fields = self.find(:all, :select => :field_name,
      :conditions => ["(processor_id is null or processor_id = ?)
       and (facility_id is null or facility_id = ?)
       and (reason_code_set_name_id is null or reason_code_set_name_id = ? )
       and client_id = ? and start_date <= ? and end_date >= ?
       and field_name is not null and field_name != ''",
        "#{user_id}", "#{facility_id}", "#{rc_set_name_id}", "#{client_id}",
        "#{(Time.now).strftime("%Y-%m-%d")}", "#{Time.now.strftime("%Y-%m-%d")}"])
    alert_fields = fields.collect{|alert| alert.field_name.strip}.join(',')
    alert_fields
  end

  def self.frame_delete_conditions hash, group_no
    field_name_conditions = []
    hash["#{group_no}"].split(" ").each do |item|
      field_name_conditions << ("field_name like " + '"' + item.gsub('"', '') +"%" + '"')
    end
    unless group_no.blank?
      conditions = "group_no = #{group_no}"
      unless field_name_conditions.blank?
        conditions <<  " and " << "#{field_name_conditions.flatten.join(' or ')}"
      end
    end
  end

  def self.get_group_no last_twice_keying_record
    group_number = 1
    unless last_twice_keying_record.blank?
      group_no = last_twice_keying_record.group_no
      group_number = group_no + 1 unless group_no.blank?
    end
    group_number
  end

end
