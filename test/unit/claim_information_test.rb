require File.dirname(__FILE__) + '/../test_helper'

class ClaimInformationTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations, :claim_informations, :claim_service_informations 
    
  def test_least_date_for_mpi_svc_line
    insurance_payment_eob1 = insurance_payment_eobs(:eob_55)
    insurance_payment_eob2 = insurance_payment_eobs(:eob_56)
    claim_info_for_eob1 = insurance_payment_eob1.claim_information
    claim_info_for_eob2 = insurance_payment_eob2.claim_information
    least_service_line1 = claim_info_for_eob1.least_date_for_mpi_svc_line
    least_service_line2 = claim_info_for_eob2.least_date_for_mpi_svc_line
    assert_equal(least_service_line1, Date.parse('2011-09-09'))
    assert_equal(least_service_line2, Date.parse('2011-09-22'))
  end
  
end
