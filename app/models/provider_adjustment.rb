class ProviderAdjustment < ActiveRecord::Base
  include EobClientCode
  include DcGrid
  
  validate :validate_patient_account_number
  belongs_to :job
  belongs_to :insurance_payment_eob
  alias_attribute :image_page_no, :image_page_number
  before_save :upcase_grid_data
  # +--------------------------------------------------------------------------+
  # This method is for validating patient account number.                      |
  # -- Patient account number - Required alphabets, numeric,  hyphen  and      |
  #    period only for BAC. Otherwise error message will throw.                |
  # -- Patient account number - Required alphabets, numeric,  hyphen,  period  |
  #    forward slash only for non BAC. Otherwise error message will throw.     |
  # -- No consecutive occurrence of special characters allowed                 |
  # -- No maximum limit to any special characters except forward slash(3)      |
  # +--------------------------------------------------------------------------+
  def validate_patient_account_number
    error_message = ""
    error_message += "Patient Account Number should be Alphanumeric, hyphen or period only!" if $IS_PARTNER_BAC &&
      !patient_account_number.blank? &&
      (patient_account_number.match(/\.{2}|\-{2}|^[\-\.]+$/) || 
        !patient_account_number.match(/^[A-Za-z0-9\-\.]*$/))
    error_message += "Patient Account Number should be Alphanumeric, hyphen, period or forward slash only!" if !$IS_PARTNER_BAC &&
      !patient_account_number.blank? &&
      (patient_account_number.match(/\.{2}|\-{2}|\/{2}|^[\-\.\/]+$/) ||
        !patient_account_number.match(/^[A-Za-z0-9\-\.\/]*$/) ||
        patient_account_number.gsub(/[a-zA-Z0-9\.\-]/, '').match(/\/{4,}/))
    errors.add(:base, error_message) unless error_message == ""
  end

  def self.processor_input_field_count(image_page_no, job)
    ids_of_all_jobs = []
    count = 0
    ids_of_all_jobs += job.get_ids_of_all_child_jobs if job.eob_count == 0
    ids_of_all_jobs << job.id
    conditions = "provider_adjustments.job_id IN (#{ids_of_all_jobs.uniq.join(',')}) and provider_adjustments.image_page_number = #{image_page_no}"
    provider_adjustments = self.find(:all, :conditions => conditions )
    provider_adjustments.each do |provider_adjustment|
      constant_fields_with_data = []
      constant_fields = [provider_adjustment.amount,
        provider_adjustment.description, provider_adjustment.patient_account_number]
      constant_fields_with_data = constant_fields.select{|field| !field.blank?}
      count += constant_fields_with_data.length unless constant_fields_with_data.blank?
    end
    count
  end

 end
