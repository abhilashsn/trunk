# To change this template, choose Tools | Templates
# and open the template in the editor.

require File.dirname(__FILE__) + '/../test_helper'
require 'test/unit'
require 'provider_adjustment'

class ProviderAdjustmentTest < ActiveSupport::TestCase
  fixtures :jobs, :provider_adjustments, :insurance_payment_eobs
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_account_number'.|
  # -- Patient Account Number should contain alphabets/numbers/hyphens/        |
  # -- /periods only                                                           |
  # Input  : valid patient_account_number.                                     |
  # Output : Returns true.                                                     |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_account_number_by_giving_valid_data
    provider_adj = ProviderAdjustment.new
    provider_adj.patient_account_number= "gh.gh-89"
    provider_adj.save
    assert provider_adj.valid?, provider_adj.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_account_number'.|
  # -- Patient Account Number should contain alphabets/numbers/hyphens/        |
  # -- /periods only                                                           |
  # Input  : Invalid patient_account_number.                                   |
  # Output : Returns error message if provider_adj is not valid.               |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_account_number_by_giving_invalid_data
    provider_adj = ProviderAdjustment.new
    provider_adj.patient_account_number = "gh.gh-&&89"
    provider_adj.save
    assert !provider_adj.valid?, provider_adj.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_account_number'.|
  # -- Patient Account Number should contain alphabets, numbers, hyphens       |
  # -- and periods only                                                        |
  # Input  : Patient_account_number with consecutive occurrence of valid special
  #          characters.                                                       |
  # Output : Returns error message if provider_adj is not valid.                        |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_account_number_with_consecutive_occurrence_of_valid_special_characters
    provider_adj = ProviderAdjustment.new
    provider_adj.patient_account_number = "gh..gh"
    provider_adj.save
    assert !provider_adj.valid?, provider_adj.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing processor_input_field_count.                                  
  # Input1  : Normal job without provider_adjustments and image page number of eob
  # Input2  : Normal job with provider_adjustments and image page number of eob
  # Input2  : Normal job having split jobs with provider_adjustments and image page number of eob
  # Output1 : Return 0.
  # Output1 : Return 2.
  # Output1 : Return 6.
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_processor_input_field_count
    assert_equal(0, ProviderAdjustment.processor_input_field_count(1, jobs(:job_228)))
    assert_equal(2, ProviderAdjustment.processor_input_field_count(1, jobs(:job_223)))
    assert_equal(9, ProviderAdjustment.processor_input_field_count(1, jobs(:job_222)))
  end
end
