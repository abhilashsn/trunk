require File.dirname(__FILE__)+'/../test_helper'

class Output835::ShepherdEyeSurgicenterCheckTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :isa_identifiers, :payers, :insurance_payment_eobs, :claim_informations
  
    
  def setup
    @check = Output835::ShepherdEyeSurgicenterCheck.new(check_informations(:check_7), facilities(:facility_3), 0, '*')
    @payee =  claim_informations(:four)
    @st_segment = "ST*835*000000001"
    @trn_segment = "TRN*1*#{check_informations(:check_7).check_number}*#{payers(:payer7).payid}"
    @ref_segment = "REF*TJ"
    @lx_segment = "LX*1"
    @address_segment_facility = "N3*#{facilities(:facility_3).address_one.upcase}"
    @address_segment_payer = "N3*#{payers(:payer7).pay_address_one.upcase}*#{payers(:payer7).pay_address_two.upcase}"
    @plb_segment = "PLB*#{facilities(:facility_3).facility_npi}*20121231*#{check_informations(:check_7).provider_adjustment_qualifier}*#{-1 * check_informations(:check_7).provider_adjustment_amount.to_i}"
    @segment_count = 50
    @se_segment = "SE*#{@segment_count}*000000001"
  end
  
  def test_transaction_set_header
    assert_equal(@st_segment, @check.transaction_set_header)
  end
  
  def test_reassociation_trace
     assert_equal(@trn_segment, @check.reassociation_trace)
  end
  
  def test_transaction_set_line_number
    assert_equal(@lx_segment, @check.transaction_set_line_number)
  end
  
  def test_address
    assert_equal(@address_segment_facility, @check.address(facilities(:facility_3)))
    assert_equal(@address_segment_payer, @check.address(payers(:payer7)))
  end
  
  def test_provider_adjustment
    assert_equal(@plb_segment, @check.provider_adjustment)
  end
  
  def test_transaction_set_trailer
    assert_equal(@se_segment, @check.transaction_set_trailer(@segment_count))
  end
  
  def test_payer_id
    assert_equal(payers(:payer7).payid, @check.payer_id)
  end

end