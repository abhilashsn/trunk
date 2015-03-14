require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/output835/eob'
require File.dirname(__FILE__)+'/../../lib/output835'

class QuadaxEobTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :facilities, :payers
  include Output835
  
  def setup
    eob1 = insurance_payment_eobs(:one)
    eob2 = insurance_payment_eobs(:two)
    facility = facilities(:facility_2)
    payer = payers(:payer2)
    @eob1 = Eob.new(eob1,facility, payer, 1, '*')
    @eob2 = Eob.new(eob2, facility, payer, 2, '*')
  end
  
  def test_claim_level_eob
    assert_equal(@eob1.claim_level_eob?, true)
    assert_equal(@eob2.claim_level_eob?, false)
  end
  
  def test_claim_from_date
    assert_equal( @eob1.claim_from_date, "DTM*232*20090216",
                 message = "DTM*232*claim_from_date should be there." )
    assert_equal( @eob2.claim_from_date, nil,
                 message = "DTM*232*claim_to_date should not be there.")
  end
  
  def test_claim_to_date
   assert_equal(@eob1.claim_to_date, "DTM*233*20090217",
                message = "DTM*233*claim_to_date should be there." ) 
   assert_equal(@eob2.claim_to_date, nil,
                message = "DTM*233*claim_to_date should not be there." )               
  end
end