require File.dirname(__FILE__) + '/../test_helper'

class PayerTest < ActiveSupport::TestCase
  fixtures :payers, :facilities, :users, :jobs, :check_informations,
    :reason_codes, :reason_codes_clients_facilities_set_names, :batches,
    :insurance_payment_eobs, :micr_line_informations, :payer_exclusions
  
  def setup
    set_up_configs
    @payer = Payer.new()
    facility_setup = facilities(:facility_setup_214)
    @facility_payids = {:commercial_payid => facility_setup.commercial_payerid,
      :patient_payid => facility_setup.patient_payerid}
  end

  def test_processor_input_field_count_with_all_data
    payer  = Payer.find(4)
    total_field_count = payer.processor_input_field_count
    assert_equal(total_field_count, 8)
  end
  
  def test_processor_input_field_count_with_no_data
    payer  = Payer.find(5)
    total_field_count = payer.processor_input_field_count
    assert_equal(total_field_count, 0)
  end  
  
  def test_processor_input_field_count_without_fcui_config_for_payer_tin
    payer  = Payer.find(12)
    total_field_count = payer.processor_input_field_count
    assert_equal(total_field_count, 5)
  end
  
  def test_processor_input_field_count_with_missing_data
    payer  = Payer.find(11)
    total_field_count = payer.processor_input_field_count
    assert_equal(total_field_count, 6)
  end
  
  def test_payer_id_that_contains_string_raises_record_not_found_error
    assert_nothing_raised(ActiveRecord::StatementInvalid) do
      Payer.payer_details("67 + holycross hospital + 45 + 213anotherstring",users(:aaron).id,jobs(:job1).id)
    end
  end
  
  def test_normal_payerid_scenario
    assert_nothing_raised(ActiveRecord::RecordNotFound) do
      Payer.payer_details("67 + holycross hospital + 45 + 213",users(:aaron).id,jobs(:job1).id)
    end
  end
  
  
  def test_regex_pattern
    a_str = "123"
    pattern = '/\w/'
    
    assert !(/[a-zA-Z]+/.match('6565anjana99AnJaNsa')).blank?
    assert (/[a-zA-Z]+/.match('656599')).blank?
    
  end 
  

  def test_payer_id_based_payer_exclusion
    payer = payers(:payer21_excluded_based_on_payerid)
    assert_equal true, payer.excluded?(facilities(:facility_with_some_payers_excluded))
  end

  def test_payer_with_micr_inclusion
    payer = payers(:payer20_not_excluded_has_micr)
    assert_equal false, payer.excluded?(facilities(:facility_with_some_payers_excluded))
  end

  def test_payer_with_out_micr_inclusion
    payer = payers(:payer22_not_excluded)
    assert_equal false, payer.excluded?(facilities(:facility_with_some_payers_excluded))
  end

  def test_mapped_accepted_payer
    payer = payers(:mapped_payer)
    is_payer_accepted = payer.accepted?
    assert_equal true, is_payer_accepted
  end
  
  def test_unmapped_accepted_payer
    payer = payers(:unmapped_payer)
    is_payer_accepted = payer.accepted?
    assert_equal true, is_payer_accepted
  end
  
  def test_approved_accepted_payer
    payer = payers(:approved_payer)
    is_payer_accepted = payer.accepted?
    assert_equal true, is_payer_accepted
  end
  
  def test_not_accepted_payer
    payer = payers(:not_accepted_payer)
    is_payer_accepted = payer.accepted?
    assert_equal false, is_payer_accepted
  end
  
  def test_threshold_condition_for_non_footnote
    payer = payers(:unclassified_non_footnote_payer)
    distinct_reason_codes = ['59', '60']
    footnote_indicator, payer_status = payer.run_threshold_condition_and_classify(@configs,
      distinct_reason_codes)
    assert_not_nil payer_status
    assert_equal false, footnote_indicator
    assert_equal "CLASSIFIED", payer_status
  end

  def test_threshold_condition_for_footnote
    payer = payers(:unclassified_footnote_payer)
    distinct_reason_codes = ['61', '62']
    footnote_indicator, payer_status = payer.run_threshold_condition_and_classify(@configs,
      distinct_reason_codes)
    assert_not_nil payer_status
    assert_equal true, footnote_indicator
    assert_equal "CLASSIFIED", payer_status
  end

  def do_not_test_min_reason_code_condition_for_non_footnote
    payer = payers(:unclassified_non_footnote_payer)
    payer.expects(:run_threshold_condition_and_classify).at_least_once.returns([false, 'CLASSIFIED'])
    footnote_indicator, payer_status = payer.run_min_reason_code_condition_and_classify(@configs)
    assert_not_nil payer_status
    assert_equal false, footnote_indicator
    assert_equal "CLASSIFIED", payer_status
  end

  def do_not_test_min_reason_code_condition_for_footnote
    payer = payers(:unclassified_footnote_payer)
    payer.expects(:run_threshold_condition_and_classify).at_least_once.returns([true, 'CLASSIFIED'])
    footnote_indicator, payer_status = payer.run_min_reason_code_condition_and_classify(@configs)
    assert_not_nil payer_status
    assert_equal true, footnote_indicator
    assert_equal "CLASSIFIED", payer_status
  end

  def test_min_eob_condition_for_non_footnote
    payer = payers(:unclassified_non_footnote_payer)
    payer.expects(:run_min_reason_code_condition_and_classify).at_least_once.returns([false, 'CLASSIFIED'])
    InsurancePaymentEob.expects(:count).at_least_once.returns(1)
    footnote_indicator, payer_status = payer.run_min_eob_condition_and_classify(@configs)
    assert_not_nil payer_status
    assert_equal false, footnote_indicator
    assert_equal "CLASSIFIED", payer_status
  end

  def test_min_eob_condition_for_footnote
    payer = payers(:unclassified_footnote_payer)
    payer.expects(:run_min_reason_code_condition_and_classify).at_least_once.returns([true, 'CLASSIFIED'])
    InsurancePaymentEob.expects(:count).at_least_once.returns(1)
    footnote_indicator, payer_status = payer.run_min_eob_condition_and_classify(@configs)
    assert_not_nil payer_status
    assert_equal true, footnote_indicator
    assert_equal "CLASSIFIED", payer_status
  end

  def do_not_test_classify_as_non_footnote
    payer = payers(:unclassified_non_footnote_payer)
    classified_payer = payer.classify(@configs)
    assert_equal false, classified_payer.footnote_indicator
    assert_equal 'CLASSIFIED', classified_payer.status
  end

  def do_not_test_classify_as_footnote
    payer = payers(:unclassified_footnote_payer)
    classified_payer = payer.classify(@configs)
    assert_equal true, classified_payer.footnote_indicator
    assert_equal 'CLASSIFIED', classified_payer.status
  end

  def test_no_classification_happened
    payer = payers(:new_payer_46)
    payer.expects(:run_min_eob_condition_and_classify).at_least_once.returns([nil, nil])
    expected_payer = payer.classify(@configs)
    assert_equal 'NEW', expected_payer.status
    assert_equal nil, expected_payer.footnote_indicator
  end

  def test_default_classification
    payer = payers(:unclassified_non_footnote_payer)
    footnote_indicator, payer_status = payer.default_classification
    assert_equal false, footnote_indicator
    assert_equal 'CLASSIFIED_BY_DEFAULT', payer_status
  end

  def test_force_classify_if_no_more_checks_to_process
    payer = payers(:payer_29)
    footnote_indicator, payer_status = payer.force_classify_if_no_more_checks_to_process
    assert_equal false, footnote_indicator
    assert_equal 'CLASSIFIED_BY_DEFAULT', payer_status
  end

  def test_do_not_force_classify_if_more_checks_to_process
    payer = payers(:payer_27)
    footnote_indicator, payer_status = payer.force_classify_if_no_more_checks_to_process
    assert_equal nil, footnote_indicator
    assert_equal nil, payer_status
  end

  def test_force_classify_for_urgent_batches
    Batch.expects(:count_of_urgent_batches_for_payer).at_least_once.returns(1)
    payer = payers(:payer_29)
    footnote_indicator, payer_status = payer.force_classify_for_urgent_batches(1.hours)
    assert_equal false, footnote_indicator
    assert_equal 'CLASSIFIED_BY_DEFAULT', payer_status
  end

  def test_do_not_force_classify_for_urgent_batches
    Batch.expects(:count_of_urgent_batches_for_payer).at_least_once.returns(0)
    payer = payers(:payer_29)
    footnote_indicator, payer_status = payer.force_classify_for_urgent_batches(1.hours)
    assert_equal false, footnote_indicator
    assert_equal 'CLASSIFIED_BY_DEFAULT', payer_status
  end

  def test_force_classify
    Batch.expects(:count_of_urgent_batches_for_payer).at_least_once.returns(0)
    payer = payers(:payer_29)
    footnote_indicator, payer_status = payer.force_classifiy(@configs)
    assert_equal false, footnote_indicator
    assert_equal 'CLASSIFIED_BY_DEFAULT', payer_status
  end

  def don_not_test_eob_and_reason_code_and_treshold_conditions_met_for_non_footnote
    payer = payers(:payer_33)
    classified_payer = payer.classify(@configs)
    assert_equal false, classified_payer.footnote_indicator
    assert_equal 'CLASSIFIED', classified_payer.status
  end

  def do_not_test_eob_and_reason_code_and_treshold_conditions_met_for_footnote
    payer = payers(:payer_34)
    classified_payer = payer.classify(@configs)
    assert_equal true, classified_payer.footnote_indicator
    assert_equal 'CLASSIFIED', classified_payer.status
  end

  def test_save_patient_payer_status_when_payer_is_not_same_as_patient
    check = check_informations(:check_36)
    payer = payers(:payer_43)
    saved_payer = payer.save_patient_payer_status_and_indicator(check)
    assert_equal 'CLASSIFIED', saved_payer.status
    assert_equal false, saved_payer.footnote_indicator
  end
  
  def test_save_patient_payer_status_when_payer_is_same_as_patient
    check = check_informations(:check_37)
    payer = payers(:payer_44)
    saved_payer = payer.save_patient_payer_status_and_indicator(check)
    assert_equal 'MAPPED', saved_payer.status
    assert_equal false, saved_payer.footnote_indicator
  end
  
  def test_save_patient_payer_status_when_payer_is_not_a_patient_payer
    check = check_informations(:check_35)
    payer = payers(:payer_34)
    saved_payer = payer.save_patient_payer_status_and_indicator(check)
    assert_equal 'NEW', saved_payer.status.to_s.upcase
    assert_equal nil, saved_payer.footnote_indicator
  end
  
  def test_payer_identification_for_mapped_payer
    payer = payers(:mapped_payer)
    micr = micr_line_informations(:micr6)
    payerid = payer.payer_identifier(micr)
    assert_equal '7710P', payerid
  end
  
  def test_payer_identification_in_upcase_for_mapped_payer
    payer = payers(:mapped_payer)
    micr = micr_line_informations(:micr6)
    payerid = payer.payer_identifier(micr)
    assert_not_equal '7710p', payerid
  end
  
  def test_payer_identification_for_non_mapped_payer
    payer = payers(:not_accepted_payer)
    micr = micr_line_informations(:micr6)
    payerid = payer.payer_identifier(micr)
    assert_equal '88301', payerid
  end
  
  
  # This is an invalid test, it is not clear what it is testing so ntesting it
  def test_payer_address_dto
    payer = Payer.find(:first, :order=>'rand()')
    dto = payer.payer_address_dto
    assert_equal(dto.streetAddressLine1, payer.address_one)
    assert_equal(dto.streetAddressLine2, payer.address_two)
    assert_equal(dto.streetAddressLine3, payer.pay_address_three)
    assert_equal(dto.cityNm, payer.city)
    assert_equal(dto.stateCode, payer.state)
    assert_equal(dto.zipCode, payer.zip_code)
    assert_equal(dto.companyWebsite, payer.website)
  end

  def test_payid
    payer = payers(:payer_220)
    micr = micr_line_informations(:micr_7)
    assert_equal(micr.payid_temp, payer.payid)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_payid of a commercial payer.  |
  # Input  : Payer type of payer is "Commercial".                              |
  # Output : Commercial payid from facilty .                                   |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_payid_of_commercial_payer
    payer_type = 'Commercial'
    assert_equal("D9998", @payer.get_payid(payer_type,@facility_payids))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_payid of a patpay payer.      |
  # Input  : Payer type of payer is "PatPay".                                  |
  # Output : Patient payid from facilty .                                      |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_payid_of_patpay_payer
    payer_type = 'PatPay'
    assert_equal("P9998", @payer.get_payid(payer_type,@facility_payids))
  end



  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as check_payer_status                |
  # Input1  : Commercial payer                                                 |
  # Input2  : Patpay payer                                                     |
  # Input3  :Actual Payer(payid from AP- not D9998 & P9998) with status as blank
  #          and footnote indicator is not blank.                              |
  # Output1 : Status of Commercial payer .                                     |
  # Output2 : Status of Patient Payer.                                         |
  # Output3 : Status as "MAPPED"                                               |
  # Owner   : Ramya Periyangat                                                 |
  # Modified by: Ramya                                                         |
  # +--------------------------------------------------------------------------+
  def test_check_payer_status
    commercial_payer = payers(:payer_225)
    patpay_payer = payers(:payer_222)
    actual_payer = payers(:payer_226)
    assert_equal("NEW", commercial_payer.check_payer_status(@facility_payids))
    assert_equal("NEW", patpay_payer.check_payer_status(@facility_payids))
    assert_equal("MAPPED", actual_payer.check_payer_status(@facility_payids))
  end

  def test_classification_of_new_payer_for_non_bac
    payer = payers(:unclassified_footnote_payer)
    facility = ''
    is_partner_bac = false
    saved_payer = payer.commence_classification(is_partner_bac, facility)
    assert_equal false, saved_payer.footnote_indicator
    assert_equal 'CLASSIFIED_BY_DEFAULT', saved_payer.status
  end

  def test_classification_of_classified_payer_for_non_bac
    payer = payers(:classified_footnote_payer)
    facility = ''
    is_partner_bac = false
    saved_payer = payer.commence_classification(is_partner_bac, facility)
    assert_equal nil, saved_payer
  end

  def test_cleanup_reason_codes_before_reclassification_of_footnote_payer_to_nonfootnote_payer
    footnote_payer = payers(:payer_to_reclassify_49)
    new_footnote_indicator = false
    cleaned_up = footnote_payer.cleanup_reason_codes_before_reclassification(new_footnote_indicator)
    assert_equal true, cleaned_up

    retained_reason_code = ReasonCode.find(reason_codes(:reason_code103).id)
    soft_deleted_reason_code_1 = ReasonCode.find(reason_codes(:reason_code104).id)
    soft_deleted_reason_code_2 = ReasonCode.find(reason_codes(:reason_code105).id)
    assert_equal true, retained_reason_code.active
    assert_equal soft_deleted_reason_code_1.replacement_reason_code_id, retained_reason_code.id
    assert_equal soft_deleted_reason_code_2.replacement_reason_code_id, retained_reason_code.id
    assert_equal false, soft_deleted_reason_code_1.active
    assert_equal false, soft_deleted_reason_code_2.active
  end

  def test_cleanup_reason_codes_before_reclassification_of_nonfootnote_payer_to_footnote_payer
    nonfootnote_payer = payers(:payer_to_reclassify_51)
    new_footnote_indicator = true
    cleaned_up = nonfootnote_payer.cleanup_reason_codes_before_reclassification(new_footnote_indicator)
    assert_equal true, cleaned_up

    retained_reason_code = ReasonCode.find(reason_codes(:reason_code106).id)
    soft_deleted_reason_code_1 = ReasonCode.find(reason_codes(:reason_code107).id)
    soft_deleted_reason_code_2 = ReasonCode.find(reason_codes(:reason_code108).id)
    assert_equal true, retained_reason_code.active
    assert_equal soft_deleted_reason_code_1.replacement_reason_code_id, retained_reason_code.id
    assert_equal soft_deleted_reason_code_2.replacement_reason_code_id, retained_reason_code.id
    assert_equal false, soft_deleted_reason_code_1.active
    assert_equal false, soft_deleted_reason_code_2.active
  end

  def test_not_to_cleanup_reason_codes_before_reclassification_for_payer_with_nil_footnote_indicator
    payer = payers(:payer_with_nil_footnote_indicator)
    new_footnote_indicator = true
    result = payer.cleanup_reason_codes_before_reclassification(new_footnote_indicator)
    assert_equal true, result
  end

  def test_get_default_payer_address_when_atleast_one_of_the_address_field_is_blank
    check = check_informations(:check_61)
    payer = payers(:non_patpay_payer)
    facility = facilities(:facility_2)
    expected_default_payer_address = {
      :address_one => 'ADDRESS ONE',
      :city => 'PAYER CITY',
      :state => 'SS',
      :zip_code => '00099'
    }
    obtained_default_payer_address = payer.default_payer_address(facility, check)
    assert_equal expected_default_payer_address, obtained_default_payer_address
  end

  def test_get_default_payer_address_when_all_of_the_address_fields_are_blank
    check = check_informations(:check_61)
    payer = payers(:payer_with_nil_footnote_indicator)
    facility = facilities(:facility_2)
    expected_default_payer_address = {
      :address_one => 'ADDRESS ONE',
      :city => 'PAYER CITY',
      :state => 'SS',
      :zip_code => '00099'
    }
    obtained_default_payer_address = payer.default_payer_address(facility, check)
    assert_equal expected_default_payer_address, obtained_default_payer_address
  end

  def test_get_default_payer_address_when_none_of_the_address_fields_are_blank
    check = check_informations(:check_61)
    payer = payers(:payer1)
    facility = facilities(:facility_2)
    expected_default_payer_address = nil
    obtained_default_payer_address = payer.default_payer_address(facility, check)
    assert_equal expected_default_payer_address, obtained_default_payer_address
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_payer_type(payid)             |
  # Input  : Payid and Patpay payer.                                           |
  # Output : Payer type will be 'Patpay' .                                     |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_payer_type_for_patpay_payer
    payid = '78787'
    payer = payers(:payer_221)
    assert_equal('PatPay', payer.get_payer_type(payid))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_payer_type(payid)             |
  # Input  : FC UI Commercial Payid and Commercial payer.                      |
  # Output : Payer type will be 'Commercial' .                                 |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_payer_type_for_commercial_payer
    payid = 'D9998'
    payer = payers(:payer_222)
    assert_equal('Commercial', payer.get_payer_type(payid))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_payer_type(payid)             |
  # Input  : Payid and Commercial payer.                                       |
  # Output : Payer type will be Id of the Commercial payer record.             |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_payer_type_for_insurance_payer
    payid = 'I8888'
    payer = payers(:payer_222)
    assert_equal(222, payer.get_payer_type(payid))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the the presence of payid                              |
  # Input  : A new payer without payid                                         |
  # Output : Return false while saving                                         |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_validate_presence_of_payid
    payer = Payer.new(:payer => "Payer without Payid")
    assert_equal(false, payer.save, "Payer ID can't be blank!")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_gateway of a payer for BAC .  |
  # Input  : Partner is BAC.                                                   |
  # Output : Returns gateway as "HLSC" .                                       |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_gateway_of_payer_for_bac
    $IS_PARTNER_BAC = truee
    assert_equal("HLSC", @payer.get_gateway(is_partner_bac))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as get_gateway of a payer for Non BAC.|
  # Input  : Partner is Non BAC.                                               |
  # Output : Returns gateway as "REVMED" .                                     |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_get_gateway_of_payer_for_bac
    $IS_PARTNER_BAC = false
    assert_equal("REVMED", @payer.get_gateway(is_partner_bac))
  end

  private
  def set_up_configs
    facility = facilities(:facility_with_payer_classification_config)
    @configs = {}
    @configs[:min_reason_codes] = facility.details[:min_reason_codes]
    @configs[:min_percentage_of_reason_codes] = facility.details[:min_percentage_of_reason_codes]
    @configs[:min_number_of_eobs] = facility.details[:min_number_of_eobs]
    @configs[:threshold_time_to_tat] = facility.details[:threshold_time_to_tat]
    @configs
  end

end
