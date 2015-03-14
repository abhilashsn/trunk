require File.dirname(__FILE__) + '/../test_helper'
require 'mocha/setup'

class InsurancePaymentEOBTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :jobs, :batches,
    :facilities, :reason_codes, :reason_codes_clients_facilities_set_names,
    :payers, :hipaa_codes, :service_payment_eobs, :default_codes_for_adjustment_reasons,
    :clients, :partners, :images_for_jobs, :image_types, 
    :insurance_payment_eobs_reason_codes, :service_payment_eobs_reason_codes,
    :facility_output_configs

  def setup
    Partner.expects(:is_partner_bac?).returns(false)
  end
  
  def test_processor_input_field_count_for_claim_level_with_fcui_config_true_for_service_from_date
    insurance_payment_eob = InsurancePaymentEob.find(111)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility8))
    assert_equal(total_field_count, 53)
  end
  
  def test_processor_input_field_count_for_claim_level_with_fcui_config_false_for_service_from_date
    insurance_payment_eob = insurance_payment_eobs(:ins_pay_eob_8)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_1))
    assert_equal(total_field_count, 43)
  end
  
  def test_processor_input_field_count_for_claim_level_with_fcui_config_true_for_denied
    insurance_payment_eob = InsurancePaymentEob.find(111)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility8))
    assert_equal(total_field_count, 53)
  end
  
  def test_processor_input_field_count_for_claim_level_with_fcui_config_false_for_denied
    insurance_payment_eob = InsurancePaymentEob.find(111)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_2))
    assert_equal(total_field_count, 51)
  end
  
  #If there is no provider tin, but in FC UI,then count
  def test_processor_input_field_count_for_claim_level_without_provider_tin
    insurance_payment_eob = InsurancePaymentEob.find(8)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_1))
    assert_equal(total_field_count, 43)
  end
  
  #If there is no provider npi, but in FC UI,then count
  def test_processor_input_field_count_for_claim_level_without_provider_npi
    insurance_payment_eob = InsurancePaymentEob.find(8)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_1))
    assert_equal(total_field_count, 43)
  end
  
  def test_processor_input_field_count_for_claim_level_without_fcui_config_fields
    insurance_payment_eob = InsurancePaymentEob.find(8)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_1))
    assert_equal(total_field_count, 43)
  end
  
  def test_processor_input_field_count_for_claim_level_with_fcui_config_fields
    insurance_payment_eob = InsurancePaymentEob.find(111)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility8))
    assert_equal(total_field_count, 53)
  end
  
  def test_processor_input_field_count_for_service_level_with_fcui_config_fields
    insurance_payment_eob = InsurancePaymentEob.find(6)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility8))
    assert_equal(total_field_count, 31)
  end
  
  def test_processor_input_field_count_for_service_level_without_fcui_config_fields
    insurance_payment_eob = InsurancePaymentEob.find(7)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_1))
    assert_equal(total_field_count, 27)
  end
  
  def test_processor_input_field_count_for_service_level_without_provider_tin
    insurance_payment_eob = InsurancePaymentEob.find(6)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_3))
    assert_equal(total_field_count, 33)
  end
  
  def test_processor_input_field_count_for_service_level_without_provider_npi
    insurance_payment_eob = InsurancePaymentEob.find(6)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_3))
    assert_equal(total_field_count, 33)
  end
  
  def test_processor_input_field_count_for_five_new_fields_with_data
    insurance_payment_eob = InsurancePaymentEob.find(16)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_25))
    assert_equal(total_field_count, 7)
  end
  
  def test_processor_input_field_count_for_five_new_fields_without_data
    insurance_payment_eob = InsurancePaymentEob.find(77)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_26))
    assert_equal(total_field_count, 1)
  end
  
  def test_claim_status_code_for_no_reason_code
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(32)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_is_secondary_for_ppp_non_zero
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(18)
    assert_equal('2', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_is_denial_for_zero_total_coinsurance_and_deductible_and_payment
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(22)
    assert_equal('4', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_is_reversal_for_negative_total_charge_and_total_payment
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(21)
    assert_equal('22', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_zero_pay_claim_having_crosswalk_with_denied_and_normal_claim_status_code_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(26)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_zero_pay_claim_having_crosswalk_with_denied_status_code_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(24)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_zero_pay_claim_having_crosswalk_with_claim_status_code_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(25)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_service_eob_having_crosswalk_with_mapped_code_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(19)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_service_eob_having_crosswalk_with_denied_status_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(24)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_service_eob_having_crosswalk_with_claim_status_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(25)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_claim_status_code_for_service_eob_having_crosswalk_with_denied_and_normal_claim_status_code_nil
    client = clients(:Apria)
    facility = facilities(:facility1)
    insurance_payment_eob = InsurancePaymentEob.find(27)
    assert_equal('1', insurance_payment_eob.claim_status_code(client, facility))
  end
  
  def test_zero_payment
    svc_line = insurance_payment_eobs(:svc_line_with_zero_payment)
    assert_equal true, svc_line.zero_payment?
  end
  
  def test_non_zero_payment
    svc_line = insurance_payment_eobs(:svc_line_with_non_zero_payment)
    assert_equal false, svc_line.zero_payment?
  end
  
  def test_reason_codes
    svc_line = insurance_payment_eobs(:svc_with_reason_codes)
    svc_line.expects(:adjustment_reason_elements).returns(['coinsurance'])
    facility = facilities(:facility_with_rcc_crosswalk_and_default_cas_code)
    payer = payers(:payer17)
    reason_codes = svc_line.reason_codes_for_service_line(facility, payer)
    assert_not_nil reason_codes
    assert_equal ['RC1'], reason_codes
  end
  
  def test_patient_name
    patient_1 = insurance_payment_eobs(:eob_35)
    patient_2 = insurance_payment_eobs(:eob_36)
    patient_3 = insurance_payment_eobs(:eob_37)
    patient_4 = insurance_payment_eobs(:eob_38)
    patient_name_1 = patient_1.patient_name
    patient_name_2 = patient_2.patient_name
    patient_name_3 = patient_3.patient_name
    patient_name_4 = patient_4.patient_name
    assert_equal 'FIRST M LAST S', patient_name_1
    assert_equal 'FIRST LAST', patient_name_2
    assert_equal '', patient_name_3
    assert_equal '', patient_name_4
  end
  
  def test_is_payer_indicator_present?
    eob_with_payer_united = insurance_payment_eobs(:eob_41)
    eob_with_payer_aetna_1 = insurance_payment_eobs(:eob_42)
    eob_with_payer_aetna_2 = insurance_payment_eobs(:eob_43)
    eob_with_no_payer = insurance_payment_eobs(:eob_44)
    assert_equal(eob_with_payer_united.is_payer_indicator_present?, true)
    assert_equal(eob_with_payer_aetna_1.is_payer_indicator_present?, true)
    assert_equal(eob_with_payer_aetna_2.is_payer_indicator_present?, true)
    assert_equal(eob_with_no_payer.is_payer_indicator_present?, false)
  end
  
  def test_processor_input_field_count_for_payer_indicator
    eob = insurance_payment_eobs(:eob_41)
    facility = Facility.find(27)
    assert_equal(eob.is_payer_indicator_present?, true)
    assert_equal(eob.processor_input_field_count(facility), 1)
  end
  
  def test_image_file_name
    eob = insurance_payment_eobs(:ins_pay_eob_2215)
    assert_equal(images_for_jobs(:img_for_jb11).filename, eob.image_file_name)
  end
  
  def test_compute_claim_status_code_for_default_code_from_facility
    eob = insurance_payment_eobs(:eob_48)
    facility = facilities(:facility_91)
    crosswalked_codes = {}
    status_code = eob.compute_claim_status_code(facility, crosswalked_codes)
    assert_equal '1', status_code
  end
  
  def test_get_primary_reason_code_ids_of_eob
    eob = insurance_payment_eobs(:ins_pay_eob_for_gcbs_49)
    assert_equal([72,74,74,75], eob.get_primary_reason_code_ids_of_eob)
  end
  
  def test_get_reason_code_ids_of_eob_and_svc_of_a_job_claim_level
    eob = insurance_payment_eobs(:ins_pay_eob_for_gcbs_49)
    assert_equal([72,74,75,80], eob.get_reason_code_ids_of_eob_and_svc_of_a_job)
  end
  
  def test_get_reason_code_ids_of_eob_and_svc_of_a_job_service_level
    eob = insurance_payment_eobs(:ins_pay_eob__for_pm_facility_50)
    assert_equal([76,78,77,80], eob.get_reason_code_ids_of_eob_and_svc_of_a_job)
  end
  
  def test_get_customized_claim_type_as_primary_even_if_837_claim_type_is_secondary
    eob = insurance_payment_eobs(:eob_52)
    sitecode = nil
    expected_claim_type = '1'
    obtained_claim_type = eob.get_customized_claim_type(sitecode)
    assert_equal expected_claim_type, obtained_claim_type
  end
  
  def test_get_customized_claim_type_secondary_when_ppp_is_present
    eob = insurance_payment_eobs(:eob_53)
    sitecode = nil
    expected_claim_type = '2'
    obtained_claim_type = eob.get_customized_claim_type(sitecode)
    assert_equal expected_claim_type, obtained_claim_type
  end
  
  def test_get_customized_claim_type_tertiary_from_837_for_site_00895
    eob = insurance_payment_eobs(:eob_54)
    sitecode = '00895'
    expected_claim_type = '3'
    obtained_claim_type = eob.get_customized_claim_type(sitecode)
    assert_equal expected_claim_type, obtained_claim_type
  end
  
  def test_no_to_get_customized_claim_type_tertiary_from_837_for_sites_other_than_00895
    eob = insurance_payment_eobs(:eob_54)
    sitecode = '99999'
    expected_claim_type = '2'
    obtained_claim_type = eob.get_customized_claim_type(sitecode)
    assert_equal expected_claim_type, obtained_claim_type
  end
  
  def test_claim_status_code_for_site_00895
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00895'
    facility.sitecode = '00895'
    eob = insurance_payment_eobs(:eob_53)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00k39
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00K39'
    facility.sitecode = '00K39'
    eob = insurance_payment_eobs(:eob_53)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00985
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00985'
    facility.sitecode = '00985'
    eob = insurance_payment_eobs(:eob_54)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00986
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00986'
    facility.sitecode = '00986'
    eob = insurance_payment_eobs(:eob_54)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00987
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00987'
    facility.sitecode = '00987'
    eob = insurance_payment_eobs(:eob_53)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00988
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00988'
    facility.sitecode = '00988'
    eob = insurance_payment_eobs(:eob_54)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00989
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00989'
    facility.sitecode = '00989'
    eob = insurance_payment_eobs(:eob_54)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00k22
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00K22'
    facility.sitecode = '00K22'
    eob = insurance_payment_eobs(:eob_54)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  def test_claim_status_code_for_site_00k23
    client = clients(:client_16)
    facility = Facility.new
    facility.name = 'Site_00K23'
    facility.sitecode = '00K23'
    eob = insurance_payment_eobs(:eob_54)
    code = eob.claim_status_code(client, facility)
    assert_equal '2', code
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_name'.          |
  # -- Patient First Name and Patient Last Name should contain alphabets/numbers/
  # -- hyphens/periods only                                                    |
  # Input  : Patient_first_name, patient_last_name and patient_middle_initial  |
  #          with invalid special characters.                                  |
  # Output : Error message will return if eob is not valid.                    |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_by_giving_invalid_data
    eob = InsurancePaymentEob.new
    eob.patient_first_name = "gh%gh"
    eob.patient_last_name = "hj*gfhj"
    eob.patient_middle_initial = "hj89"
    eob.save
    assert !eob.valid?, eob.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_name'.          |
  # -- Patient First Name and Patient Last Name should contain alphabets/numbers/
  # -- hyphens/periods only                                                    |
  # Input  : Patient_first_name and patient_last_name contain valid data and   |
  #          patient_middle_initial contains invalid data.                     |
  # Output : Error message will return if eob is not valid.                    |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_by_giving_invalid_middle_initial
    eob = InsurancePaymentEob.new
    eob.patient_first_name = "gh.gh"
    eob.patient_last_name = "h-gfhj"
    eob.patient_middle_initial = "hj89"
    eob.save
    assert !eob.valid?, eob.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_name'.          |
  # -- Patient First Name and Patient Last Name should contain alphabets/numbers/
  # -- hyphens/periods only                                                    |
  # Input  : Patient_first_name and patient_last_name contain valid data and   |
  #          patient_middle_initial contains valid data.                       |
  # Output : Returns true.                                                     |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_by_giving_valid_data
    eob = InsurancePaymentEob.new
    eob.patient_first_name = "gh.gh"
    eob.patient_last_name = "h-gfhj"
    eob.patient_middle_initial = "hj"
    eob.save
    assert eob.valid?, eob.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_name'.          |
  # -- Patient First Name and Patient Last Name should contain alphabets/numbers/
  # -- hyphens/periods only                                                    |
  # Input  : Patient_first_name and patient_last_name with consecutive occurrence
  #  of valid special characters and patient_middle_initial with valid data.   |
  # Output : Returns error message if eob is not valid.                                                     |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_name_with_consecutive_occurrence_of_valid_special_characters
    eob = InsurancePaymentEob.new
    eob.patient_first_name = "gh..gh"
    eob.patient_last_name = "h--gfhj"
    eob.patient_middle_initial = "hj"
    eob.save
    assert !eob.valid?, eob.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_account_number'.|
  # -- Patient Account Number should contain alphabets/numbers/hyphens/        |
  # -- /periods only                                                           |
  # Input  : valid patient_account_number.                                     |
  # Output : Returns true.                                                     |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_account_number_by_giving_valid_data
    eob = InsurancePaymentEob.new
    eob.patient_account_number= "gh.gh-89"
    eob.save
    assert eob.valid?, eob.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_account_number'.|
  # -- Patient Account Number should contain alphabets/numbers/hyphens/        |
  # -- /periods only                                                           |
  # Input  : Invalid patient_account_number.                                   |
  # Output : Returns error message if eob is not valid.                        |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_account_number_by_giving_invalid_data
    eob = InsurancePaymentEob.new
    eob.patient_account_number = "gh.gh-&&89"
    eob.save
    assert !eob.valid?, eob.errors.full_messages.to_s
  end
  
  # +--------------------------------------------------------------------------+
  # This is for testing a custom validation, 'validate_patient_account_number'.|
  # -- Patient Account Number should contain alphabets, numbers, hyphens       |
  # -- and periods only                                                        |
  # Input  : Patient_account_number with consecutive occurrence of valid special
  #          characters.                                                       |
  # Output : Returns error message if eob is not valid.                        |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_validate_patient_account_number_with_consecutive_occurrence_of_valid_special_characters
    eob = InsurancePaymentEob.new
    eob.patient_account_number = "gh..gh"
    eob.save
    assert !eob.valid?, eob.errors.full_messages.to_s
  end
  
  # Tests for the payment_amount_for_output method written in insurance_payment_eob model
  
  def test_payment_amount_for_output_with_sum_of_interest_and_payment
    eob = insurance_payment_eobs(:eob_57)
    facility = facilities(:facility_94)
    facility_output_config = facility_output_configs(:facility_config_226)
    total_payment_amount_for_output = eob.payment_amount_for_output(facility, facility_output_config)
    assert_equal(total_payment_amount_for_output, 48.00)
  end
  
  def test_payment_amount_for_output_with_payment_only
    eob = insurance_payment_eobs(:eob_58)
    facility = facilities(:facility_95)
    facility_output_config = facility_output_configs(:facility_config_227)
    total_payment_amount_for_output = eob.payment_amount_for_output(facility, facility_output_config)
    assert_equal(total_payment_amount_for_output, 100.00)
  end
  
  def test_least_date_for_eob_svc_line
    insurance_payment_eob1 = insurance_payment_eobs(:eob_68)
    insurance_payment_eob2 = insurance_payment_eobs(:eob_69)
    least_service_line1 = insurance_payment_eob1.least_date_for_eob_svc_line
    least_service_line2 = insurance_payment_eob2.least_date_for_eob_svc_line
    assert_equal(least_service_line1, Date.parse('2011-09-11'))
    assert_equal(least_service_line2, Date.parse('2011-09-08'))
  end
  
  # +--------------------------------------------------------------------------+
  # Testing processor_field count for claim level eobs with adjustment amounts.
  # Input: an eob with primary and secondary RCS.
  # Output: For bank, count will be 9 as it counts secondary RCs along with others.
  #         For bank, count will be 8 as it counts only primary RCs along with others.
  #Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_processor_input_field_count_for_claim_level_with_adjustment_amounts
    insurance_payment_eob = insurance_payment_eobs(:ins_pay_eob_for_gcbs_49)
    total_field_count = insurance_payment_eob.processor_input_field_count(facilities(:facility_1))
    if $IS_PARTNER_BAC
      assert_equal(total_field_count, 9)
    else
      assert_equal(total_field_count, 8)
    end
  end

end

