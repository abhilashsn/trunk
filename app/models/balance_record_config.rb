class BalanceRecordConfig < ActiveRecord::Base
  belongs_to :facility 
  validates_presence_of :first_name, :last_name, :if => :is_patient_name_present?,
    :message => "Please enter Patient Name in Balancing Records Tab"
  validates_presence_of :account_number, :if => :is_account_number_present?, 
    :message => "Please enter Patient Account Number in Balancing Records Tab"
  validate :validate_first_and_last_name
  validate :validate_patient_account_number

  def self.create_or_delete_records(facility_id, parameters)
    svc_lines_ids_to_delete = []
    if parameters
      delete_records(parameters, svc_lines_ids_to_delete)
      save_records(facility_id, parameters, svc_lines_ids_to_delete)
    end
  end

  private
  
  def is_patient_name_present?
    !is_payer_the_patient && !account_number.blank?
  end
  
  def is_account_number_present?
    (!first_name.blank? && !last_name.blank?) || is_payer_the_patient
  end

  # +--------------------------------------------------------------------------+
  # This method is for validating account number.     |
  # -- Account # - Required alphabets,numeric,hyphen, period and               |
  #     forward slash for nan BAC and Required alphabets ,numeric, hyphen      |
  #     and period for BAC. Otherwise error message will throw.                |
  # -- No consecutive occurrence of special characters allowed                 |
  # -- No maximum limit to any special characters except forward slash(3)      |
  # +--------------------------------------------------------------------------+
  def validate_patient_account_number
    error_message = ""
    error_message += "  Account# - Required Alphanumeric, hyphen and period only!!" if $IS_PARTNER_BAC &&
      !account_number.blank? &&
      (account_number.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !account_number.match(/^[A-Za-z0-9\-\.]*$/)) 
    error_message += "  Account# - Required Alphanumeric, hyphen, period and forward slash only!!" if !$IS_PARTNER_BAC &&
      !account_number.blank? &&
      (account_number.match(/\.{2}|\-{2}|\/{2}|^[\-\.\/]+$/) ||
        !account_number.match(/^[A-Za-z0-9\-\.\/]*$/) ||
        account_number.gsub(/[a-zA-Z0-9\.\-]/, '').match(/\/{4,}/))
    errors.add(:base, error_message) unless error_message == ""
  end
  
  # +--------------------------------------------------------------------------+
  # This method is for validating first and last names.
  # -- first name and last name - For BAC Required alphabets, numeric,hyphen   |
  #    or period only. Otherwise error message will throw.
  # -- first name and last name - For NBAC Required alphabets, numeric,hyphen,   |
  #    space or period only if patient_name_format_validation is checked in FCUI.
  #    Otherwise error message will throw.                     |
  # +--------------------------------------------------------------------------+
  def validate_first_and_last_name
    error_message = ""
    error_message += "First/Last Name should be Alphanumeric, hyphen or period only!" if $IS_PARTNER_BAC &&
      !last_name.blank? && !first_name.blank? &&
      (last_name.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !last_name.match(/^[A-Za-z0-9\-\.]*$/)) &&
      (first_name.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !first_name.match(/^[A-Za-z0-9\-\.]*$/))

    error_message += "First/Last Name should be Alphanumeric, hyphen, space or period only!" if !$IS_PARTNER_BAC &&
      facility.details[:patient_name_format_validation] &&
      !last_name.blank? && !first_name.blank? &&
      (last_name.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) ||
        !last_name.match(/^[A-Za-z0-9\-\s\.]*$/)) &&
      (first_name.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) ||
        !first_name.match(/^[A-Za-z0-9\-\s\.]*$/))
    
    errors.add(:base, error_message) unless error_message == ""
  end

  def self.delete_records(parameters, svc_lines_ids_to_delete)
    record_ids_to_delete = parameters[:ids_to_delete]
    record_ids_to_delete = record_ids_to_delete.split(',') if record_ids_to_delete
    if !record_ids_to_delete.blank?
      record_ids_to_delete.each do |svc_lines_id|
        if !svc_lines_id.blank?
          svc_lines_ids_to_delete << svc_lines_id.to_i
        end
      end
      BalanceRecordConfig.where(:id => (svc_lines_ids_to_delete.uniq)).destroy_all if !svc_lines_ids_to_delete.blank?
    end
  end

  def self.save_records(facility, parameters, svc_lines_ids_to_delete)
    records_to_create = []
    serial_and_record_ids = parameters[:serial_and_record_ids]
    serial_and_record_ids = serial_and_record_ids.split(',')
    if !serial_and_record_ids.blank?
      existing_records = get_existing_records_in_hash(facility.id)
      serial_and_record_ids.each do |serial_num_and_record_id|
        variables = {
          :serial_num_and_record_id => serial_num_and_record_id,
          :svc_lines_ids_to_delete => svc_lines_ids_to_delete,
          :existing_records => existing_records
        }
        save_records_with_respect_to_the_serial_numbers(facility, variables, parameters, records_to_create)
      end
      create_records(records_to_create)
    end
  end

  def self.get_existing_records_in_hash(facility_id)
    existing_record_hash = {}
    existing_records = self.where(:facility_id => facility_id)
    existing_records.each do |record|
      existing_record_hash[record.id] = record
    end
    existing_record_hash
  end

  def self.save_records_with_respect_to_the_serial_numbers(facility, variables, parameters, records_to_create)
    serial_num_and_record_id = variables[:serial_num_and_record_id]
    svc_lines_ids_to_delete = variables[:svc_lines_ids_to_delete]
    existing_records = variables[:existing_records]
    if !serial_num_and_record_id.blank?
      svc_line_serial_num_and_id = serial_num_and_record_id.split('_')
      if !svc_line_serial_num_and_id.blank?
        serial_num = svc_line_serial_num_and_id[0].to_i
        record_id = svc_line_serial_num_and_id[1]
        if !serial_num.blank? && serial_num != 0 && (svc_lines_ids_to_delete.blank? || !svc_lines_ids_to_delete.include?(record_id))
          variables = { :existing_records => existing_records, :record_id => record_id, :serial_num => serial_num }
          update_or_create_record(facility, variables, records_to_create, parameters)
        end
      end
    end
  end

  def self.update_or_create_record(facility, variables, records_to_create, parameters)
    record_id = variables[:record_id]
    serial_num = variables[:serial_num]
    if record_id.present?
      update_record(facility, variables, parameters)
    else
      initialize_record(facility, serial_num, records_to_create, parameters)
    end
  end

  def self.update_record(facility, variables, parameters)
    existing_records = variables[:existing_records]
    record_id = variables[:record_id]
    serial_num = variables[:serial_num]
    record = existing_records[record_id.to_i]
    if record
      set_attributes(facility, record, serial_num, parameters)
      if record.category.present?
        record.save if record.changed?
      end
    end
  end

  def self.initialize_record(facility, serial_num, records_to_create, parameters)
    record = BalanceRecordConfig.new
    set_attributes(facility, record, serial_num, parameters)
    if record.category.present?
      records_to_create << record
    end
  end

  def self.set_attributes(facility, record, serial_num, parameters)
    serial_num = serial_num.to_s
    record.facility = facility
    record.category = format_attribute(parameters["category_#{serial_num}"])
    record.first_name = format_attribute(parameters["first_name_#{serial_num}"])
    record.last_name = format_attribute(parameters["last_name_#{serial_num}"])
    record.account_number = format_attribute(parameters["account_number_#{serial_num}"])
    record.is_payer_the_patient = format_attribute(parameters["is_payer_the_patient_#{serial_num}"])
    source_of_adjustment = format_attribute(parameters["source_of_adjustment_#{serial_num}"])
    source_of_adjustment = source_of_adjustment.downcase if source_of_adjustment.present?
    record.source_of_adjustment = source_of_adjustment
    record.is_claim_level_eob = case parameters["is_claim_level_eob_#{serial_num}"]
    when 'claim'
      true
    else
      false
    end
  end

  def self.create_records(records_to_create)
    if !records_to_create.blank?
      self.import records_to_create
    end
  end

  def self.format_attribute(value)
    value.blank? ? nil : value.strip.upcase
  end

end
