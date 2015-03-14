require File.dirname(__FILE__) + '/../test_helper'

class ClaimServiceInformationTest < ActiveSupport::TestCase
  def test_total_charges_amount_not_nil
      id = 1    
      result = ClaimServiceInformation.total_charges_amount(id)
      assert_not_nil(result, message = "Nil")
 end
 
  def test_total_charges_amount_nil
      id = 999    
      result = ClaimServiceInformation.total_charges_amount(id)
      assert_not_nil(result, message = "Not Nil")
 end
 
  def test_get_service_lines_size
    claiminformation_hash = {1 => "120",2 => "234"}
    count = ClaimServiceInformation.find_by_sql("select * from 
            claim_service_informations where claim_information_id in (1,2)").length
    result = ClaimServiceInformation.get_service_lines_size(claiminformation_hash)
    assert_equal(count,result)
  end
end
