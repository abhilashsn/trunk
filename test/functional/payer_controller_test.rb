require File.dirname(__FILE__)+'/../test_helper'
require 'application_controller'

class PayerControllerTest < ActionController::TestCase
  fixtures :payers, :micr_line_informations, :check_informations,
    :facilities, :facilities_micr_informations, :facilities_payers_informations
  def setup
    @controller = Admin::PayerController.new
  end
  
  def test_list_build_condition_condition_not_blank
    my_session = {:search_Field => payers(:payer18).gateway,:criteria => 'Gateway'}
    assert_not_nil(get :list_build_condition,{},my_session)
  end

  def test_create_facilities_micr_information
    @controller.instance_variable_set("@micr_line_information", micr_line_informations(:micr2))
    facilities_micr_information = @controller.create_facilities_micr_information("onbase name",3 )
    assert_equal("onbase name", facilities_micr_information.onbase_name)
  end

  def test_update_facilities_micr_information
    @controller.instance_variable_set("@micr_line_information", micr_line_informations(:micr2))
    facilities_micr_information_before_update = facilities_micr_informations(:facilities_micr_info_1)
    facilities_micr_information_after_update = @controller.update_facilities_micr_information(facilities_micr_information_before_update.id, "MISSING CHECK", 2 )
    assert_equal("MISSING CHECK", facilities_micr_information_after_update.onbase_name)
  end
  def test_presence_of_values_in_export_payer
    payer = @controller.export_payer
    assert_not_nil(payer.first)
  end

  def test_export_payer_with_payid
    payer = @controller.export_payer
    assert_equal( "222", payer.first.payid)
  end

  def test_export_payer_with_allowance_code
    payer = @controller.export_payer
    assert_equal( "INPATIENT", payer.first.ip_payment_code )
    assert_equal( "OUT", payer.first.op_allowance_code)
  end

  def test_export_payer_with_onbase_name
    payer = @controller.export_payer
    assert_equal("TEST",payer.first.onbase_name)
  end

  # Test for payer address
  
  def test_valid_payer
    payer_details = { 
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '112233445',
      :payer_account_number => '112233445'
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :payer_type => 'Insurance',
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'}
    }
    $IS_PARTNER_BAC = false
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = Payer.find_by_payer('Valid Payer')
    set_name = payer.reason_code_set_name
    assert_equal 'D0009', set_name.name
  end

  def test_address_to_be_invalid_when_address_is_blank
    payer_details = {
      :payer => '',
      :pay_address_one => '',
      :pay_address_two => '',
      :payer_city => '',
      :payer_state => '',
      :payer_zip => '',
      :payid => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = "Please enter full and valid payer address fields."
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  def test_address_to_be_invalid_when_half_of_address_is_blank
    payer_details = {
      :payer => 'payer',
      :pay_address_one => 'add one',
      :pay_address_two => '',
      :payer_city => '',
      :payer_state => '',
      :payer_zip => '12345',
      :payid => '2343'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = "Please enter full and valid payer address fields."
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  def test_address_to_be_invalid_when_zip_code_and_state_are_invalid_data
    payer_details = {
      :payer => 'Payer 1',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SSGG',
      :payer_zip => '123456',
      :payid => '34534'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = "Please enter full and valid payer address fields."
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  # Testing the payer payid
  
  def test_validate_payid_to_be_false_when_payid_is_blank
    payer_details = {
      :payer => 'Payer 1',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = 'Payer ID cannot be blank.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  # Testing insurance payer duplication
  
  def test_not_creation_of_duplicate_payer_when_actual_payer_is_approved
    payer_details = {      
      :payer => 'Duplicate Payer 1',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {      
      :aba_routing_number => '121121121',
      :payer_account_number => '121121121'
    }
    get :save_payer_and_its_related_attributes, {
      :micr_id => '9',
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = 'Another payer has this MICR. Please provide valid data.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  def test_deletion_of_duplicate_payer_with_check_and_micr_when_actual_payer_is_approved
    payer_details = {      
      :payer => 'Duplicate Payer 2',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'C9998'
    }
    micr_details = {      
      :aba_routing_number => '100001111',
      :payer_account_number => '100001111'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '62',
      :micr_id => '11',
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = 'This payer was duplicate, hence was not created / updated.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payers = Payer.find_all_by_payer('Duplicate Payer 2')
    payer = payers.first    
    assert_equal 1, payers.length
    assert_equal 'PO BOX 1479', payer.address_one

    set_name_of_duplicate_payer = ReasonCodeSetName.find_by_name('DEFAULT_62')
    set_name_of_actual_payer = payer.reason_code_set_name
    assert_nil set_name_of_duplicate_payer
    assert_equal 'C9998', set_name_of_actual_payer.name

    checks = payer.check_informations
    assert_equal 2, checks.length
    check_of_duplicate_payer = CheckInformation.find(97)
    assert_equal '61', check_of_duplicate_payer.payer_id

    micrs = payer.micr_line_informations
    assert_equal 2, micrs.length
    micr_of_duplicate_payer = MicrLineInformation.find(11)
    assert_equal '61', micr_of_duplicate_payer.payer_id
  end

  def test_deletion_of_duplicate_payer_without_check_and_micr_when_actual_payer_is_approved
    payer_details = {      
      :payer => 'Duplicate Payer 3',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'C9998'
    }
    micr_details = {      
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '64',
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = 'This payer was duplicate, hence was not created / updated.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payers = Payer.find_all_by_payer('Duplicate Payer 3')
    payer = payers.first
    assert_equal 1, payers.length
    assert_equal 'PO BOX 1479', payer.address_one

    set_name_of_duplicate_payer = ReasonCodeSetName.find_by_name('DEFAULT_62')
    set_name_of_actual_payer = payer.reason_code_set_name
    assert_nil set_name_of_duplicate_payer
    assert_equal 'C9998', set_name_of_actual_payer.name

    checks = payer.check_informations
    assert_equal 1, checks.length
    check_of_duplicate_payer = CheckInformation.find(97)
    assert_equal '63', check_of_duplicate_payer.payer_id

    micrs = payer.micr_line_informations
    assert_equal 1, micrs.length
    micr_of_duplicate_payer = MicrLineInformation.find(11)
    assert_equal '63', micr_of_duplicate_payer.payer_id
  end

  def test_updation_of_duplicate_payer_with_check_and_micr_when_actual_payer_is_not_approved
    payer_details = {      
      :payer => 'Duplicate Payer 4',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'C9998'
    }
    micr_details = {
      :aba_routing_number => '100111100',
      :payer_account_number => '100111100'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '66',
      :micr_id => '13',
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payers = Payer.find_all_by_payer('Duplicate Payer 4')
    assert_equal 2, payers.length
    existing_payer_array = Payer.find_all_by_payer_and_payid('Duplicate Payer 4', 'D9998')
    duplicate_payer_array = Payer.find_all_by_payer_and_payid('Duplicate Payer 4', 'C9998')
    existing_payer = existing_payer_array.first
    duplicate_payer = duplicate_payer_array.first
    assert_not_nil existing_payer
    assert_not_nil duplicate_payer

    
    set_name_of_actual_payer = existing_payer.reason_code_set_name
    set_name_of_duplicate_payer = duplicate_payer.reason_code_set_name
    assert_equal 'DEFAULT_65', set_name_of_actual_payer.name
    assert_equal 'C9998', set_name_of_duplicate_payer.name

    check_of_duplicate_payer = CheckInformation.find(102)
    assert_equal 66, check_of_duplicate_payer.payer_id

    micr_of_duplicate_payer = MicrLineInformation.find(13)
    assert_equal 66, micr_of_duplicate_payer.payer_id
  end

  def test_updation_of_duplicate_patpay_payer_with_check_and_micr_when_actual_payer_is_approved
    payer_details = {      
      :payer => 'Duplicate PatPay Payer',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'P9998'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '68',
      :payer => payer_details,
      :payer_type => 'PatPay',
      :micr_line_information => micr_details
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payers = Payer.find_all_by_payer('Duplicate PatPay Payer')
    existing_payer = payers[0]
    duplicate_payer = payers[1]
    assert_equal 2, payers.length
    assert_not_nil existing_payer
    assert_not_nil duplicate_payer


    set_name_of_actual_payer = existing_payer.reason_code_set_name
    set_name_of_duplicate_payer = duplicate_payer.reason_code_set_name
    assert_equal 'DEFAULT_67', set_name_of_actual_payer.name
    assert_equal 'DEFAULT_68', set_name_of_duplicate_payer.name

    check_of_duplicate_payer = CheckInformation.find(103)
    assert_equal 68, check_of_duplicate_payer.payer_id
  end

  # Testing MICR uniqueness
  
  def test_validate_for_micr_duplication_to_be_false
    payer_details = {
      :payer => 'Payer with micr',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '121234345',
      :payer_account_number => '121234345'
    }
    get :save_payer_and_its_related_attributes, {
      :micr_id => '8',
      :payer => payer_details,
      :micr_line_information => micr_details
    }
    expected_error_message = 'Another payer has this MICR. Please provide valid data.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  # Testing payer type change
  
  def test_validation_to_pass_for_change_payer_type_while_creating_a_new_payer
    payer_details = {
      :payer => 'Payer',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :payer_type => 'Insurance',
      :micr_line_information => micr_details
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  def test_for_change_payer_type_of_a_insurance_payer_with_eobs
    payer_details = {      
      :payer => 'Payer 56',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '56',
      :payer => payer_details,
      :payer_type => 'PatPay',
      :micr_line_information => micr_details
    }
    expected_error_message = 'Please delete the EOBs attached for this payer to change the payer type'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  def test_for_change_payer_type_of_a_patpay_payer_with_eobs
    payer_details = {      
      :payer => 'Cigna',
      :pay_address_one => 'PO BOX 14079',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '23451',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '16',
      :payer => payer_details,
      :payer_type => 'Insurance',
      :micr_line_information => micr_details
    }
    expected_error_message = 'Please delete the EOBs attached for this payer to change the payer type'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
  end

  def test_for_change_payer_type_of_a_insurance_payer_without_eobs
    payer_details = {      
      :payer => 'Payer Insurance to Patpay',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '12345',
      :payid => 'P9998'
    }
    micr_details = {      
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '59',
      :payer => payer_details,
      :payer_type => 'PatPay',
      :micr_line_information => micr_details
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer_type_changed_payer = Payer.find(59)
    set_name = payer_type_changed_payer.reason_code_set_name
    assert_equal 'PatPay', payer_type_changed_payer.payer_type
    assert_equal 'P9998', payer_type_changed_payer.attributes["payid"]
    assert_equal 'DEFAULT_59', set_name.name
    assert_equal 2, set_name.reason_codes.length
  end

  def test_for_change_payer_type_of_a_patpay_payer_without_eobs
    payer_details = {      
      :payer => 'Payer Patpay to Insurance',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '12345',
      :payid => 'D9999'
    }
    micr_details = {      
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '60',
      :payer => payer_details,
      :payer_type => 'Insurance',
      :micr_line_information => micr_details
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer_type_changed_payer = Payer.find(60)
    set_name = payer_type_changed_payer.reason_code_set_name
    assert_equal '60', payer_type_changed_payer.payer_type
    assert_equal 'D9999', payer_type_changed_payer.attributes["payid"]
    assert_equal 'D9999', set_name.name
  end

  def test_for_not_changing_the_set_name_for_bac_when_payer_type_changes
    payer_details = {
      :payer => 'Payer Patpay to Insurance',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '12345',
      :payid => 'D9999'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '60',
      :payer => payer_details,
      :payer_type => 'Insurance',
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D9999'},
    }
    $IS_PARTNER_BAC = true
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer_type_changed_payer = Payer.find(60)
    set_name = payer_type_changed_payer.reason_code_set_name
    assert_equal '60', payer_type_changed_payer.payer_type
    assert_equal 'D9999', payer_type_changed_payer.attributes["payid"]
    assert_equal 'DEFAULT_60', set_name.name
    assert_equal 2, set_name.reason_codes.length
    assert_equal 2, set_name.reason_codes.where(:active => true).length
  end



  # Testing facility and micr specific payer name and payid

  def test_onbase_name_and_payid_validation_to_pass
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '112233445',
      :payer_account_number => '112233445'
    }
    facilities_micr_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3',
      :facility_id1 => '1',
      :onbase_name1 => 'on base 1',
      :output_payid1 => 'pay id 1',
      :facility_id2 => '2',
      :onbase_name2 => 'on base 2',
      :output_payid2 => '',
      :facility_id3 => '3',
      :onbase_name3 => '',
      :output_payid3 => 'pay id 3'
    }

    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_micr_information => facilities_micr_information
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    micr = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number( '112233445', '112233445')
    facilities_micr_information = FacilitiesMicrInformation.find_all_by_micr_line_information_id(micr.id)
    assert_equal 3, facilities_micr_information.length
  end

  def test_onbase_name_and_payid_validation_to_fail_with_blank_values
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '456000564',
      :payer_account_number => '456000564'
    }
    facilities_micr_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3',
      :facility_id1 => '1',
      :onbase_name1 => '',
      :output_payid1 => '',
      :facility_id2 => '',
      :onbase_name2 => 'on base 2',
      :output_payid2 => 'pay id 2'
    }

    get :save_payer_and_its_related_attributes, {
      :micr_id => '17',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_micr_information => facilities_micr_information
    }
    expected_error_message = 'Please enter one row for a facility.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
    micr = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number('456000564',
      '456000564')
    facilities_micr_information = FacilitiesMicrInformation.find_all_by_micr_line_information_id(micr.id)
    assert_equal 0, facilities_micr_information.length
  end

  def test_onbase_name_and_payid_validation_to_fail_with_no_micr_data
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    facilities_micr_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3,4',
      :facility_id1 => '1',
      :onbase_name1 => 'on base 1',
      :output_payid1 => 'pay id 1',
      :facility_id2 => '',
      :onbase_name2 => 'on base 2',
      :output_payid2 => 'pay id 2',
      :facility_id3 => '',
      :onbase_name3 => '',
      :output_payid3 => '',
      :facility_id4 => '3',
      :onbase_name4 => '',
      :output_payid4 => ''
    }

    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_micr_information => facilities_micr_information
    }
    expected_error_message = 'Please enter one row for a facility.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message

    facilities_micr_information = FacilitiesMicrInformation.find_all_by_facility_id([11, 13])
    assert_equal 0, facilities_micr_information.length
  end

  def test_onbase_name_and_payid_validation_to_fail_with_duplicate_values
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '456000564',
      :payer_account_number => '456000564'
    }
    facilities_micr_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3,4,5',
      :facility_id1 => '1',
      :onbase_name1 => 'on base 1',
      :output_payid1 => 'pay id 1',
      :facility_id2 => '1',
      :onbase_name2 => 'on base 2',
      :output_payid2 => '',
      :facility_id3 => '1',
      :onbase_name3 => '',
      :output_payid3 => 'pay id 3',
      :facility_id4 => '1',
      :onbase_name4 => '',
      :output_payid4 => '',
      :facility_id5 => '2',
      :onbase_name5 => 'pay id 4',
      :output_payid5 => ''
    }

    get :save_payer_and_its_related_attributes, {
      :micr_id => '17',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_micr_information => facilities_micr_information
    }
    expected_error_message = 'Please enter one row for a facility.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
    micr = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number('456000564',
      '456000564')
    facilities_micr_information = FacilitiesMicrInformation.find_all_by_micr_line_information_id(micr.id)
    assert_equal 0, facilities_micr_information.length
  end

  # Testing allowance, payment and capitation codes saving

  def test_payer_specific_codes_validation_to_pass
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '112233445',
      :payer_account_number => '112233445'
    }
    facilities_payers_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3',
      :facility_id1 => '1',
      :in_patient_payment_code1 => '111',
      :out_patient_payment_code1 => '222',
      :in_patient_allowance_code1 => '333',
      :out_patient_allowance_code1 => '444',
      :capitation_code1 => '555',
      :facility_id2 => '2',
      :in_patient_payment_code2 => '',
      :out_patient_payment_code2 => '222',
      :in_patient_allowance_code2 => '333',
      :out_patient_allowance_code2 => '',
      :capitation_code2 => '555',
      :facility_id3 => '3',
      :in_patient_payment_code3 => '',
      :out_patient_payment_code3 => '',
      :in_patient_allowance_code3 => '',
      :out_patient_allowance_code3 => '',
      :capitation_code3 => '555'
    }

    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_payers_information => facilities_payers_information
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = Payer.find_by_payer('Valid Payer')
    facilities_payers_information = FacilitiesPayersInformation.find_all_by_payer_id(payer.id)
    assert_equal 3, facilities_payers_information.length
  end

  def test_payer_specific_codes_validation_to_fail_with_blank_data
    payer_details = {
      :payer => 'Payer 69',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    facilities_payers_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3',
      :facility_id1 => '1',
      :in_patient_payment_code1 => '',
      :out_patient_payment_code1 => '',
      :in_patient_allowance_code1 => '',
      :out_patient_allowance_code1 => '',
      :capitation_code1 => '',
      :facility_id2 => '',
      :in_patient_payment_code2 => '111',
      :out_patient_payment_code2 => '222',
      :in_patient_allowance_code2 => '333',
      :out_patient_allowance_code2 => '444',
      :capitation_code2 => '555',
      :facility_id3 => '',
      :in_patient_payment_code3 => '',
      :out_patient_payment_code3 => '222',
      :in_patient_allowance_code3 => '',
      :out_patient_allowance_code3 => '',
      :capitation_code3 => '555'
    }

    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_payers_information => facilities_payers_information
    }
    expected_error_message = 'Please enter one row for a facility.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = Payer.find(69)
    facilities_payers_information = FacilitiesPayersInformation.find_all_by_payer_id(payer.id)
    assert_equal 0, facilities_payers_information.length
  end

  def test_payer_specific_codes_validation_to_fail_with_duplication_data
    payer_details = {
      :payer => 'Payer 69',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    facilities_payers_information = {
      :to_delete => '',
      :serial_numbers_added => '1,2,3',
      :facility_id1 => '1',
      :in_patient_payment_code1 => '111',
      :out_patient_payment_code1 => '222',
      :in_patient_allowance_code1 => '333',
      :out_patient_allowance_code1 => '444',
      :capitation_code1 => '555',
      :facility_id2 => '1',
      :in_patient_payment_code2 => '',
      :out_patient_payment_code2 => '222',
      :in_patient_allowance_code2 => '333',
      :out_patient_allowance_code2 => '',
      :capitation_code2 => '555',
      :facility_id3 => '3',
      :in_patient_payment_code3 => '',
      :out_patient_payment_code3 => '',
      :in_patient_allowance_code3 => '',
      :out_patient_allowance_code3 => '',
      :capitation_code3 => '555'
    }

    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_payers_information => facilities_payers_information
    }
    expected_error_message = 'Please enter one row for a facility.'
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal false, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = Payer.find(69)
    facilities_payers_information = FacilitiesPayersInformation.find_all_by_payer_id(payer.id)
    assert_equal 0, facilities_payers_information.length
  end

  # Testing validity of values
  
  def test_validity_of_values
    payer_details = {
      :payer => 'Valid Payer ',
      :pay_address_one => 'add one  ',
      :pay_address_two => '',
      :payer_city => '  city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '112233445',
      :payer_account_number => '112233445'
    }
    facilities_payers_information = {
      :serial_numbers_added => '1,',
      :facility_id1 => '1',
      :in_patient_payment_code1 => 'a111  ',
      :out_patient_payment_code1 => '   222b',
      :in_patient_allowance_code1 => ' c333c ',
      :out_patient_allowance_code1 => nil,
      :capitation_code1 => ''
    }
    facilities_micr_information = {
      :serial_numbers_added => '1,',
      :facility_id1 => '1',
      :onbase_name1 => 'on base 1   ',
      :output_payid1 => ''
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'},
      :facilities_payers_information => facilities_payers_information,
      :facilities_micr_information => facilities_micr_information
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = Payer.find_by_payer('Valid Payer')
    assert_equal 'VALID PAYER', payer.payer
    assert_equal 'ADD ONE', payer.pay_address_one
    assert_equal nil, payer.pay_address_two
    assert_equal 'CITY', payer.payer_city
    assert_equal 'SS', payer.payer_state
    assert_equal '12345', payer.payer_zip
    assert_equal 'APPROVED', payer.status
    
    
    micr = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number('112233445',
      '112233445')
    assert_equal 'APPROVED', micr.status
    
    facilities_micr_info_array = FacilitiesMicrInformation.find_all_by_micr_line_information_id(micr.id)
    facilities_micr_information = facilities_micr_info_array.first
    assert_equal 'ON BASE 1', facilities_micr_information.onbase_name
    assert_equal nil, facilities_micr_information.output_payid

    facilities_payers_information_array = FacilitiesPayersInformation.find_all_by_payer_id(payer.id)
    facilities_payers_information = facilities_payers_information_array.first
    assert_equal 'A111', facilities_payers_information.in_patient_payment_code
    assert_equal '222B', facilities_payers_information.out_patient_payment_code
    assert_equal 'C333C', facilities_payers_information.in_patient_allowance_code
    assert_equal nil, facilities_payers_information.out_patient_allowance_code
    assert_equal nil, facilities_payers_information.capitation_code
  end

  # Testing the payer status

  def test_payer_status_and_micr_status_to_change_from_new_to_approved_after_approval
    payer_details = {
      :payer => 'Payer 69',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '567567567',
      :payer_account_number => '567567567'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '69',
      :micr_id => '14',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'I9998'}
    }
    $IS_PARTNER_BAC = false
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = payers(:payer_69)
    assert_equal 'APPROVED', payer.status
    micr = micr_line_informations(:micr_14)
    assert_equal 'APPROVED', micr.status
  end

  def test_payer_status_and_micr_status_not_to_change_for_mapped_payer
    payer_details = {      
      :payer => 'Payer 70',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '765765765',
      :payer_account_number => '765765765'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '70',
      :micr_id => '15',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'I9998'}
    }
    $IS_PARTNER_BAC = false
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = payers(:payer_70)    
    assert_equal 'MAPPED', payer.status
    micr = micr_line_informations(:micr_15)
    assert_equal 'APPROVED', micr.status
  end

  # Testing gateway value

  def test_gate_way_for_bac
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '112233445',
      :payer_account_number => '112233445'
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'}
    }
    $IS_PARTNER_BAC = true
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    
    payer = Payer.find_by_payer('Valid Payer')
    assert_equal 'HLSC', payer.gateway
  end

  def test_gate_way_for_non_bac
    payer_details = {
      :payer => 'Valid Payer',
      :pay_address_one => 'add one',
      :pay_address_two => 'add two',
      :payer_city => 'city',
      :payer_state => 'SS',
      :payer_zip => '12345',
      :payid => 'D0009'
    }
    micr_details = {
      :aba_routing_number => '112233445',
      :payer_account_number => '112233445'
    }
    get :save_payer_and_its_related_attributes, {
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'D0009'}
    }
    $IS_PARTNER_BAC = false
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = Payer.find_by_payer('Valid Payer')
    assert_equal 'REVMED', payer.gateway
  end

  # Testing MICR status for BAC

  def test_micr_status_not_to_change_from_new_to_approved_after_approval
    payer_details = {      
      :payer => 'Payer 69',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '567567567',
      :payer_account_number => '567567567'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '69',
      :micr_id => '14',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'I9998'}
    }
    $IS_PARTNER_BAC = true
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = payers(:payer_69)
    assert_equal 'APPROVED', payer.status
    micr = micr_line_informations(:micr_14)
    assert_equal 'NEW', micr.status
  end
  
  def test_micr_status_not_to_change_from_approval
    payer_details = {
      :payer => 'Payer 70',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '457567111',
      :payer_account_number => '457567111'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '70',
      :micr_id => '16',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'I9998'}
    }
    $IS_PARTNER_BAC = true
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = payers(:payer_69)
    assert_equal 'MAPPED', payer.status
    micr = micr_line_informations(:micr_14)
    assert_equal 'APPROVED', micr.status
  end

  def test_micr_status_to_be_new_while_creation
    payer_details = {
      :payer => 'Payer 70',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OH',
      :payer_zip => '12345',
      :payid => 'I9998'
    }
    micr_details = {
      :aba_routing_number => '781969789',
      :payer_account_number => '781969789'
    }
    get :save_payer_and_its_related_attributes, {
      :id => '70',
      :payer => payer_details,
      :micr_line_information => micr_details,
      :rc_set => {:name => 'I9998'}
    }
    $IS_PARTNER_BAC = true
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer = payers(:payer_70)
    assert_equal 'MAPPED', payer.status
    micr = MicrLineInformation.find_by_aba_routing_number_and_payer_account_number('781969789',
      '781969789')
    assert_equal 'NEW', micr.status.to_s.upcase
  end

  # Testing the footnote indicator when set name changes

  def test_for_non_footnote_payer_to_change_to_footnote_when_payer_type_changes
    payer_details = {      
      :payer => 'Payer Patpay to Insurance',
      :pay_address_one => 'PO BOX 1479',
      :pay_address_two => '',
      :payer_city => 'NEWARK',
      :payer_state => 'OA',
      :payer_zip => '12345',
      :payid => 'IP9999',
      :footnote_indicator => 'Non-Footnote'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :save_payer_and_its_related_attributes, {
      :id => '60',
      :payer => payer_details,
      :payer_type => 'Insurance',
      :micr_line_information => micr_details
    }
    expected_error_message = nil
    observed_result, observed_error_message = @controller.save_payer_and_its_related_attributes
    assert_equal true, observed_result
    assert_equal expected_error_message, observed_error_message
    payer_type_changed_payer = Payer.find(60)
    set_name = payer_type_changed_payer.reason_code_set_name
    assert_equal '60', payer_type_changed_payer.payer_type
    assert_equal 'IP9999', payer_type_changed_payer.attributes["payid"]
    assert_equal 'IP9999', set_name.name
    assert_equal false, payer_type_changed_payer.footnote_indicator
    assert_equal 4, set_name.reason_codes.length
    assert_equal 3, set_name.reason_codes.where(:active => true).length
  end

end