require File.dirname(__FILE__)+'/../test_helper'

class Output835::ShepherdEyeSurgicenterServiceTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :isa_identifiers, \
      :payers, :insurance_payment_eobs, :images_for_jobs, :client_images_to_jobs, :service_payment_eobs
      
      # :claim_informations,
  
  def setup
    payer = payers(:payer7)
    facility = facilities(:facility_3)
    Partner.expects(:is_partner_bac?).at_least_once.returns(false)
    @service1 = Output835::ShepherdEyeSurgicenterService.new(service_payment_eobs(:four), facility, payer, 1, '*')
    @eob2 = Output835::ShepherdEyeSurgicenterEob.new(insurance_payment_eobs(:four), facility, payer, 1, '*')
    @service_date_segment = ["DTM*150*#{service_payment_eobs(:four).date_of_service_from.\
        strftime("%Y%m%d")}","DTM*151*#{service_payment_eobs(:four).date_of_service_to.strftime("%Y%m%d")}"]
    @ref_segment = "REF*6R*#{service_payment_eobs(:four).service_reference_identification_number}"
    @service_segments = [@service1.service_payment_information, @service1.service_date_reference, \
        @service1.provider_control_number, @service1.service_supplemental_amount]\
        .compact.flatten
  end
  
  def test_generate
    assert_equal(@service_segments, @service1.generate)
  end
  
  def test_service_date_reference
    assert_equal(@service_date_segment, @service1.service_date_reference)
  end
  
  def test_provider_control_number
    assert_equal(@ref_segment, @service1.provider_control_number)
  end
end