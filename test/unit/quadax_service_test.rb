require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/output835/quadax_service'
require File.dirname(__FILE__)+'/../../lib/output835'

class QuadaxServiceTest < ActiveSupport::TestCase
  fixtures :jobs, :batches,:facilities,:insurance_payment_eobs, :check_informations, :service_payment_eobs, :payers
  include Output835
  
  def setup
    facility = facilities(:facility1)
    payer = payers(:two)
    service = service_payment_eobs(:two)
    @quadax_service = QuadaxService.new(service, facility, payer, 1, ',')
  end
  
  def ntest_service_payment_information
    assert_equal(@quadax_service.service_payment_information,nil)
  end

  def ntest_service_date_reference
    assert_equal(@quadax_service.service_date_reference,nil)
  end  
end