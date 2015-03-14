require File.dirname(__FILE__) + '/../test_helper'
require 'facility'

class FacilityTest < ActiveSupport::TestCase
  fixtures :facilities, :facility_output_configs

  def test_industry_code_is_configured
    facility = facilities(:facility_with_remark_code)
    config = facility.industry_code_configured?
    assert_equal true, config
  end

  def test_industry_code_is_not_configured
    facility = facilities(:facility_with_rcc_crosswalk_and_default_cas_code)
    config = facility.industry_code_configured?
    assert_equal false, config
  end

  def test_insurance_output_config
    facility = facilities(:facility_3)
    expected_config = facility_output_configs(:facility_output_config_9)
    obtained_config = facility.output_config(nil)
    assert_equal expected_config, obtained_config
  end

  def test_patpay_output_config
    facility = facilities(:facility_3)
    expected_config = facility_output_configs(:patpay_output_config_10)
    obtained_config = facility.output_config('PatPay')
    assert_equal expected_config, obtained_config
  end
  
end