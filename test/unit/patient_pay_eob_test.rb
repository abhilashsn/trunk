require File.dirname(__FILE__) + '/../test_helper'

class PatientPayEOBTest < ActiveSupport::TestCase
  fixtures :patient_pay_eobs, :facilities
  
  def test_processor_input_field_count_with_all_data
    patient_pay_eob  = PatientPayEob.find(2)
    total_field_count = patient_pay_eob.processor_input_field_count
    assert_equal(total_field_count, 8)
  end
  
  def test_processor_input_field_count_with_no_data
    patient_pay_eob  = PatientPayEob.find(3)
    total_field_count = patient_pay_eob.processor_input_field_count
    assert_equal(total_field_count, 0)
  end
  
  def test_processor_input_field_count_with_some_missing_data
    patient_pay_eob  = PatientPayEob.find(1)
    total_field_count = patient_pay_eob.processor_input_field_count
    assert_equal(total_field_count, 7)
  end

  def test_to_normalize_account_number_of_12_digits
    eob = PatientPayEob.new
    eob.account_number = '123456789012'
    facility = facilities(:facility8)
    obtained_account_number = eob.normalize_account_number(facility.details[:practice_id])
    expected_account_number = '1234123456789012'
    assert_equal expected_account_number, obtained_account_number
  end
  
  def test_to_normalize_account_number_of_less_than_digits
    eob = PatientPayEob.new
    eob.account_number = '12345678901'
    facility = facilities(:facility8)
    obtained_account_number = eob.normalize_account_number(facility.details[:practice_id])
    expected_account_number = '1234012345678901'
    assert_equal expected_account_number, obtained_account_number
  end

  def test_to_normalize_account_number_of_12_digits_and_having_zeros
    eob = PatientPayEob.new
    eob.account_number = '000056789012'
    facility = facilities(:facility8)
    obtained_account_number = eob.normalize_account_number(facility.details[:practice_id])
    expected_account_number = '1234000056789012'
    assert_equal expected_account_number, obtained_account_number
  end

  def test_to_normalize_account_number_of_12_digits_having_no_practice_id
    eob = PatientPayEob.new
    eob.account_number = '123456789012'
    facility = facilities(:facility_1)
    obtained_account_number = eob.normalize_account_number(facility.details[:practice_id])
    expected_account_number = '123456789012'
    assert_equal expected_account_number, obtained_account_number
  end
  
end
