require File.dirname(__FILE__) + '/../test_helper'

class MicrLineInformationTest < ActiveSupport::TestCase
  fixtures :micr_line_informations, :facilities

  def test_processor_input_field_count_with_fcui_config_for_micr_line_info
    micr_line_information = MicrLineInformation.find(99)
    total_field_count = micr_line_information.processor_input_field_count(facilities(:facility8))
    assert_equal(total_field_count, 2)
  end
  
  def test_processor_input_field_count_without_fcui_config_for_micr_line_info
    micr_line_information = MicrLineInformation.find(99)
    total_field_count = micr_line_information.processor_input_field_count(facilities(:facility_1))
    assert_equal(total_field_count, 0)
  end

  def test_update_temp_pay_id
    m = MicrLineInformation.find(99)
    if m.present?
      result = m.update_temp_payer_details({"successIndicator"=>true, "originalPayerId"=>"12345", "reasonCodeSetName"=>"setname", "originalGateway" => "gtemp"})    
      if m.payer.present? && result
        assert_equal(m.payid_temp, "12345")
        assert_equal(m.payer.gateway_temp, "gtemp")
        assert_equal(m.payer.status, "UNMAPPED")
        assert_equal(m.payer.reason_code_set_name.name, "setname")        
      end
    end
  end

  def test_to_find_micr_record_with_valid_data
    expected_micr_record = micr_line_informations(:micr_18)
    aba_routing_number = expected_micr_record.aba_routing_number
    payer_account_number = expected_micr_record.payer_account_number
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_equal expected_micr_record, obtained_micr_record
    assert_equal expected_micr_record.payid_temp, obtained_micr_record.payid_temp
  end

  def test_to_find_micr_record_with_valid_data_and_blank_temp_payid
    expected_micr_record = micr_line_informations(:micr_19)
    aba_routing_number = expected_micr_record.aba_routing_number
    payer_account_number = expected_micr_record.payer_account_number
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_equal expected_micr_record, obtained_micr_record
    assert_equal 'D9998', obtained_micr_record.payid_temp
  end

  def test_to_create_micr_record_with_valid_data
    aba_routing_number = '111222333'
    payer_account_number = '111222333'
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_not_nil obtained_micr_record
    assert_equal 'D9998', obtained_micr_record.payid_temp
  end

  def test_to_create_micr_record_with_invalid_data
    aba_routing_number = '1@1#1 22.2?3(3%3'
    payer_account_number = '1@1#1 + 2"2.2?3(3%3'
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_not_nil obtained_micr_record
    assert_equal '111222333', obtained_micr_record.aba_routing_number
    assert_equal '111222333', obtained_micr_record.payer_account_number
    assert_equal 'D9998', obtained_micr_record.payid_temp
  end

  def test_to_create_micr_record_with_invalid_data_in_aba_routing_number
    aba_routing_number = '3@3#3 + 2"2.2?1(1%1'
    payer_account_number = '333222111'
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_not_nil obtained_micr_record
    assert_equal '333222111', obtained_micr_record.aba_routing_number
    assert_equal '333222111', obtained_micr_record.payer_account_number
    assert_equal 'D9998', obtained_micr_record.payid_temp
  end

  def test_to_create_micr_record_with_invalid_data_in_payer_account_number
    aba_routing_number = '333222111'
    payer_account_number = '3@3#3 + 2"2.2?1(1%1'
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_not_nil obtained_micr_record
    assert_equal '333222111', obtained_micr_record.aba_routing_number
    assert_equal '333222111', obtained_micr_record.payer_account_number
    assert_equal 'D9998', obtained_micr_record.payid_temp
  end

  def test_to_create_micr_record_with_invalid_length_in_aba_routing_number
    aba_routing_number = '22.2?1(1%1'
    payer_account_number = '+ 2"2.2?1(1%1'
    obtained_micr_record = MicrLineInformation.find_or_create_valid_micr_record(aba_routing_number, payer_account_number, 'D9998')
    assert_not_nil obtained_micr_record
    assert_equal '000222111', obtained_micr_record.aba_routing_number
    assert_equal '222111', obtained_micr_record.payer_account_number
    assert_equal 'D9998', obtained_micr_record.payid_temp
  end
  
end
