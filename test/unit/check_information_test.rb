require File.dirname(__FILE__) + '/../test_helper'

class CheckInformationTest < ActiveSupport::TestCase
  fixtures :check_informations, :facilities, :micr_line_informations, :payers, :jobs, :images_for_jobs,
    :client_images_to_jobs, :insurance_payment_eobs


  def test_get_amount_so_far_for_nextgen

    expected_amount_so_far = 30.00
    job = jobs(:job_94)
    obtained_amount_so_far = job.check_informations.first.get_amount_so_far()
    assert_equal expected_amount_so_far, obtained_amount_so_far
  end

  def test_get_amount_so_far_for_ins_payment_eobs

    expected_amount_so_far = 73.00
    job = jobs(:job_95)
    obtained_amount_so_far = job.check_informations.first.get_amount_so_far()
    assert_equal expected_amount_so_far, obtained_amount_so_far
  end
  

  def test_processor_input_field_count_for_nextgen_grid_with_all_data
    check_information = CheckInformation.find(4)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'nextgen')
    assert_equal(total_field_count, 5)
  end

  def test_processor_input_field_count_for_nextgen_grid_without_payment_type
    check_information = CheckInformation.find(21)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'nextgen')
    assert_equal(total_field_count, 3)
  end

  #Data in check amount and check number. No check date and payment_type are present
  def test_processor_input_field_count_for_nextgen_grid_without_check_date_and_payment_type
    check_information = CheckInformation.find(15)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'nextgen')
    assert_equal(total_field_count, 3)
  end

  def test_processor_input_field_count_for_nextgen_grid_with_check_amount_only
    check_information = CheckInformation.find(16)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'nextgen')
    assert_equal(total_field_count, 2)
  end
  def test_processor_input_field_count_for_nextgen_grid_has_no_fcui_config_for_payment_type
    check_information = CheckInformation.find(20)
    total_field_count = check_information.processor_input_field_count(facilities(:facility_1), 'nextgen')
    assert_equal(total_field_count, 0)
  end

  def test_processor_input_field_count_for_nextgen_grid_has_fcui_config_for_payment_type
    check_information = CheckInformation.find(20)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'nextgen')
    assert_equal(total_field_count, 1)
  end

  def test_processor_input_field_count_for_nextgen_grid_with_no_data
    check_information = CheckInformation.find(17)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'nextgen')
    assert_equal(total_field_count, 0)
  end

  def test_processor_input_field_count_for_simplified_grid_with_all_data
    check_information  = CheckInformation.find(4)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 5)
  end

  def test_processor_input_field_count_for_simplified_grid_without_payment_type
    check_information  = CheckInformation.find(21)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 3)
  end

  def test_processor_input_field_count_for_simplified_grid_without_check_date_and_payment_type
    check_information  = CheckInformation.find(15)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 2)
  end

  def test_processor_input_field_count_for_simplified_grid_with_check_amount
    check_information  = CheckInformation.find(16)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 1)
  end

  def test_processor_input_field_count_for_simplified_grid_with_no_data
    check_information = CheckInformation.find(17)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 0)
  end

  def test_processor_input_field_count_for_simplified_grid_has_no_fcui_config_for_payment_type
    check_information = CheckInformation.find(20)
    total_field_count = check_information.processor_input_field_count(facilities(:facility_1), 'simplified')
    assert_equal(total_field_count, 0)
  end

  def test_processor_input_field_count_for_simplified_grid_has_fcui_config_for_payment_type
    check_information = CheckInformation.find(20)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 1)
  end

  #Check mailed & received dates are applicable to insurance grid only
  def test_processor_input_field_count_for_check_mailed_and_received_dates
    check_information = CheckInformation.find(13)
    total_field_count = check_information.processor_input_field_count(facilities(:facility_25), 'insurance')
    assert_equal(total_field_count, 2)
  end

  def test_processor_input_field_count_for_without_check_mailed_and_received_dates
    check_information = CheckInformation.find(17)
    total_field_count = check_information.processor_input_field_count(facilities(:facility_25), 'insurance')
    assert_equal(total_field_count, 0)
  end

  # Unit test cases to test the date values in checks.
  def test_date_in_checks_for_check_date
    check_information  = check_informations(:check_information13)
    check_date = check_information.date_in_checks(check_information.check_date)
    assert_equal(check_date, '02/05/09')
  end

  def test_date_in_checks_for_check_mailed_date
    check_information  = check_informations(:check_information13)
    check_mailed_date = check_information.date_in_checks(check_information.check_mailed_date)
    assert_equal(check_mailed_date, '01/05/09')
  end

  def test_date_in_checks_for_check_received_date
    check_information  = check_informations(:check_information13)
    check_received_date = check_information.date_in_checks(check_information.check_received_date)
    assert_equal(check_received_date, '03/05/09')
  end

  def test_date_in_checks_for_blank_check_date
    check_info = CheckInformation.new
    check_9999  = check_informations(:check_9999)
    date_check = check_info.date_in_checks(check_9999.check_date)
    assert_equal(date_check, 'mm/dd/yy')
  end

  def test_date_in_checks_for_blank_check_mailed_date
    check_information  = check_informations(:check_information205)
    check_mailed_date = check_information.date_in_checks(check_information.check_mailed_date)
    assert_equal(check_mailed_date, 'mm/dd/yy')
  end

  def test_date_in_checks_for_blank_check_received_date
    check_information  = check_informations(:check_information205)
    check_received_date = check_information.date_in_checks(check_information.check_received_date)
    assert_equal(check_received_date, 'mm/dd/yy')
  end

  def get_payer_from_micr_when_payer_associated_to_check_exists
    check = check_informations(:check_29)
    payer = check.get_payer
    assert_equal payers(:payer_30), payer
  end

  def get_payer_from_micr_when_payer_associated_to_check_does_not_exists
    check = check_informations(:check_30)
    payer = check.get_payer
    assert_equal payers(:payer_30), payer
  end

  def get_payer_from_payer_associated_to_check_does_not_exists
    check = check_informations(:check_31)
    payer = check.get_payer
    assert_equal payers(:payer_23), payer
  end

  def test_count_of_unfinished_checks_for_payer_from_micr
    payer = payers(:payer_28)
    count = CheckInformation.count_of_unfinished_checks_for_payer(payer.id)
    assert_equal 1, count
  end

  def test_count_of_unfinished_checks_for_payer_from_check
    payer = payers(:payer_27)
    count = CheckInformation.count_of_unfinished_checks_for_payer(payer.id)
    assert_equal 1, count
  end

  def test_count_of_unfinished_checks_for_excluded_job
    payer = payers(:payer_29)
    count = CheckInformation.count_of_unfinished_checks_for_payer(payer.id)
    assert_equal 0, count
  end

  def test_count_of_unfinished_checks_for_completed_job
    payer = payers(:payer_29)
    count = CheckInformation.count_of_unfinished_checks_for_payer(payer.id)
    assert_equal 0, count
  end

  def test_count_of_unfinished_checks_for_incompleted_job
    payer = payers(:payer_29)
    count = CheckInformation.count_of_unfinished_checks_for_payer(payer.id)
    assert_equal 0, count
  end

  def test_image_file_name
    assert_equal(images_for_jobs(:img_for_jb11).filename, check_informations(:check_44).image_file_name)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'display_patpay_grid_by_default'.
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) No MICR and Check number length(after trimming the left padded zeroes)=4|
  # Output:                                                                    |
  # 1) Returns true                                                            |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_no_micr_and_check_number_length_equal_to_four
    check_with_no_micr = check_informations(:check_47)
    facility = facilities(:facility1)
    assert_equal false, check_with_no_micr.display_patpay_grid_by_default?(nil, facility, nil)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'display_patpay_grid_by_default'.
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) New MICR and check number length(No left padded zeroes) = 4             |
  # Output:                                                                    |
  # 1) Returns true                                                            |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_new_micr_and_check_number_length_equal_to_four
    check_with_new_micr = check_informations(:check_52)
    facility = facilities(:facility1)
    assert_equal true, check_with_new_micr.display_patpay_grid_by_default?(nil,facility, nil)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'display_patpay_grid_by_default'.           |
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) MICR does not belong to Insurance Payer and check number length         |
  #    (after trimming the left padded zeroes) = 4                             |
  # Output:                                                                    |
  # 1) Returns true                                                            |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_micr_does_not_belong_to_insurance_payer_and_check_number_length_equal_to_four
    check_having_micr_which_belongs_to_patient_payer = check_informations(:check_having_micr_associated_to_patpay_payer_57)
    facility = facilities(:facility1)
    assert_equal true, check_having_micr_which_belongs_to_patient_payer.display_patpay_grid_by_default?(nil,facility, nil)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,  'display_patpay_grid_by_default'.         |
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) No MICR and Check number length(after trimming the left padded zeroes)  |
  #    is not equal to 4.                                                      |
  # Output:                                                                    |
  # 1) Returns false                                                           |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_no_micr_and_check_number_length_not_equal_to_four
    check_with_no_micr = check_informations(:check_50)
    facility = facilities(:facility1)
    assert_equal false, check_with_no_micr.display_patpay_grid_by_default?(nil, facility, nil)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,  'display_patpay_grid_by_default'.         |
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) New MICR and Check number length(after trimming the left padded zeroes)  |
  #    is not equal to 4.                                                      |
  # Output:                                                                    |
  # 1) Returns false                                                           |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_new_micr_and_check_number_length_not_equal_to_four
    check_with_new_micr = check_informations(:check_56)
    facility = facilities(:facility1)
    assert_equal false, check_with_new_micr.display_patpay_grid_by_default?(nil, facility, nil)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'display_patpay_grid_by_default'.           |
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) MICR does not belong to Insurance Payer and check number length         |
  #    (after trimming the left padded zeroes) not equal to 4.                 |
  # Output:                                                                    |
  # 1) Returns False.                                                            |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_micr_does_not_belong_to_insurance_payer_and_check_number_length_not_equal_to_four
    check_having_micr_which_belongs_to_patient_payer = check_informations(:check_having_micr_associated_to_patpay_payer_58)
    facility = facilities(:facility1)
    assert_equal false, check_having_micr_which_belongs_to_patient_payer.display_patpay_grid_by_default?(nil, facility, nil)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'display_patpay_grid_by_default'.           |
  # -- Following conditions together satisfy.                                  |
  # 1) No MICR/ New MICR/MICR does not belong to Insurance Payer               |
  # 2)  Check number length(after trimming the left padded zeroes) = 4         |
  # Input:                                                                     |
  # 1) MICR belongs to Insurance Payer and check number length = 4             |
  # Output:                                                                    |
  # 1) Returns False.                                                          |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_display_patpay_grid_by_default_with_micr_belongs_to_insurance_payer_and_check_number_length_equal_to_four
    check_having_micr_which_belongs_to_insurance_payer = check_informations(:check_having_micr_associated_to_insurance_payer_59)
    facility = facilities(:facility1)
    assert_equal false, check_having_micr_which_belongs_to_insurance_payer.display_patpay_grid_by_default?(nil, facility, nil)
  end

  def test_do_not_display_patpay_grid_having_no_facility_patpay_configuration
    check_with_no_micr = check_informations(:check_47)
    facility = facilities(:facility2)
    assert_equal false, check_with_no_micr.display_patpay_grid_by_default?(nil, facility, nil)
  end

  # +--------------------------------------------------------------------------+
  #Re-pricer Info is included along with other fields.This field is applicable to
  #3 grids(insurance, simplified and nextgen)
  #Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_processor_input_field_count_with_or_without_re_pricer_info
    check_information = check_informations(:check_45)
    total_field_count_with_re_pricer_info = check_information.processor_input_field_count(facilities(:facility8), 'insurance')
    total_field_count_without_re_pricer_info = check_information.processor_input_field_count(facilities(:facility_1), 'insurance')
    assert_equal(total_field_count_with_re_pricer_info, 2)
    assert_equal(total_field_count_without_re_pricer_info, 1)
  end

  def test_total_paid_amount_when_all_amounts_are_present
    facility = facilities(:facility_25)
    check = check_informations(:check_71)
    observed_paid_amount = check.total_paid_amount(facility)
    assert_equal 150.00, observed_paid_amount
  end

  def test_total_paid_amount_when_payment_and_fund_and_filing_charge_are_absent
    facility = facilities(:facility_25)
    check = check_informations(:check_72)
    observed_paid_amount = check.total_paid_amount(facility)
    assert_equal 25.83, observed_paid_amount
  end

  def test_total_paid_amount_when_filing_charge_and_interest_and_provider_adjustment_are_absent
    facility = facilities(:facility_25)
    check = check_informations(:check_74)
    observed_paid_amount = check.total_paid_amount(facility)
    assert_equal 28.22, observed_paid_amount
  end

  def test_total_paid_amount_when_interest_is_captured_at_service_level_and_provider_adjustment_amount_is_absent
    facility = facilities(:facility8)
    check = check_informations(:check_75)
    observed_paid_amount = check.total_paid_amount(facility)
    assert_equal 95.67, observed_paid_amount
  end

  def test_for_balanced_check_71
    facility = facilities(:facility_25)
    check = check_informations(:check_71)
    is_check_balanced = check.is_check_balanced?(jobs(:job_75), (facility))
    assert_equal true, is_check_balanced
  end

  def test_for_balanced_check_72
    facility = facilities(:facility_25)
    check = check_informations(:check_72)
    is_check_balanced = check.is_check_balanced?(jobs(:job_76), facility)
    assert_equal true, is_check_balanced
  end

  def test_for_unbalanced_check_74
    facility = facilities(:facility_25)
    check = check_informations(:check_74)
    is_check_balanced = check.is_check_balanced?(jobs(:job_78), facility)
    assert_equal false, is_check_balanced
  end

  def test_for_unbalanced_parent_check_75
    facility = facilities(:facility8)
    check = check_informations(:check_75)
    is_check_balanced = check.is_check_balanced?(jobs(:job_79), facility)
    assert_equal false, is_check_balanced
  end

  def test_for_unbalanced_child_job_check_75
    facility = facilities(:facility8)
    check = check_informations(:check_75)
    is_check_balanced = check.is_check_balanced?(jobs(:job_80), facility)
    assert_equal true, is_check_balanced
  end

  def test_if_transaction_type_is_check_only
    check = check_informations(:check_70)
    observed_value = check.is_transaction_type_missing_check_or_check_only?
    assert_equal true, observed_value
  end

  def test_if_transaction_type_is_missing_check
    check = check_informations(:check_71)
    observed_value = check.is_transaction_type_missing_check_or_check_only?
    assert_equal true, observed_value
  end

  def test_if_transaction_type_is_complete_eob
    check = check_informations(:check_72)
    observed_value = check.is_transaction_type_missing_check_or_check_only?
    assert_equal false, observed_value
  end

  def test_if_transaction_type_is_not_present
    check = check_informations(:check_74)
    observed_value = check.is_transaction_type_missing_check_or_check_only?
    assert_equal false, observed_value
  end

  def test_processor_input_field_count_for_simplified_grid_without_payment_method
    check_information  = check_informations(:check_78)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 4)
  end

  def test_processor_input_field_count_for_simplified_grid_with_payment_method
    check_information  = check_informations(:check_78)
    total_field_count = check_information.processor_input_field_count(facilities(:facility8), 'simplified')
    assert_equal(total_field_count, 4)
  end

  def test_denial_transaction
    check_information  = check_informations(:denial_check_80)
    assert_equal(true, check_information.is_denial_transaction?)
  end

  def test_non_denial_transaction
    check_information  = check_informations(:non_denial_check_81)
    assert_equal(false, check_information.is_denial_transaction?)
  end

  def test_system_generated_check_number_is_not_present_for_insurance
    non_denial_check  = check_informations(:non_denial_check_81)
    assert_equal(false, non_denial_check.has_system_generated_check_number?)
  end

  def test_system_generated_check_number_is_present_for_insurance
    denial_check  = check_informations(:denial_check_80)
    assert_equal(true, denial_check.has_system_generated_check_number?)
  end

  def test_auto_generate_check_number_for_insurance
    denial_check  = check_informations(:denial_check_80)
    non_denial_check  = check_informations(:non_denial_check_81)
    denial_check.auto_generate_check_number
    non_denial_check.auto_generate_check_number
    saved_denial_check = CheckInformation.find(80)
    saved_non_denial_check = CheckInformation.find(81)
    assert_match("RX300412", saved_denial_check.check_number)
    assert_equal("0", saved_non_denial_check.check_number)
  end

  def test_system_generated_check_number_is_not_present_for_patpay
    non_denial_check  = check_informations(:non_denial_check_for_patient_pay_104)
    assert_equal(false, non_denial_check.has_system_generated_check_number?)
  end

  def test_system_generated_check_number_is_present_for_patpay
    denial_check  = check_informations(:denial_check_for_patient_pay_105)
    assert_equal(true, denial_check.has_system_generated_check_number?)
  end

  def test_auto_generate_check_number_for_patpay
    denial_check  = check_informations(:denial_check_for_patient_pay_105)
    non_denial_check  = check_informations(:non_denial_check_for_patient_pay_104)
    denial_check.auto_generate_check_number
    non_denial_check.auto_generate_check_number
    saved_denial_check = CheckInformation.find(105)
    saved_non_denial_check = CheckInformation.find(104)
    assert_match("RX210212", saved_denial_check.check_number)
    assert_equal("0", saved_non_denial_check.check_number)
  end
end
