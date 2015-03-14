require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/output835/quadax_eob'
require File.dirname(__FILE__)+'/../../lib/output835'

class QuadaxEobTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations
  include Output835
  
  def setup
    eob = insurance_payment_eobs(:two)
    @quadax_eob = QuadaxEob.new(eob,1,',')
  end
  
  def ntest_claim_supplemental_info
    assert_equal(@quadax_eob.claim_supplemental_info,nil)
  end
end