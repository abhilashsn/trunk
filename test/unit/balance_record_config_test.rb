require File.dirname(__FILE__) + '/../test_helper'

class BalanceRecordConfigTest < ActiveSupport::TestCase
  fixtures :balance_record_configs, :facilities
  def setup
    balance_record_with_patient = balance_record_configs(:balance_record_config_2)
    balance_record_with_payer = balance_record_configs(:balance_record_config_3)
    @new_balance_record_1 = BalanceRecordConfig.new
    @new_balance_record_1.attributes = balance_record_with_patient.attributes
    @new_balance_record_2 = BalanceRecordConfig.new
    @new_balance_record_2.attributes = balance_record_with_payer.attributes
    @facility = facilities(:facility1)
  end
  
  def test_is_account_number_present
    @new_balance_record_1.account_number = nil
    @new_balance_record_1.save
    @new_balance_record_2.account_number = nil
    @new_balance_record_2.save
    
    assert !@new_balance_record_1.valid?, @new_balance_record_1.errors.full_messages.to_s
    assert !@new_balance_record_2.valid?, @new_balance_record_2.errors.full_messages.to_s
  end
 
  def test_is_patient_name_present
    @new_balance_record_1.first_name = nil
    @new_balance_record_1.last_name = nil
    @new_balance_record_1.save
    
    assert !@new_balance_record_1.valid?, @new_balance_record_1.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the custom validation, 'validate_name_and_account_number'.
  # -- Name and Account Number should contain alphabets, numbers,              |
  #    hyphens and periods only                                                |
  # Input  : valid Name and Account number.                                    |
  # Output : Returns true.                                                     |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_name_and_account_number_by_giving_valid_data
    balance_record_config = BalanceRecordConfig.new
    balance_record_config.first_name = "RAJ.jk-9"
    balance_record_config.last_name = "CC.9-"
    balance_record_config.account_number = "gh.gh-89"
    balance_record_config.save
    assert balance_record_config.valid?, balance_record_config.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the custom validation, 'validate_name_and_account_number'.
  # -- Name and Account Number should contain alphabets, numbers,              |
  #    hyphens and periods only.                                               |
  # Input  : Invalid Name and Account Number.                                  |
  # Output : Returns error message if balance_record_config is not valid.      |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_name_and_account_number_by_giving_invalid_data
    balance_record_config = BalanceRecordConfig.new
    balance_record_config.first_name = "RAJ*"
    balance_record_config.last_name = "CC.j)"
    balance_record_config.account_number = "gh.gh_89"
    balance_record_config.save
    assert !balance_record_config.valid?, balance_record_config.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing the custom validation, 'validate_name_and_account_number'.
  # -- Name and Account Number should contain alphabets, numbers,              |
  #    hyphens and periods only.                                               |
  # Input  : Name and Account Number with consecutive occurrence of valid      |
  #          special characters only.                                          |
  # Output : Returns error message if balance_record_config is not valid.      |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_name_and_account_number_with_consecutive_occurrence_of_valid_special_characters
    balance_record_config = BalanceRecordConfig.new
    balance_record_config.first_name = "RAJjk--9"
    balance_record_config.last_name = "CC..9-"
    balance_record_config.account_number = "gh.gh..89"
    balance_record_config.save
    assert !balance_record_config.valid?, balance_record_config.errors.full_messages.to_s
  end
end
