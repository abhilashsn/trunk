require File.dirname(__FILE__)+'/../test_helper'

class Output835::ShepherdEyeSurgicenterEobTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :isa_identifiers, \
      :payers, :insurance_payment_eobs, :images_for_jobs, :client_images_to_jobs,
      :claim_informations
  
  def setup
    payer = payers(:payer7)
    facility = facilities(:facility_3)
    @eob1 = Output835::ShepherdEyeSurgicenterEob.new(insurance_payment_eobs(:three), facility, payer, 1, '*')
    @eob2 = Output835::ShepherdEyeSurgicenterEob.new(insurance_payment_eobs(:four), facility, payer, 1, '*')
    @nm1_segment1 = "NM1*82*2*#{facilities(:facility_3).name.upcase}*****FI*#{insurance_payment_eobs(:three).provider_tin}"
    @nm1_segment2 = "NM1*82*1*#{insurance_payment_eobs(:four).rendering_provider_last_name.\
        strip}*#{insurance_payment_eobs(:four).rendering_provider_first_name}*#{insurance_payment_eobs(:four).\
        rendering_provider_middle_initial}***FI*#{insurance_payment_eobs(:four).provider_tin}"
    @ref_segment = "REF*F8*#{images_for_jobs(:image12).original_file_name}"
  end
  
  def test_service_prov_name
    assert_equal(@nm1_segment1, @eob1.service_prov_name)
    assert_equal(@nm1_segment2, @eob2.service_prov_name)
  end
  
  def test_other_claim_related_id
    assert_equal(@ref_segment, @eob1.other_claim_related_id)
  end
  
  def test_service_payee_identification
    assert_equal([facilities(:facility_3).facility_npi,'XX'],@eob1.service_payee_identification)
    assert_equal([facilities(:facility_3).facility_npi,'XX'],@eob2.service_payee_identification)
  end
end