require File.dirname(__FILE__)+'/../test_helper'
require 'archive_controller'

class ArchiveControllerTest < ActionController::TestCase
  fixtures :facilities, :default_codes_for_adjustment_reasons
  
  def setup
    @controller = ArchiveController.new
    @facility = facilities(:facility_28)
  end
  
 
  def test_get_default_groupcode
    @controller.get_default_groupcode(@facility)
    assert_equal('CO', @controller.instance_eval("@coinsurance_group_code").group_code)
    assert_equal('CN', @controller.instance_eval("@contractual_group_code").group_code)
    assert_equal('CP', @controller.instance_eval("@copay_group_code").group_code)
    assert_equal('DD', @controller.instance_eval("@deductible_group_code").group_code)
    assert_equal('DN', @controller.instance_eval("@denied_group_code").group_code)
    assert_equal('DS', @controller.instance_eval("@discount_group_code").group_code)
    assert_equal('NC', @controller.instance_eval("@noncovered_group_code").group_code)
    assert_equal('PP', @controller.instance_eval("@primary_payment_group_code").group_code)
  end
end
