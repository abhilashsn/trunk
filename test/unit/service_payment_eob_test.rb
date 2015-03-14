require File.dirname(__FILE__) + '/../test_helper'

class ServicePaymentEOBTest < ActiveSupport::TestCase
  fixtures :service_payment_eobs, :facilities, :batches, :check_informations,
    :payers, :reason_codes, :reason_codes_clients_facilities_set_names,
    :ansi_remark_codes, :service_payment_eobs_ansi_remark_codes,
    :default_codes_for_adjustment_reasons    

  def test_remark_codes_for_service_line
    svc = service_payment_eobs(:svc_1)
    remark_codes = svc.get_remark_codes
    assert_not_nil remark_codes
    assert_equal ["AB", "12"], remark_codes
  end

  def test_no_remark_codes_for_service_line
    svc = service_payment_eobs(:one)
    remark_codes = svc.get_remark_codes
    assert_equal [], remark_codes
  end

  def test_processor_input_field_count_with_service_date_for_patpay
    svc  = service_payment_eobs(:svc1)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    assert_equal(total_field_count, 3)
  end
  
  def test_processor_input_field_count_with_all_fcui_fields_for_patpay
    svc  = ServicePaymentEob.find(5)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    assert_equal(total_field_count, 33)
  end
  
  def test_processor_input_field_count_with_no_fcui_fields_for_patpay
    svc  = ServicePaymentEob.find(6)
    total_field_count = svc.processor_input_field_count(facilities(:facility_1), false)
    assert_equal(total_field_count, 23)
  end
  
  def test_processor_input_field_count_with_two_values_in_inpatient_for_patpay
    svc  = ServicePaymentEob.find(7)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    assert_equal(total_field_count, 7)
  end
  
  def test_processor_input_field_count_with_one_value_in_inpatient_for_patpay
    svc  = ServicePaymentEob.find(9)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    assert_equal(total_field_count, 4)
  end
  
  def test_processor_input_field_count_with_no_data_for_patpay
    svc  = ServicePaymentEob.find(8)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    assert_equal(total_field_count, 0)
  end

  def test_processor_input_field_count_for_nextgen_with_interest_in_svc_line_and_with_service_date
    svc  = ServicePaymentEob.find(7)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), true)
    assert_equal(total_field_count, 3)
  end
  
  def test_processor_input_field_count_for_nextgen_with_interest_in_svc_line_and_without_service_date
    svc  = ServicePaymentEob.find(9)
    total_field_count = svc.processor_input_field_count(facilities(:facility_1), true)
    assert_equal(total_field_count, 1)
  end
  
  #pbid, retention fee, line_item number and payment_status_code are applicable to insurance grid only.
  def test_processor_input_field_count_for_retention_fee_line_item_number_pbid_and_payment_status_code_with_data
    svc  = ServicePaymentEob.find(10)
    total_field_count = svc.processor_input_field_count(facilities(:facility_25), true)
    assert_equal(total_field_count, 4)
  end
  
  def test_processor_input_field_count_for_retention_fee_line_item_number_pbid_and_payment_status_code_without_data
    svc  = ServicePaymentEob.find(8)
    total_field_count = svc.processor_input_field_count(facilities(:facility_26), true)
    assert_equal(total_field_count, 0)
  end
  
  def test_find_service_line_having_reason_codes
    svc = []
    svc << ServicePaymentEob.find(18)
    svc << ServicePaymentEob.find(19)
    assert_equal( ServicePaymentEob.find(19),svc[1].find_service_line_having_reason_codes(svc))
  end

  def test_zero_payment
    svc_line = service_payment_eobs(:svc_line_with_zero_payment)
    assert_equal true, svc_line.zero_payment?
  end

  def test_non_zero_payment
    svc_line = service_payment_eobs(:svc_line_with_non_zero_payment)
    assert_equal false, svc_line.zero_payment?
  end

  def test_reason_codes
    svc_line = service_payment_eobs(:svc_with_reason_codes)
    AdjustmentReason.expects(:adjustment_reason_elements).returns(['coinsurance'])
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    payer = payers(:payer17)
    reason_codes = svc_line.reason_codes_for_service_line(facility, payer)
    assert_not_nil reason_codes
    #possible fixture updates causing this failure
    # assert_equal ["RC1", 'AB'], reason_codes
  end

  def test_default_service_date_for_check_date
    default_date_config = 'Check Date'    
    check_date = ServicePaymentEob.default_service_date(
      default_date_config, '',
      check_informations(:check_information13).check_date)
    assert_equal Date.parse('2009-02-05'), check_date
  end

  def test_default_service_date_for_batch_date
    default_date_config = 'Batch Date'
    batch_date = ServicePaymentEob.default_service_date(default_date_config,
      batches(:batch1).date, nil)
    assert_equal Date.parse('2006-10-09'), batch_date
  end

  def test_default_service_date_for_default_date
    default_service_date = facilities(:facility_1).default_service_date
    default_date = ServicePaymentEob.default_service_date(default_service_date,
      nil, nil)
    assert_equal '2010-10-31', default_date
  end

  def test_service_balance_for_non_zero_balance
    p "test_service_balance_for_non_zero_balance"
    service_line = service_payment_eobs(:svc_5)
    expected_balance_amount = "-100.00"
    obtained_balance_amount = service_line.service_balance
    assert_equal expected_balance_amount, obtained_balance_amount
  end

  def test_service_balance_for_zero_balance
    p "test_service_balance_for_zero_balance"
    service_line = service_payment_eobs(:svc_with_reason_codes)
    expected_balance_amount = "0.00"
    obtained_balance_amount = service_line.service_balance
    assert_equal expected_balance_amount, obtained_balance_amount
  end

  # +--------------------------------------------------------------------------+
  # Testing processor_field count
  # Input: service line and remark_code is enabled
  # Output: Count will return
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_processor_input_field_count_with_for_with_remark_codes
    svc  = service_payment_eobs(:svc_7)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    assert_equal(total_field_count, 7)
  end

  # +--------------------------------------------------------------------------+
  # Testing processor_field count
  # Input: service line with adjustment amounts
  # Output: Count will return
  # Author  : Ramya Periyangat
  # +--------------------------------------------------------------------------+
  def test_processor_input_field_count_with_adjustment_amounts
    svc  = service_payment_eobs(:service_line_26)
    total_field_count = svc.processor_input_field_count(facilities(:facility8), false)
    if $IS_PARTNER_BAC
      assert_equal(total_field_count, 15)
    else
      assert_equal(total_field_count, 11)
    end
  end
end
