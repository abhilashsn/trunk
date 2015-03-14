require File.dirname(__FILE__)+'/../test_helper'
require 'insurance_payment_eobs_controller'
require 'mocha/setup'

class DatacapturesControllerTest < ActionController::TestCase
  
  include AuthenticatedTestHelper
  fixtures :users, :roles, :roles_users, :clients, 
    :jobs , :check_informations, :batches, :facilities,
    :insurance_payment_eobs, :payers, :service_payment_eobs, :reason_code_set_names,
    :insurance_payment_eobs_reason_codes, :service_payment_eobs_reason_codes,
    :reason_codes, :reason_codes_jobs, :balance_record_configs, :ansi_remark_codes, :service_payment_eobs_ansi_remark_codes
  
  def setup
    @controller = DatacapturesController.new
    @session   = ActionController::TestSession.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def teardown
    #    @session.clear
  end

  def test_validate_payment_method_when_payment_method_is_nil
    check_details = { :check_number => '',
      :check_date => '',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = 'Payment method is missing or invalid'
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_when_payment_method_is_disabled_but_available_from_hidden_field
    check_details = { :check_number => '',
      :check_date => '',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check_information => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in Check Number, Check Date, Check Amount, ABA Routing #, Payer Account #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end
 
  def test_validate_payment_method_for_chk_when_all_fields_are_absent
    check_details = { :check_number => '',
      :check_date => '',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in Check Number, Check Date, Check Amount, ABA Routing #, Payer Account #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end


  def test_validate_payment_method_for_chk_when_fields_contain_default_values
    check_details = { :check_number => '0000000',
      :check_date => 'mm/dd/yy',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '00000000',
      :payer_account_number => '00000000'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in Check Number, Check Date, Check Amount, ABA Routing #, Payer Account #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end
  
  def test_validate_payment_method_for_chk_when_fields_of_set1_are_absent
    check_details = { :check_number => '234567',
      :check_date => '',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '7568678797',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in Check Date, Check Amount, Payer Account #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_chk_when_fields_of_set2_are_absent
    check_details = { :check_number => '',
      :check_date => '10/10/12',
      :check_amount => '20.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => '567658568'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in Check Number, ABA Routing #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_chk_when_check_number_is_auto_generated
    check_details = { :check_number => 'RX150612095022',
      :check_date => '10/10/12',
      :check_amount => '20.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => '567658568'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :generated => {:check_number => 'RX150612'},
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in Check Number, ABA Routing #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_chk_when_check_number_is_not_auto_generated
    check_details = { :check_number => 'RX150612',
      :check_date => '10/10/12',
      :check_amount => '20.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => '567658568'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :generated => {:check_number => 'RX150612'},
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as CHK. Please enter value in ABA Routing #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end
  
  def test_validate_payment_method_for_chk_when_all_fields_are_present
    check_details = { :check_number => '5345346',
      :check_date => '10/10/12',
      :check_amount => '20.00'
    }
    micr_details = {
      :aba_routing_number => '345346346',
      :payer_account_number => '567658568'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_chk_when_micr_and_date_are_not_present_in_grid
    check_details = { :check_number => '5345346',
      :check_amount => '20.00'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :check => {:payment_method => 'CHK'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_cor_when_all_fields_are_absent
    check_details = { :check_number => '',
      :check_date => '',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_cor_when_all_fields_are_present
    check_details = { :check_number => '5345346',
      :check_date => '10/10/12',
      :check_amount => '20.00'
    }
    micr_details = {
      :aba_routing_number => '345346346',
      :payer_account_number => '567658568'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as COR. Please do not enter value in Check Number, Check Date, Check Amount, ABA Routing #, Payer Account #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_cor_when_check_number_is_auto_generated
    check_details = { :check_number => 'RX150612015022',
      :check_date => '10/10/12',
      :check_amount => '20.00'
    }
    micr_details = {
      :aba_routing_number => '345346346',
      :payer_account_number => '567658568'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :generated => {:check_number => 'RX150612'},
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as COR. Please do not enter value in Check Date, Check Amount, ABA Routing #, Payer Account #"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_cor_when_fields_of_set1_are_absent
    check_details = { :check_number => '',
      :check_date => '10/10/11',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as COR. Please do not enter value in Check Date"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_cor_when_fields_of_set2_are_absent
    check_details = { :check_number => '000000',
      :check_date => '',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '0000000',
      :payer_account_number => '00000'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_cor_when_check_number_is_absent_and_amount_is_present
    check_details = { :check_number => '',
      :check_date => '',
      :check_amount => '10.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as COR. Please do not enter value in Check Amount"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validation_passed_for_payment_method_for_cor_when_micr_and_date_are_not_present_in_grid
    check_details = { :check_number => '000000',
      :check_amount => '0.00'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validation_failed_for_payment_method_for_cor_when_micr_and_date_are_not_present_in_grid_with_invalid_data
    check_details = { :check_number => '5345346',
      :check_amount => '20.00'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :check => {:payment_method => 'COR'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as COR. Please do not enter value in Check Number, Check Amount"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_all_fields_are_absent
    check_details = { :check_number => '',
      :check_date => '',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as EFT. Please enter value in Check Number OR Check Amount"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_all_fields_are_present
    check_details = { :check_number => '56768678',
      :check_date => '10/10/11',
      :check_amount => '12.00'
    }
    micr_details = {
      :aba_routing_number => '7567567567',
      :payer_account_number => '567567567'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_check_number_is_present_and_amount_is_zero
    check_details = { :check_number => '56768678',
      :check_date => '10/10/11',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '7567567567',
      :payer_account_number => '567567567'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_check_number_is_present_and_amount_is_blank
    check_details = { :check_number => '56768678',
      :check_date => '10/10/11',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '7567567567',
      :payer_account_number => '567567567'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_date_is_present_and_check_number_is_zero
    check_details = { :check_number => '0000000',
      :check_date => '10/10/11',
      :check_amount => '12.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_date_is_present_and_check_number_is_blank
    check_details = { :check_number => '',
      :check_date => '10/10/11',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as EFT. Please enter value in Check Number OR Check Amount"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_check_number_is_auto_generated_with_amount
    check_details = { :check_number => 'RX150612090322',
      :check_date => '10/10/11',
      :check_amount => '12.00'
    }
    micr_details = {
      :aba_routing_number => '7567567567',
      :payer_account_number => '567567567'
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :generated => {:check_number => 'RX150612'},
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal true, observed_result
    assert_equal nil, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_check_number_is_auto_generated_with_zero_amount
    check_details = { :check_number => 'RX150612094022',
      :check_date => '10/10/11',
      :check_amount => '0.00'
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :generated => {:check_number => 'RX150612'},
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as EFT. Please enter value in Check Number OR Check Amount"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_payment_method_for_eft_when_check_number_is_auto_generated_with_blank_amount
    check_details = { :check_number => 'RX150612094022',
      :check_date => '10/10/11',
      :check_amount => ''
    }
    micr_details = {
      :aba_routing_number => '',
      :payer_account_number => ''
    }
    get :validate_payment_method, {
      :checkinforamation => check_details,
      :micr_line_information => micr_details,
      :generated => {:check_number => 'RX150612'},
      :check => {:payment_method => 'EFT'}
    }
    @controller.instance_variable_set("@check_information", check_informations(:check_information_4))
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    expected_statement_to_alert = "The payment method is selected as EFT. Please enter value in Check Number OR Check Amount"
    observed_result, observed_statement_to_alert = @controller.validate_payment_method
    assert_equal false, observed_result
    assert_equal expected_statement_to_alert, observed_statement_to_alert
  end

  def test_validate_service_line_should_return_true_for_svc_line_with_from_date
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '10/10/10',
      'dateofservice_to1' => '10/10/10',
      'allowable1' => '100',
      'payment1' => '100',
      'charges1' => '100'
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility8))
    get :validate_service_line, my_params, my_session
    assert_equal @controller.validate_service_line('1'), true
  end

  def test_validate_service_line_should_return_true_for_svc_line_without_from_date_when_facility_has_no_from_date_configured
    my_session = {:batch_id => batches(:batch_belonging_to_facility_without_svc_from_date),
      :job_id => jobs(:job_with_no_svc_from_date),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '',
      'dateofservice_to1' => '',
      'allowable1' => '100',
      'payment1' => '100',
      'charges1' => '100'
    }
    my_params = {:lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility_1))
    get :validate_service_line, my_params, my_session
    assert_equal @controller.validate_service_line('1'), true
  end

  def test_validate_service_line_should_return_false_for_svc_line_without_from_date_when_facility_has_from_date_configured
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '',
      'dateofservice_to1' => '',
      'allowable1' => '100',
      'payment1' => '100',
      'charges1' => '100'
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility8))
    get :validate_service_line, my_params, my_session
    assert_equal @controller.validate_service_line('1'), false
  end

  def test_validate_service_line_should_return_false_for_svc_line_without_from_date_and_without_allowable_and_without_payment_when_facility_has_no_from_date_configured
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'charges2' => '100',
      'dateofservice_from1' => '',
      'dateofservice_from2' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'allowable2' => '20',
      'payment1' => '',
      'charges1' => '100'
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility8))
    get :validate_service_line, my_params, my_session
    assert_equal @controller.validate_service_line('1'), false
  end

  def test_validate_service_line_should_return_true_for_adjustment_line
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'charges2' => '100',
      'dateofservice_from1' => '',
      'dateofservice_from2' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'allowable2' => '20',
      'payment1' => '100',
      'charges1' => ''
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@adjustment_line_count', 0)
    get :validate_service_line, my_params, my_session
    assert_equal @controller.validate_service_line('1'), true
  end

  def test_validate_service_line_should_return_false_when_no_allowable_no_charges_no_payment_no_service_from_date
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'charges2' => '100',
      'dateofservice_from1' => '',
      'dateofservice_from2' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'allowable2' => '20',
      'payment1' => '',
      'charges1' => ''
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility8))
    get :validate_service_line, my_params, my_session
    assert_equal @controller.validate_service_line('1'), false
  end

  def test_set_ansi_remark_code_for_multiple_values
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'remark_code1' => 'AB:AC'
    }
    my_params = {:lineinformation => lineinformation}
    get :set_ansi_remark_code, my_params, my_session
    service_payment_eob = service_payment_eobs(:service_payment_eob_without_remark_codes1)
    service_payment_eob_with_remark_codes = service_payment_eobs(:service_payment_eob_with_remark_codes)
    @controller.set_ansi_remark_code(service_payment_eob, '1')
    assert_equal service_payment_eob.ansi_remark_codes.length, service_payment_eob_with_remark_codes.ansi_remark_codes.length
    assert_equal service_payment_eob.ansi_remark_codes[0], service_payment_eob_with_remark_codes.ansi_remark_codes[0]
    assert_equal service_payment_eob.ansi_remark_codes[1], service_payment_eob_with_remark_codes.ansi_remark_codes[1]
  end

  def test_set_ansi_remark_code_for_single_value
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'remark_code1' => 'AB'
    }
    my_params = {:lineinformation => lineinformation}
    get :set_ansi_remark_code, my_params, my_session
    service_payment_eob = service_payment_eobs(:service_payment_eob_without_remark_codes2)
    service_payment_eob_with_one_remark_code = service_payment_eobs(:service_payment_eob_with_one_remark_code)
    @controller.set_ansi_remark_code(service_payment_eob, '1')
    assert_equal service_payment_eob.ansi_remark_codes.length, service_payment_eob_with_one_remark_code.ansi_remark_codes.length
    assert_equal service_payment_eob.ansi_remark_codes[0], service_payment_eob_with_one_remark_code.ansi_remark_codes[0]
  end

  def test_does_not_set_ansi_remark_codes_for_new_remark_codes
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'remark_code1' => '90:91'
    }
    my_params = {:lineinformation => lineinformation}
    get :set_ansi_remark_code, my_params, my_session
    service_payment_eob = service_payment_eobs(:service_payment_eob_without_remark_codes3)
    @controller.set_ansi_remark_code(service_payment_eob, '1')
    assert_equal service_payment_eob.ansi_remark_codes.length, 0
  end

  def test_should_set_service_line_dates_charge_payment_cpt_code_for_insurance_eob_on_service_payment_eob
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '11/11/11',
      'dateofservice_to1' => '11/11/11',
      'charges1' => '100',
      'payment1' => '100'
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility8))
    service_payment_eob = service_payment_eobs(:service_payment_eob_without_remark_codes3)
    insurance_payment_eob =  insurance_payment_eobs(:insurance_eob_with_svc_lines_without_interest)

    @controller.expects(:insurance_eob?).returns(true)
    get :set_service_line_dates_charge_payment_cpt_code, my_params, my_session
    @controller.set_service_line_dates_charge_payment_cpt_code(insurance_payment_eob, service_payment_eob, '1')
    assert_equal service_payment_eob.date_of_service_from, Date.parse('11/11/2011')
    assert_equal service_payment_eob.date_of_service_to, Date.parse('11/11/2011')
    assert_equal service_payment_eob.service_procedure_charge_amount, 100.0
    assert_equal service_payment_eob.service_paid_amount, 100.0
	end

	def test_should_set_service_line_dates_charge_payment_cpt_code_for_patient_pay_eob_on_service_payment_eob_and_isurance_payment_eob
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '11/11/11',
      'dateofservice_to1' => '11/11/11',
      'charges1' => '100',
      'payment1' => '100'
    }
    my_params = { :lineinformation => lineinformation}
    @controller.instance_variable_set('@facility', facilities(:facility_with_single_svc_line_for_patpay))
    service_payment_eob = service_payment_eobs(:service_payment_eob_without_remark_codes2)
    insurance_payment_eob =  insurance_payment_eobs(:insurance_eob_of_a_patient_pay_check)

    @controller.expects(:insurance_eob?).returns(false)
    get :set_service_line_dates_charge_payment_cpt_code, my_params, my_session
    @controller.set_service_line_dates_charge_payment_cpt_code(insurance_payment_eob, service_payment_eob, '1')
    assert_equal service_payment_eob.date_of_service_from, Date.parse('11/11/2011')
    assert_equal service_payment_eob.date_of_service_to, Date.parse('11/11/2011')
    assert_equal service_payment_eob.service_procedure_charge_amount, 100.0
    assert_equal service_payment_eob.service_paid_amount, 100.0

    assert_equal insurance_payment_eob.claim_from_date, Date.parse('11/11/2011')
    assert_equal insurance_payment_eob.claim_to_date, Date.parse('11/11/2011')
    assert_equal insurance_payment_eob.total_submitted_charge_for_claim, 100.0
    assert_equal insurance_payment_eob.total_amount_paid_for_claim, 100.0
    assert_equal insurance_payment_eob.total_service_balance, 0
	end

  # +-------------------------------------------------------------------------+
  # This is for testing the method, named as                                  |
  # update_reason_code_set_name_for_default_reason_codes.                     |
  # Input  : Job which contains one reason_code has reason_code_set_name and  |
  #          other one gas no reason_code_set_name, parent_job_id and         |
  #          reason_code_set_name_id of payer.                                |
  # Output : Update reason_code's reason_code_set_name to payer's set_name.   |
  # +-------------------------------------------------------------------------+
  def ntest_update_reason_code_set_name_for_default_reason_codes
    job = jobs(:job_227)
    parent_job_id = job.get_parent_job_id
    payer_set_name = reason_code_set_names(:rc_set_name_10)
    @controller.update_reason_code_set_name_for_default_reason_codes(job,parent_job_id, payer_set_name.id)
    reason_codes_has_already_set_name = ReasonCode.find(85)
    reason_codes_has_no_set_name = ReasonCode.find(86)
    assert_equal(10, reason_codes_has_already_set_name.reason_code_set_name_id)
    assert_equal(10, reason_codes_has_no_set_name.reason_code_set_name_id)
  end

  def ntest_saves_eob_for_a_service_level_eob_with_interest

    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    payer = {
      'payer_id' => 1,
      'popup' => 'popup',
      'payer_address_one' => 'My Add1',
      'payer_address_two' => 'My Add2',
      'payer_city' => 'My City',
      'payer_state' => 'My State',
      'payer_zip' => 'My Zip',
      'payer_tin' => 112121,
      'payer_type' => ''
    }

    checkinforamation = {
      'check_date' => '',
      'id' => 9
    }

    insurancepaymenteob = {
      "total_amount_paid_for_claim" => 100.0,
      "claim_interest" => 23.0
    }

    provider = {
      "provider_last_name" => 'Nair',
      "provider_npi_number" => 12345
    }

    rejection = {
      "comment_area" => "something"
    }

    my_params = { :payer => payer, :checkinforamation => checkinforamation, :insurancepaymenteob => insurancepaymenteob, :provider => provider, :rejection => rejection}

    get :insertdata, my_params, my_session

    @controller.stubs(:current_user).returns(users(:qa_person))
    @controller.expects(:get_total_eob_field_count)
    ServicePaymentEob.any_instance.expects(:update_attributes)
    ServicePaymentEob.any_instance.expects(:prepare_interest_svc_line).returns(nil)
    @controller.insertdata(true)
  end

  def ntest_saves_eob_for_a_claim_level_eob_with_interest

    my_session = {:batch_id => batches(:batch999),
      :job_id => jobs(:job9),
      :tab => 'Insurance'
    }
    payer = {
      'payer_id' => 1,
      'popup' => 'popup',
      'payer_address_one' => 'My Add1',
      'payer_address_two' => 'My Add2',
      'payer_city' => 'My City',
      'payer_state' => 'My State',
      'payer_zip' => 'My Zip',
      'payer_tin' => 112121,
      'payer_type' => ''
    }

    checkinforamation = {
      'check_date' => '',
      'id' => 9
    }

    insurancepaymenteob = {
      "total_amount_paid_for_claim" => 100.0,
      "claim_interest" => 23.0,
      "category" => 'claim'
    }

    provider = {
      "provider_last_name" => 'Nair',
      "provider_npi_number" => 12345
    }

    rejection = {
      "comment_area" => "something"
    }

    my_params = { :payer => payer, :checkinforamation => checkinforamation, :insurancepaymenteob => insurancepaymenteob, :provider => provider, :rejection => rejection}

    get :insertdata, my_params, my_session

    @controller.stubs(:current_user).returns(users(:qa_person))
    @controller.expects(:get_total_eob_field_count)
    ServicePaymentEob.any_instance.expects(:update_attributes).never()
    @controller.insertdata(true)
  end

  def do_not_test_build_an_eob_for_balance_record
    parameters = {}
    parameters[:check_id] = 1
    parameters[:balance_record_config] = balance_record_configs(:balance_record_config_1)
    parameters[:payer_name] = 'Payer'
    parameters[:check_amount] = 100
    parameters[:balance_amount] = 50
    parameters[:image_page_no] = 1
    parameters[:image_page_to_number] = 1
    parameters[:sub_job_id] = 1
    eob = @controller.build_an_eob_for_balance_record(parameters)
    assert_equal insurance_payment_eobs(:balance_record_eob), eob
  end

  def do_not_test_build_a_service_line_for_balance_record
    parameters = {}
    parameters[:eob_id] = 31
    parameters[:facility] = facilities(:facility_25)
    parameters[:batch_date] = '10/10/10'
    parameters[:check_date] = '09/09/10'
    parameters[:balance_record_config] = balance_record_configs(:balance_record_config_1)
    parameters[:check_amount] = 100.00
    parameters[:balance_amount] = 50.00
    service_line = build_a_service_line_for_balance_record(parameters)
    assert_equal service_payment_eobs(:balance_record_service_line),service_line
  end

  def test_save_primary_reason_codes_for_claim_level
    insurance_eob = insurance_payment_eobs(:eob_45)
    rc = reason_codes(:reason_code1)
    associated_reason_codes_ids_to_adjustment_reason = { :coinsurance => "#{rc.id}",
      :copay => "#{rc.id}",
      :contractual => "#{rc.id}",
      :deductible => "#{rc.id}",
      :denied => "#{rc.id}",
      :discount => "#{rc.id}",
      :noncovered => "#{rc.id}",
      :primary_payment => "#{rc.id}" }
    get :save_reason_codes, {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    @amount_value_for_adjustment_reason = { :coinsurance => insurance_eob.total_co_insurance,
      :copay => insurance_eob.total_co_pay,
      :contractual => insurance_eob.total_contractual_amount,
      :deductible => insurance_eob.total_deductible,
      :denied => insurance_eob.total_denied,
      :discount => insurance_eob.total_discount,
      :noncovered => insurance_eob.total_non_covered,
      :primary_payment => insurance_eob.total_primary_payer_amount }
    @entity = insurance_eob
    @controller.instance_variable_set("@amount_value_for_adjustment_reason", @amount_value_for_adjustment_reason)
    @controller.instance_variable_set("@entity", @entity)
    @controller.save_reason_codes
    eob = InsurancePaymentEob.find(45)
    assert_equal rc.id, eob.coinsurance_reason_code_id
    assert_equal rc.id, eob.contractual_reason_code_id
    assert_equal rc.id, eob.copay_reason_code_id
    assert_equal rc.id, eob.deductible_reason_code_id
    assert_equal rc.id, eob.denied_reason_code_id
    assert_equal rc.id, eob.discount_reason_code_id
    assert_equal rc.id, eob.noncovered_reason_code_id
    assert_equal rc.id, eob.primary_payment_reason_code_id
  end

  def test_do_not_save_primary_reason_codes_for_claim_level_in_insurance_payment_eobs_reason_codes
    insurance_eob = insurance_payment_eobs(:eob_45)
    rc = reason_codes(:reason_code1)
    associated_reason_codes_ids_to_adjustment_reason = { :coinsurance => "#{rc.id}",
      :copay => "#{rc.id}",
      :contractual => "#{rc.id}",
      :deductible => "#{rc.id}",
      :denied => "#{rc.id}",
      :discount => "#{rc.id}",
      :noncovered => "#{rc.id}",
      :primary_payment => "#{rc.id}" }
    get :save_reason_codes, {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    @amount_value_for_adjustment_reason = { :coinsurance => insurance_eob.total_co_insurance,
      :copay => insurance_eob.total_co_pay,
      :contractual => insurance_eob.total_contractual_amount,
      :deductible => insurance_eob.total_deductible,
      :denied => insurance_eob.total_denied,
      :discount => insurance_eob.total_discount,
      :noncovered => insurance_eob.total_non_covered,
      :primary_payment => insurance_eob.total_primary_payer_amount }
    @entity = insurance_eob
    @controller.instance_variable_set("@amount_value_for_adjustment_reason", @amount_value_for_adjustment_reason)
    @controller.instance_variable_set("@entity", @entity)
    @controller.save_reason_codes
    eob = InsurancePaymentEob.find(45)
    assert_equal [], eob.reason_codes
  end

  def test_save_primary_and_secondary_reason_codes_for_claim_level
    insurance_eob = insurance_payment_eobs(:eob_45)
    rc1 = reason_codes(:reason_code1)
    rc2 = reason_codes(:reason_code2)
    associated_reason_codes_ids_to_adjustment_reason = {
      :coinsurance => "#{rc1.id}; #{rc2.id}",
      :copay => "#{rc1.id}; #{rc2.id}",
      :contractual => "#{rc1.id}; #{rc2.id}",
      :deductible => "#{rc1.id}; #{rc2.id}",
      :denied => "#{rc1.id}; #{rc2.id}",
      :discount => "#{rc1.id}; #{rc2.id}",
      :noncovered => "#{rc1.id}; #{rc2.id}",
      :primary_payment => "#{rc1.id}; #{rc2.id}" }
    get :save_reason_codes, {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    @amount_value_for_adjustment_reason = { :coinsurance => insurance_eob.total_co_insurance,
      :copay => insurance_eob.total_co_pay,
      :contractual => insurance_eob.total_contractual_amount,
      :deductible => insurance_eob.total_deductible,
      :denied => insurance_eob.total_denied,
      :discount => insurance_eob.total_discount,
      :noncovered => insurance_eob.total_non_covered,
      :primary_payment => insurance_eob.total_primary_payer_amount }
    @entity = insurance_eob
    @controller.instance_variable_set("@amount_value_for_adjustment_reason", @amount_value_for_adjustment_reason)
    @controller.instance_variable_set("@entity", @entity)
    @controller.save_reason_codes
    eob = InsurancePaymentEob.find(45)
    assert_equal rc1.id, eob.coinsurance_reason_code_id
    assert_equal rc1.id, eob.contractual_reason_code_id
    assert_equal rc1.id, eob.copay_reason_code_id
    assert_equal rc1.id, eob.deductible_reason_code_id
    assert_equal rc1.id, eob.denied_reason_code_id
    assert_equal rc1.id, eob.discount_reason_code_id
    assert_equal rc1.id, eob.noncovered_reason_code_id
    assert_equal rc1.id, eob.primary_payment_reason_code_id
    eob = InsurancePaymentEob.find(45)
    assert_not_nil eob.reason_codes
    assert_equal  8, eob.reason_codes.count
  end

  def test_save_primary_reason_codes_for_service_level
    service_line = service_payment_eobs(:service_line_25)
    rc = reason_codes(:reason_code1)
    associated_reason_codes_ids_to_adjustment_reason = {
      :coinsurance1 => "#{rc.id}",
      :copay1 => "#{rc.id}",
      :contractual1 => "#{rc.id}",
      :deductible1 => "#{rc.id}",
      :denied1 => "#{rc.id}",
      :discount1 => "#{rc.id}",
      :noncovered1 => "#{rc.id}",
      :primary_payment1 => "#{rc.id}" }
    get :save_reason_codes, {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    @amount_value_for_adjustment_reason = { :coinsurance => service_line.service_co_insurance,
      :copay => service_line.service_co_pay,
      :contractual => service_line.contractual_amount,
      :deductible => service_line.service_deductible,
      :denied => service_line.denied,
      :discount => service_line.service_discount,
      :noncovered => service_line.service_no_covered,
      :primary_payment => service_line.primary_payment }
    @entity = service_line
    @controller.instance_variable_set("@amount_value_for_adjustment_reason", @amount_value_for_adjustment_reason)
    @controller.instance_variable_set("@entity", @entity)
    @controller.save_reason_codes(1)
    service_line = ServicePaymentEob.find(25)
    assert_equal rc.id, service_line.coinsurance_reason_code_id
    assert_equal rc.id, service_line.contractual_reason_code_id
    assert_equal rc.id, service_line.copay_reason_code_id
    assert_equal rc.id, service_line.deductible_reason_code_id
    assert_equal rc.id, service_line.denied_reason_code_id
    assert_equal rc.id, service_line.discount_reason_code_id
    assert_equal rc.id, service_line.noncovered_reason_code_id
    assert_equal rc.id, service_line.primary_payment_reason_code_id
  end

  def test_do_not_save_primary_reason_codes_for_service_level_in_insurance_payment_eobs_reason_codes
    service_line = service_payment_eobs(:service_line_25)
    rc = reason_codes(:reason_code1)
    associated_reason_codes_ids_to_adjustment_reason = {
      :coinsurance1 => "#{rc.id}",
      :copay1 => "#{rc.id}",
      :contractual1 => "#{rc.id}",
      :deductible1 => "#{rc.id}",
      :denied1 => "#{rc.id}",
      :discount1 => "#{rc.id}",
      :noncovered1 => "#{rc.id}",
      :primary_payment1 => "#{rc.id}" }
    get :save_reason_codes, {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    @amount_value_for_adjustment_reason = { :coinsurance => service_line.service_co_insurance,
      :copay => service_line.service_co_pay,
      :contractual => service_line.contractual_amount,
      :deductible => service_line.service_deductible,
      :denied => service_line.denied,
      :discount => service_line.service_discount,
      :noncovered => service_line.service_no_covered,
      :primary_payment => service_line.primary_payment }
    @entity = service_line
    @controller.instance_variable_set("@amount_value_for_adjustment_reason", @amount_value_for_adjustment_reason)
    @controller.instance_variable_set("@entity", @entity)
    @controller.save_reason_codes(1)
    service_line = ServicePaymentEob.find(25)
    assert_equal [], service_line.reason_codes
  end

  def test_save_primary_and_secondary_reason_codes_for_service_level
    service_line = service_payment_eobs(:service_line_25)
    rc1 = reason_codes(:reason_code1)
    rc2 = reason_codes(:reason_code2)
    associated_reason_codes_ids_to_adjustment_reason = {
      :coinsurance1 => "#{rc1.id}; #{rc2.id}",
      :copay1 => "#{rc1.id}; #{rc2.id}",
      :contractual1 => "#{rc1.id}; #{rc2.id}",
      :deductible1 => "#{rc1.id}; #{rc2.id}",
      :denied1 => "#{rc1.id}; #{rc2.id}",
      :discount1 => "#{rc1.id}; #{rc2.id}",
      :noncovered1 => "#{rc1.id}; #{rc2.id}",
      :primary_payment1 => "#{rc1.id}; #{rc2.id}" }
    get :save_reason_codes, {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    @amount_value_for_adjustment_reason = { :coinsurance => service_line.service_co_insurance,
      :copay => service_line.service_co_pay,
      :contractual => service_line.contractual_amount,
      :deductible => service_line.service_deductible,
      :denied => service_line.denied,
      :discount => service_line.service_discount,
      :noncovered => service_line.service_no_covered,
      :primary_payment => service_line.primary_payment }
    @entity = service_line
    @controller.instance_variable_set("@amount_value_for_adjustment_reason", @amount_value_for_adjustment_reason)
    @controller.instance_variable_set("@entity", @entity)
    @controller.save_reason_codes(1)
    service_line = ServicePaymentEob.find(25)
    assert_equal rc1.id, service_line.coinsurance_reason_code_id
    assert_equal rc1.id, service_line.contractual_reason_code_id
    assert_equal rc1.id, service_line.copay_reason_code_id
    assert_equal rc1.id, service_line.deductible_reason_code_id
    assert_equal rc1.id, service_line.denied_reason_code_id
    assert_equal rc1.id, service_line.discount_reason_code_id
    assert_equal rc1.id, service_line.noncovered_reason_code_id
    assert_equal rc1.id, service_line.primary_payment_reason_code_id
    assert_not_nil service_line.reason_codes
    assert_equal  11, service_line.reason_codes.count
  end

  def test_get_reason_code_ids_from_id_params
    rc1 = reason_codes(:reason_code1)
    rc2 = reason_codes(:reason_code2)
    associated_reason_codes_ids_to_adjustment_reason = {
      :coinsurance1 => "#{rc1.id}; #{rc2.id}",
      :copay1 => "#{rc1.id}; #{rc2.id}",
      :contractual1 => "#{rc1.id}; #{rc2.id}",
      :deductible1 => "#{rc1.id}; #{rc2.id}",
      :denied1 => "#{rc1.id}; #{rc2.id}",
      :discount1 => "#{rc1.id}; #{rc2.id}",
      :noncovered1 => "#{rc1.id}; #{rc2.id}",
      :primary_payment1 => "#{rc1.id}; #{rc2.id}" }
    get :get_reason_code_ids,
      {:reason_code_id => associated_reason_codes_ids_to_adjustment_reason}
    reason_code_ids = @controller.get_reason_code_ids('coinsurance', 1)
    assert_equal [rc1.id, rc2.id], reason_code_ids
  end

  def test_get_reason_code_ids_from_unique_code_params
    rc1 = reason_codes(:reason_code51)
    rc2 = reason_codes(:reason_code71)
    get :get_reason_code_ids, {:job_id => '1'},
      {:reason_code_id => {}}
    @controller.session[:job_id] = '1'
    @controller.params[:reason_code] = {
      :coinsurance1 => {"unique_code"=>"1Z;1F"},
      :copay1 => {"unique_code"=>"1F;1Z"},
      :contractual1 => {"unique_code"=>"1Z;1F"},
      :deductible1 => {"unique_code"=>"1F;1Z"},
      :denied1 => {"unique_code"=>"1Z;1F"},
      :discount1 => {"unique_code"=>"1F;1Z"},
      :noncovered1 => {"unique_code"=>"1Z;1F"},
      :primary_payment1 => {"unique_code"=>"1F;1Z"}
    }
    reason_code_ids = @controller.get_reason_code_ids('coinsurance', 1)
    assert_equal [rc2.id, rc1.id], reason_code_ids
  end

  # +-------------------------------------------------------------------------+
  # This is for testing the method, named as                                  |
  # update_reason_code_set_name_for_default_reason_codes.                     |
  # Input  : Job which contains one reason_code has reason_code_set_name and  |
  #          other one gas no reason_code_set_name, parent_job_id and         |
  #          reason_code_set_name_id of payer.                                |
  # Output : Update reason_code's reason_code_set_name to payer's set_name.   |
  # +-------------------------------------------------------------------------+
  def ntest_update_reason_code_set_name_for_default_reason_codes
    job = jobs(:job_227)
    parent_job_id = job.get_parent_job_id
    payer_set_name = reason_code_set_names(:rc_set_name_10)
    @controller.update_reason_code_set_name_for_default_reason_codes(job,parent_job_id, payer_set_name.id)
    reason_codes_has_already_set_name = ReasonCode.find(85)
    reason_codes_has_no_set_name = ReasonCode.find(86)
    assert_equal(10, reason_codes_has_already_set_name.reason_code_set_name_id)
    assert_equal(10, reason_codes_has_no_set_name.reason_code_set_name_id)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'set_patient_identification_code_to_blank'.
  # If qualifier is HIC and character length of patient_identification_nnumber = 1
  # then patient_identification_number will be set to null.
  # Input:                                                                     |
  # 1) Qualifier is HIC and Identification_code length=1                       |
  # 2) Qualifier is HIC and Identification_code length=2                       |
  # 3) Qualifier is SSN and Identification_code length=1                       |
  # 4) Qualifier is SSN and Identification_code length=2                       |
  # 5) Qualifier is Blank and Identification_code length=1                     |
  # 6) Qualifier is HIC and Identification_code is Blank.                      |
  # Output:                                                                    |
  # 1) Returns true                                                            |
  # 2) Returns false                                                           |
  # 3) Returns false                                                           |
  # 4) Returns false                                                           |
  # 5) Returns false                                                           |
  # 6) Returns false                                                           |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_set_patient_identification_code_to_blank
    #    if qualifier is HIC and length of identification code is one.
    qualifier_is_hic = 'HIC'
    identification_code = 'S'
    assert_equal(true, @controller.set_patient_identification_code_to_blank(qualifier_is_hic, identification_code))
    #    if qualifier is HIC and length of identification code is two.
    qualifier_is_hic = 'HIC'
    identification_code = 'SS'
    assert_equal(false, @controller.set_patient_identification_code_to_blank(qualifier_is_hic, identification_code))
    #    if qualifier is SSN and length of identification code is one.
    qualifier_is_ssn = 'SSN'
    identification_code = 'S'
    assert_equal(false, @controller.set_patient_identification_code_to_blank(qualifier_is_ssn, identification_code))
    #    if qualifier is SSN and length of identification code is two.
    qualifier_is_ssn = 'SSN'
    identification_code = 'SS'
    assert_equal(false, @controller.set_patient_identification_code_to_blank(qualifier_is_ssn, identification_code))
    #    if qualifier is blank and length of identification code is one.
    qualifier_is_blank = ''
    identification_code = 'S'
    assert_equal(false, @controller.set_patient_identification_code_to_blank(qualifier_is_blank, identification_code))
    #    if qualifier is HIC and identification code is blank.
    qualifier_is_hic = 'HIC'
    identification_code_is_blank = ''
    assert_equal(false, @controller.set_patient_identification_code_to_blank(qualifier_is_hic, identification_code_is_blank))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'set_patient_identification_code_for_balance_record'.
  # If qualifier is HIC , site_code after trimming left padded zeroes is '896',|
  #  patient_identification_nnumber is set to 'BALANCERECORD'.                 |
  # 1) Qualifier is HIC , site_code = '896'and Identification_code = ''        |
  # 2) Qualifier is HIC , site_code = '00896'and Identification_code = ''      |
  # 3) Qualifier is HIC , site_code = '778'and Identification_code = 'A002'    |
  # 4) Qualifier is SSN , site_code = '896'and Identification_code = 'A002'    |
  # 5) Qualifier is SSN , site_code = '8966'and Identification_code = 'A002'   |
  # Output:                                                                    |
  # 1) Returns 'BALANCERECORD'                                                 |
  # 2) Returns 'BALANCERECORD'                                                 |
  # 3) Returns 'A002'                                                          |
  # 4) Returns 'A002'                                                          |
  # 5) Returns 'A002'                                                          |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_set_patient_identification_code_for_balance_record
    # If Qualifier is HIC , site_code = '896'and Identification_code = ''
    sitecode_without_leading_zeroes = "896"
    qualifier = 'HIC'
    identification_code = ""
    assert_equal('BALANCERECORD', @controller.set_patient_identification_code_for_balance_record(sitecode_without_leading_zeroes,qualifier, identification_code))
    #If Qualifier is HIC , site_code = '00896'and Identification_code = ''
    sitecode_with_leading_zeroes = "00896"
    qualifier = 'HIC'
    identification_code = ""
    assert_equal('BALANCERECORD', @controller.set_patient_identification_code_for_balance_record(sitecode_with_leading_zeroes,qualifier, identification_code))
    #If Qualifier is HIC , site_code = '778'and Identification_code = 'A002'
    sitecode = "778"
    qualifier = 'HIC'
    identification_code = "A002"
    assert_equal('A002', @controller.set_patient_identification_code_for_balance_record(sitecode,qualifier, identification_code))
    #If Qualifier is SSN , site_code = '896'and Identification_code = 'A002'
    sitecode = "896"
    qualifier = 'SSN'
    identification_code = "A002"
    assert_equal('A002', @controller.set_patient_identification_code_for_balance_record(sitecode,qualifier, identification_code))
    #If Qualifier is SSN , site_code = '8966'and Identification_code = 'A002'
    sitecode = "8966"
    qualifier = 'SSN'
    identification_code = "A002"
    assert_equal('A002', @controller.set_patient_identification_code_for_balance_record(sitecode,qualifier, identification_code))
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the count of processor entered fields in nextgen grid.
  # Input: check_information and patient_pay_eobs records
  # Output: Count will return
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_get_total_nextgen_field_count
    check_information = check_informations(:check_information4)
    patient_pay_eob = patient_pay_eobs(:patient_pay_eob2)
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    @controller.get_total_nextgen_field_count(check_information, patient_pay_eob)
    patpay_eob = PatientPayEob.find(2)
    assert_equal(patpay_eob.processor_input_fields, 12)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the count of processor entered fields in claim level eobs.
  # Input: check_information with MICR, payer and insurance_payment_eob records.
  #         Transaction_type is enabled.}
  # Output: Count will return
  #         (count of fields from check_information, payer,MICR & insurance_payment_eob)
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_get_total_eob_field_count_of_claim_level_insurance_with_transaction_type
    check_information = check_informations(:check_information4)
    insurance_payment_eob = insurance_payment_eobs(:eob_70)
    payer = payers(:first)
    @controller.expects(:insurance_eob?).returns(true)
    @controller.instance_variable_set("@facility", facilities(:facility8))
    assert_equal(@controller.get_total_eob_field_count(check_information, payer, insurance_payment_eob), 21)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the count of processor entered fields in service level eobs.
  # Input: check_information with MICR, payer and insurance_payment_eob records.
  #         Transaction_type is disabled.}
  # Output: Count will return
  #         (count of fields from check_information,payer,MICR,insurance_payment_eob & service_line_eobs)
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_get_total_eob_field_count_of_service_level_insurance_without_transaction_type
    check_information = check_informations(:check_information4)
    insurance_payment_eob = insurance_payment_eobs(:eob_71)
    payer = payers(:first)
    @controller.expects(:insurance_eob?).returns(true)
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    assert_equal(@controller.get_total_eob_field_count(check_information, payer, insurance_payment_eob), 26)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the count of processor entered fields in claim level
  #  patient pay eobs.
  # Input: check_information with MICR, payer and insurance_payment_eob records.
  # Output: Count will return
  #         (count of fields from check_information,payer,MICR,insurance_payment_eob & patient)
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_get_total_eob_field_count_of_claim_level_patient_pay_eobs
    check_information = check_informations(:check_information4)
    insurance_payment_eob = insurance_payment_eobs(:eob_70)
    payer = payers(:first)
    @controller.expects(:insurance_eob?).returns(false)
    @controller.instance_variable_set("@facility", facilities(:facility_1))
    assert_equal(@controller.get_total_eob_field_count(check_information,payer, insurance_payment_eob), 25)
  end
  
  def test_compute_transaction_type_missing_check
    @controller.instance_variable_set("@parent_job", jobs(:job_86))
    @controller.instance_variable_set("@payer", payers(:payer_228))
    @controller.instance_variable_set("@check_information", check_informations(:correspondence_check_with_eob_with_svc_missing_check_89))
    assert_equal("Missing Check", @controller.compute_transaction_type("save_eob"))
  end

  def test_compute_transaction_type_check_only
    @controller.instance_variable_set("@parent_job", jobs(:job_87))
    @controller.instance_variable_set("@payer", payers(:payer_304))
    @controller.instance_variable_set("@check_information", check_informations(:payment_check_with_eob_without_svc_check_only_90))
    assert_equal("Check Only", @controller.compute_transaction_type("save_eob"))
  end

  def test_compute_transaction_type_complete_eob_payment_check_on_save_eob
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    @controller.instance_variable_set("@payer", payers(:payer_228))
    @controller.instance_variable_set("@check_information", check_informations(:payment_check_with_eob_with_svc_complete_eob_85))
    assert_equal("Complete EOB", @controller.compute_transaction_type("save_eob"))
  end

  def test_compute_transaction_type_complete_eob_payment_check_on_complete_job
    @controller.expects(:get_job_level_balance).returns(0)
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    @controller.instance_variable_set("@payer", payers(:payer_228))
    @controller.instance_variable_set("@check_information", check_informations(:payment_check_with_eob_with_svc_complete_eob_85))
    assert_equal("Complete EOB", @controller.compute_transaction_type("complete_job"))
  end

  def test_compute_transaction_type_complete_eob_check_without_micr
    @controller.expects(:get_job_level_balance).returns(0)
    @controller.instance_variable_set("@parent_job", jobs(:job_85))
    @controller.instance_variable_set("@payer", payers(:payer_228))
    @controller.instance_variable_set("@check_information", check_informations(:correspondence_check_with_eob_with_svc_complete_eob_88))
    assert_equal("Complete EOB", @controller.compute_transaction_type("save_eob"))
  end

  def test_compute_transaction_type_correspondence
    @controller.instance_variable_set("@parent_job", jobs(:job_83))
    @controller.instance_variable_set("@payer", payers(:payer_304))
    @controller.instance_variable_set("@check_information", check_informations(:correspondence_check_with_eob_without_svc__for_correspondence_82))
    assert_equal("Correspondence", @controller.compute_transaction_type("save_eob"))
  end

  def test_compute_transaction_type_patient_pay_check_with_micr
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    @controller.instance_variable_set("@payer", payers(:payer_227))
    @controller.instance_variable_set("@check_information", check_informations(:payment_check_with_eob_with_svc_complete_eob_85))
    assert_equal("Patient Pay", @controller.compute_transaction_type("complete_job"))
  end

  def test_compute_transaction_type_patient_pay_check_without_micr
    @controller.instance_variable_set("@parent_job", jobs(:job_85))
    @controller.instance_variable_set("@payer", payers(:payer_227))
    @controller.instance_variable_set("@check_information", check_informations(:correspondence_check_with_eob_with_svc_complete_eob_88))
    assert_equal("Patient Pay", @controller.compute_transaction_type("save_eob"))
  end

  def test_save_transaction_type_based_on_rule
    @controller.expects(:compute_transaction_type).returns("Missing Check")
    @controller.instance_variable_set("@parent_job", jobs(:job_83))
    images_for_jobs = {:transaction_type => "Check Only"}
    get :save_transaction_type, {
      :images_for_jobs => images_for_jobs }
    @controller.save_transaction_type
    saved_tt = ImagesForJob.find(17).transaction_type
    assert_equal("Missing Check", saved_tt)
  end

  def test_save_manually_entered_transaction_type
    @controller.expects(:compute_transaction_type).returns(nil)
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    images_for_jobs = {:transaction_type => "Check Only"}
    get :save_transaction_type, {
      :images_for_jobs => images_for_jobs }
    @controller.save_transaction_type
    saved_tt = ImagesForJob.find(18).transaction_type
    assert_equal("Check Only", saved_tt)
  end

  def test_recalculated_transaction_type_and_saved_transaction_type_are_same
    @controller.expects(:compute_transaction_type).returns("Missing Check")
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    @controller.recalculate_transaction_type("complete_job")
    saved_tt = ImagesForJob.find(18).transaction_type
    assert_equal("Missing Check", saved_tt)
  end

  def test_recalculated_transaction_type_and_saved_transaction_type_are_different_case1
    @controller.expects(:compute_transaction_type).returns("Check Only")
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    @controller.recalculate_transaction_type("complete_job")
    saved_tt = ImagesForJob.find(18).transaction_type
    assert_equal("Check Only", saved_tt)
  end

  def test_recalculated_transaction_type_and_saved_transaction_type_are_different_case2
    @controller.expects(:compute_transaction_type).returns(nil)
    @controller.instance_variable_set("@parent_job", jobs(:job_84))
    before_recalculation_tt = ImagesForJob.find(18).transaction_type
    @controller.recalculate_transaction_type("complete_job")
    after_calculation_tt = ImagesForJob.find(18).transaction_type
    assert_equal(before_recalculation_tt, after_calculation_tt)
  end

  def test_saving_of_one_svc_line_having_no_adjustment_line
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '10/10/10',
      'dateofservice_to1' => '10/10/10',
      'allowable1' => '100',
      'payment1' => '100',
      'charges1' => '100'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    @controller.process_service_lines(insurance_eob)
    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
    assert_equal 1, service_lines.length
  end

  def test_saving_of_two_svc_lines_having_no_adjustment_line
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '10/10/10',
      'dateofservice_to1' => '10/10/10',
      'allowable1' => '100',
      'payment1' => '100',
      'charges1' => '100',
      'dateofservice_from2' => '10/10/10',
      'dateofservice_to2' => '10/10/10',
      'allowable2' => '100',
      'payment2' => '100',
      'charges2' => '100'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1,2'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    @controller.process_service_lines(insurance_eob)
    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
    assert_equal 2, service_lines.length
  end

  def test_saving_of_svc_lines_with_one_adjustment_line_at_end
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '10/10/10',
      'dateofservice_to1' => '10/10/10',
      'allowable1' => '100',
      'payment1' => '100',
      'charges1' => '100',
      'dateofservice_from2' => '10/10/10',
      'dateofservice_to2' => '10/10/10',
      'allowable2' => '100',
      'payment2' => '100',
      'charges2' => '100',
      'dateofservice_from3' => '',
      'dateofservice_to3' => '',
      'allowable3' => '',
      'payment3' => '100',
      'charges3' => '',
      'non_covered3' => '-100'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1,2,3'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    @controller.process_service_lines(insurance_eob)
    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
    assert_equal 3, service_lines.length
  end

  def test_saving_of_svc_lines_with_one_adjustment_line_in_the_beginning
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'payment1' => '100',
      'charges1' => '',
      'non_covered1' => '-100',
      'dateofservice_from2' => '10/10/10',
      'dateofservice_to2' => '10/10/10',
      'allowable2' => '100',
      'payment2' => '100',
      'charges2' => '100',
      'dateofservice_from3' => '10/10/10',
      'dateofservice_to3' => '10/10/10',
      'allowable3' => '100',
      'payment3' => '100',
      'charges3' => '100'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1,2,3'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    @controller.process_service_lines(insurance_eob)
    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
    assert_equal 3, service_lines.length
  end

  def test_not_saving_of_svc_lines_with_two_adjustment_lines
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'payment1' => '100',
      'charges1' => '',
      'non_covered1' => '-100',
      'dateofservice_from2' => '10/10/10',
      'dateofservice_to2' => '10/10/10',
      'allowable2' => '100',
      'payment2' => '100',
      'charges2' => '100',
      'dateofservice_from3' => '10/10/10',
      'dateofservice_to3' => '10/10/10',
      'allowable3' => '100',
      'payment3' => '100',
      'charges3' => '100',
      'dateofservice_from4' => '',
      'dateofservice_to4' => '',
      'allowable4' => '',
      'payment4' => '50',
      'charges4' => '',
      'non_covered4' => '-50'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1,2,3,4'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    
    assert ActiveRecord::Rollback, @controller.process_service_lines(insurance_eob)
#    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
#    assert_equal 0, service_lines.length
  end

  def test_not_saving_of_svc_line_having_only_adjustment_line
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'payment1' => '100',
      'charges1' => '',
      'non_covered1' => '-100'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1,'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    assert ActiveRecord::Rollback, @controller.process_service_lines(insurance_eob)
#    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
#    assert_equal 0, service_lines.length
  end

  def test_saving_of_svc_lines_with_invalid_adjustment_line
    my_session = {:batch_id => batches(:batch_999),
      :job_id => jobs(:job_999),
      :tab => 'Insurance'
    }
    lineinformation = {
      'dateofservice_from1' => '',
      'dateofservice_to1' => '',
      'allowable1' => '',
      'payment1' => '0',
      'charges1' => '',
      'non_covered1' => '0',
      'dateofservice_from2' => '10/10/10',
      'dateofservice_to2' => '10/10/10',
      'allowable2' => '100',
      'payment2' => '100',
      'charges2' => '100',
      'dateofservice_from3' => '10/10/10',
      'dateofservice_to3' => '10/10/10',
      'allowable3' => '100',
      'payment3' => '100',
      'charges3' => '100'
    }
    my_params = { :lineinformation => lineinformation,
      :service_line => {:serial_numbers => '1,2,3'}
    }
    @controller.instance_variable_set('@facility', facilities(:facility8))
    @controller.instance_variable_set('@check_information', check_informations(:check_999))
    insurance_eob = insurance_payment_eobs(:eob_91)
    get :process_service_lines, my_params, my_session
    @controller.process_service_lines(insurance_eob)
    service_lines = ServicePaymentEob.find_all_by_insurance_payment_eob_id(insurance_eob.id)
    assert_equal 2, service_lines.length
  end

end
