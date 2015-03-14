require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/check_segregator'

class CheckSegregatorTest < ActiveSupport::TestCase
  fixtures :check_informations, :jobs, :batches, :payers, :clients, :facilities

  def setup
    @check_segregator = CheckSegregator.new("", "")
  end
  
  def test_payer_type_correspondence
    check = check_informations(:check_information14)
    correspondence_check = @check_segregator.payer_group_indexed_image(check)
    assert_equal(correspondence_check, 'corr')
  end
  
  def test_payer_type_patpay
    check = check_informations(:check_information15)
    patpay_check = @check_segregator.payer_group_indexed_image(check)
    assert_equal(patpay_check, 'patpay')
  end
  
  def test_payer_type_insurance
    check = check_informations(:check_information16)
    insurance_check = @check_segregator.payer_group_indexed_image(check)
    assert_equal(insurance_check, 'insurance')
  end
end
