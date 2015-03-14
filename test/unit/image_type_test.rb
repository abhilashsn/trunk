require 'test_helper'

class ImageTypeTest < ActiveSupport::TestCase

  # +--------------------------------------------------------------------------+
  # This is for testing the custom validation, 'validate_patient_name_and_account_number'.
  # -- Patient Name and Account Number should contain alphabets, numbers,      |
  #    hyphens and periods only                                                |
  # Input  : valid Patient Name and Account number.                            |
  # Output : Returns true.                                                     |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_and_account_number_by_giving_valid_data
    image_type_record = ImageType.new
    image_type_record.patient_first_name = "RAJ.jk-9"
    image_type_record.patient_last_name = "CC.9-"
    image_type_record.patient_account_number = "gh.gh-89"
    image_type_record.image_type = "CHK"
    image_type_record.save
    assert image_type_record.valid?, image_type_record.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the custom validation, 'validate_patient_name_and_account_number'.
  # -- Patient Name and Account Number should contain alphabets, numbers,      |
  #    hyphens and periods only.                                               |
  # Input  : Invalid Patient Name and Account Number.                          |
  # Output : Returns error message if image_type_record is not valid.          |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_and_account_number_by_giving_invalid_data
    image_type_record = ImageType.new
    image_type_record.patient_first_name = "RAJ.jk*-9"
    image_type_record.patient_last_name = "C)C.9-"
    image_type_record.patient_account_number= "gh.gh-&&89"
    image_type_record.image_type = "EOB"
    image_type_record.save
    assert !image_type_record.valid?, image_type_record.errors.full_messages.to_s
  end

   # +--------------------------------------------------------------------------+
  # This is for testing the custom validation, 'validate_patient_name_and_account_number'.
  # -- Patient Name and Account Number should contain alphabets, numbers,      |
  #    hyphens and periods only.                                               |
  # Input  : Patient Name and Account Number with consecutive occurrence of valid 
  #          special characters only.                                          |
  # Output : Returns error message if image_type_record is not valid.          |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_and_account_number_with_consecutive_occurrence_of_valid_special_characters
    image_type_record = ImageType.new
    image_type_record.patient_first_name = "RAJ..p"
    image_type_record.patient_last_name = "mek..ha"
    image_type_record.patient_account_number= "A89--990"
    image_type_record.image_type = "NOT"
    image_type_record.save
    assert !image_type_record.valid?, image_type_record.errors.full_messages.to_s
  end
end
