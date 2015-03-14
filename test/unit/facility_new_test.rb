require File.dirname(__FILE__) + '/../test_helper'
require 'facility'

class FacilityNewTest < ActiveSupport::TestCase
  fixtures :facilities
  
  def test_claim_level_eob_type_not_nil
    claim_level_eob = facilities(:facility_1).details[:claim_level_eob]
    assert_not_nil(claim_level_eob, "Not nil") 
    assert(claim_level_eob)
  end
  
  def test_claim_level_eob_type_nil
    claim_level_eob = facilities(:facility_2).details[:claim_level_eob]
    assert_not_nil(claim_level_eob, "Not nil") 
    assert !(claim_level_eob)
  end
  
end
