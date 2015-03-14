class ImageType < ActiveRecord::Base
  include DcGrid
  validates_presence_of :image_type
  validate :validate_patient_name
  validate :validate_patient_account_number
  belongs_to :insurance_payment_eob
  belongs_to :images_for_job

  before_save :upcase_grid_data

  def self.by_batch_ids(batch_ids)
    if batch_ids.present?
      find(:all, :joins=>",insurance_payment_eobs eob ,check_informations c, batches b,jobs j", :conditions=>"eob.id = image_types.insurance_payment_eob_id  AND  eob.check_information_id = c.id  AND j.batch_id = b.id AND j.id = c.job_id AND b.id in (#{batch_ids.join(',')})", :include=>[:insurance_payment_eob])
    else
      []
    end
  end


  def self.all_image_types_by_batch_ids(batch_ids)
    if batch_ids.present?
      find(:all, :joins=>", batches b , images_for_jobs j", :conditions=>"j.batch_id = b.id AND image_types.images_for_job_id = j.id  AND b.id in (#{batch_ids.join(',')})", :include=>[:insurance_payment_eob], :order=>"b.id, j.image_file_name")
    else
      []
    end
  end

  # +--------------------------------------------------------------------------+
  # This method is for validating account number.
  # -- Patient Account # - Required alphabets,
  # numeric,hyphen and period only. Otherwise error message will throw.        |
  # +--------------------------------------------------------------------------+
  def validate_patient_account_number
    error_message = ""
    error_message += " Patient Account# - Required Alphanumeric, hyphen and period only!!" if !patient_account_number.blank? &&
      (patient_account_number.match(/\.{2}|\-{2}|^[\-\.]+$/) || !patient_account_number.match(/^[A-Za-z0-9\-\.]*$/))
    errors.add(:base, error_message) unless error_message == ""
  end
  
  # +--------------------------------------------------------------------------+
  # This method is for validating patient first and last names.
  # -- Patient first name and last name - For BAC Required alphabets, numeric,hyphen   |
  #    or period only. Otherwise error message will throw.
  # -- Patient first name and last name - For NBAC Required alphabets, numeric,hyphen,   |
  #    space or period only if patient_name_format_validation is checked in FCUI.
  #    Otherwise error message will throw.                     |
  # +--------------------------------------------------------------------------+
  def validate_patient_name
    batch = images_for_job.batch
    facility = batch.facility
    error_message = ""
    error_message += "Patient Name - First/Last should be Alphanumeric, hyphen or period only!" if $IS_PARTNER_BAC &&
      !patient_last_name.blank? && !patient_first_name.blank? &&
      (patient_last_name.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !patient_last_name.match(/^[A-Za-z0-9\-\.]*$/)) &&
      (patient_first_name.match(/\.{2}|\-{2}|^[\-\.]+$/) ||
        !patient_first_name.match(/^[A-Za-z0-9\-\.]*$/))

    error_message += "Patient Name - First/Last should be Alphanumeric, hyphen, space or period only!" if !$IS_PARTNER_BAC &&
      facility.details[:patient_name_format_validation] &&
      !patient_last_name.blank? && !patient_first_name.blank? &&
      (patient_last_name.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) ||
        !patient_last_name.match(/^[A-Za-z0-9\-\s\.]*$/)) &&
      (patient_first_name.match(/\.{2}|\-{2}|\s{2}|^[\-\.\s]+$/) ||
        !patient_first_name.match(/^[A-Za-z0-9\-\s\.]*$/))
    
    errors.add(:base, error_message) unless error_message == ""
  end

end
