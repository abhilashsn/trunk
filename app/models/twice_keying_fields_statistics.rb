# Stores the success or failure status of first attempt of twice keying fields.
# Stores the report of first attempt status of processor with date of keying and other details
class TwiceKeyingFieldsStatistics < ActiveRecord::Base
  include Admin::TwiceKeyingFieldsHelper
  
  belongs_to :processor, :class_name => "User", :foreign_key => :processor_id
  belongs_to :client
  belongs_to :facility
  belongs_to :payer
  belongs_to :check_information
  belongs_to :insurance_payment_eob

  scope :list_data, lambda { |condition_string, condition_values|
    select("twice_keying_fields_statistics.id, twice_keying_fields_statistics.field_name, \
      twice_keying_fields_statistics.date_of_keying, twice_keying_fields_statistics.first_attempt_status, \
      twice_keying_fields_statistics.batch_date, twice_keying_fields_statistics.batchid, \
      payers.payid, payers.payer AS payer_name, \
      check_informations.check_number, insurance_payment_eobs.patient_account_number, \
      clients.name AS client_name, facilities.name AS facility_name,
      users.name AS processor_name, users.employee_id").
      where(condition_string, condition_values).
      joins("INNER JOIN clients ON clients.id = twice_keying_fields_statistics.client_id \
      INNER JOIN facilities ON facilities.id = twice_keying_fields_statistics.facility_id \
      INNER JOIN users ON users.id = twice_keying_fields_statistics.processor_id \
      INNER JOIN payers ON payers.id = twice_keying_fields_statistics.payer_id \
      INNER JOIN check_informations ON check_informations.id = twice_keying_fields_statistics.check_information_id \
      INNER JOIN insurance_payment_eobs ON insurance_payment_eobs.id = twice_keying_fields_statistics.insurance_payment_eob_id").
      group("twice_keying_fields_statistics.id").
      order("date_of_keying ASC, clients.name, facilities.name ASC")
  }

  def self.create_all_records(attributes_array)
    records = []
    attributes_array.each do |attributes|
      records << self.new(attributes)
    end
    self.import(records) if records.present?
  end

  def normalize_first_attempt_status
    case first_attempt_status
    when true
      'SUCCESS'
    else
      'FAILURE'
    end
  end

  def self.get_conditions(parameters = {})
    criteria, to_find = parameters[:criteria].to_s.strip.upcase, parameters[:to_find].to_s.strip.upcase
    from_date, to_date = parameters[:from_date].to_s.strip, parameters[:to_date].to_s.strip
    condition_string = []
    condition_values = {}
    flash_notice = ''
    if to_find.present? || from_date.present? || to_date.present?
      if criteria != 'DATE'
        if from_date.present?
          date, flash_notice = self.normalize_date(from_date)
          if date.present?
            condition_string << "DATE(twice_keying_fields_statistics.date_of_keying) >= :from_date"
            condition_values[:from_date] = date
          end
        end
        if to_date.present?
          date, flash_notice = self.normalize_date(to_date)
          if date.present?
            condition_string << "DATE(twice_keying_fields_statistics.date_of_keying) <= :to_date"
            condition_values[:to_date] = date
          end
        end
      end
      case criteria   
      when 'DATE'
        date, flash_notice = self.normalize_date(to_find)
        if date.present?
          condition_string << "DATE(twice_keying_fields_statistics.date_of_keying) = :date"
          condition_values[:date] = date
        end
      when 'CLIENT'
        condition_string << "clients.name LIKE :client_name"
        condition_values[:client_name] = "%#{to_find}%"
      when 'FACILITY'
        condition_string << "facilities.name LIKE :facility_name"
        condition_values[:facility_name] = "%#{to_find}%"
      when 'PAYER ID'
        condition_string << "payers.payid = :payid"
        condition_values[:payid] = to_find
      when 'PAYER NAME'
        condition_string << "payers.payer LIKE :payer_name"
        condition_values[:payer_name] = "%#{to_find}%"
      when 'FIELD NAME'
        condition_string << "twice_keying_fields_statistics.field_name LIKE :field_name"
        condition_values[:field_name] = "%#{to_find}%"
      when 'PROCESSOR NAME'
        condition_string << "users.name LIKE :processor_name"
        condition_values[:processor_name] = "%#{to_find}%"
      when 'STATUS'
        condition_string << "twice_keying_fields_statistics.first_attempt_status = :first_attempt_status"
        if to_find == 'SUCCESS'
          value = 1
        elsif to_find == 'FAILURE'
          value = 0
        end
        condition_values[:first_attempt_status] = value
      end
      condition_string = condition_string.join(" AND ")
    end
    return condition_string, condition_values, flash_notice
  end

  def self.normalize_date(date)
    if date.length == 10
      date.slice!(6..7)
    end
    flash_notice = ''
    begin
      # normalized_date is in IST
      normalized_date = Date.strptime(date, "%m/%d/%y")
    rescue ArgumentError
      flash_notice = "Invalid date format, use mm/dd/yy"
    end
    return normalized_date, flash_notice
  end

  def normalize_field_name
    normalized_field_name = ''
    field_name_hash = field_names_list
    field_name_hash.each do |key, value|
      if field_name.include?(key.to_s)
        if field_name.include?('unique_code') && key.include?('unique_code')
          normalized_field_name = value
        elsif !field_name.include?('unique_code')
          normalized_field_name = value
        end        
        break if normalized_field_name.present?
      end
    end
    normalized_field_name.to_s.upcase
  end
  
end
