require File.dirname(__FILE__) + '/../test_helper'

class PatientTest < ActiveSupport::TestCase
  fixtures :patients
  
  def test_processor_input_field_count_with_all_data
    patient  = Patient.find(1)
    total_field_count = patient.processor_input_field_count
    assert_equal(total_field_count, 5)
  end
  
  def test_processor_input_field_count_with_no_data
    patient  = Patient.find(2)
    total_field_count = patient.processor_input_field_count
    assert_equal(total_field_count, 0)
  end 
  
  def test_processor_input_field_count_with_missing_data
    patient  = Patient.find(3)
    total_field_count = patient.processor_input_field_count
    assert_equal(total_field_count, 4)
  end 
end