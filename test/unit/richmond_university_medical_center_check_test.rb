require File.dirname(__FILE__)+'/../test_helper'

class Output835::RichmondUniversityMedicalCenterCheckTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :payers
  
  def setup
    facility = facilities(:facility_3)
    @check = Output835::Check.new(check_informations(:check_7), facility, 0, '*')
    @trn_segment = "TRN*1*#{check_informations(:check_7).check_number}*1#{payers(:payer7).payer_tin}"
  end
  
  def test_reassociation_trace
     assert_equal(@trn_segment, @check.reassociation_trace)
  end
end