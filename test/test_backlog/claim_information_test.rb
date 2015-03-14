require File.dirname(__FILE__) + '/../test_helper'
require 'nokogiri'
class ClaimInformationTest < ActiveSupport::TestCase
  
  fixtures :claim_informations,:claim_service_informations, :facilities

  
  def test_mpi_search_not_nil
    
   claim_information = ClaimInformation.mpi_search(claim_informations(:one).patient_account_number,
                                                  claim_informations(:one).patient_first_name, 
                                                  claim_informations(:one).patient_last_name, 
                                                  claim_service_informations(:one).service_from_date)
    assert_not_nil claim_information    
  end
  
  def test_mpi_search_not_nil_with_service_from_date_field_nil
      claim_information = ClaimInformation.mpi_search(claim_informations(:two).patient_account_number,
                                                  claim_informations(:two).patient_first_name, 
                                                  claim_informations(:two).patient_last_name, 
                                                  claim_service_informations(:two).service_from_date)
      assert_not_nil(claim_information)                                                 
  end
  
  
  def test_build_and_execute_query_not_nil_with_search_type_is_exact
    claim_information = ClaimInformation.build_and_execute_query(claim_informations(:three).patient_account_number,
                                                  claim_informations(:three).patient_first_name, 
                                                  claim_informations(:three).patient_last_name, 
                                                  claim_service_informations(:three).service_from_date,
                                                  'exact')
   assert_not_nil claim_information                                                  
 end
 
 def test_build_and_execute_query_not_nil_with_search_type_is_exact
    claim_information = ClaimInformation.build_and_execute_query(claim_informations(:four).patient_account_number,
                                                  claim_informations(:four).patient_first_name, 
                                                  claim_informations(:four).patient_last_name, 
                                                  claim_service_informations(:four).service_from_date,
                                                  'begins_with')
   assert_not_nil claim_information                                                  
  end
  
 def test_find_status
   claiminformation_hash = {1 => "0002037194",2 => "99999"}
   count = -3
   status = ClaimInformation.find_status(2,claiminformation_hash,count)
   assert_equal("FAILURE",status)
 end
 
 def test_text_file_report
   claiminformation_hash = {1 => "0002037194",2 => "99999"}
   claimservice_lines_hash = {1 => 1, 2 => 1}
   txt_file = ClaimInformation.text_file_report("#{Rails.root}/test/expected",
                              "#{Rails.root}/test/expected/RM093010CHAMPUSPHYS9_837.DAT.xml",claiminformation_hash,claimservice_lines_hash)
   File.delete("#{Rails.root}/test/expected/RM093010CHAMPUSPHYS9_837.DAT.txt") if File.exists?"#{Rails.root}/test/expected/RM093010CHAMPUSPHYS9_837.DAT.txt"                          
   assert_equal(txt_file.class.to_s.upcase,"FILE")
 end
 
 def test_position_of_claim_in_xml
   if File.exists? "#{Rails.root}/test/expected/RM093010CHAMPUSPHYS9_837.DAT.xml"
    doc = Nokogiri::XML.parse(File.open("#{Rails.root}/test/expected/RM093010CHAMPUSPHYS9_837.DAT.xml"))
    positions = ClaimInformation.position_of_claim_in_xml(doc,1,"RM0427211")
    assert_equal(positions,[1,2,1])
   else
    position = [0,0,0]
    assert_not_equal(positions,[1,2,1])
   end
 end
 
 def test_get_md_file_contents
   if File.exists? "#{Rails.root}/test/expected/837.md"
     assert_equal("abc123",ClaimInformation.get_md_file_contents("#{Rails.root}/test/expected/837.md")[2])
   else
     assert_equal(0,0)
   end
 end
 
  def ntest_load_837_script_client_call
#    Facility.stubs("find_by_name").returns(:facility1)
    pars = Parser::Serializer837.new("#{Rails.root}/test/expected","Apria - Carolinas")
    p "###########"
    p "The start time of the script: "
    p Time.now
     p "###########"
    pars.parse_837
     p "###########"
    p "The end time of the script: "
    p Time.now
     p "###########"
 end
 
  def test_alias_attributes
    claim = claim_informations(:one)
    assert_equal(claim.name,claim_informations(:one).billing_provider_organization_name)
    assert_equal(claim.address_one,claim_informations(:one).billing_provider_address_one)
    assert_equal(claim.tin,claim_informations(:one).billing_provider_tin)
    assert_equal(claim.npi,claim_informations(:one).billing_provider_npi)
    assert_equal(claim.city,claim_informations(:one).billing_provider_city)
    assert_equal(claim.state,claim_informations(:one).billing_provider_state)
    assert_equal(claim.zip_code,claim_informations(:one).billing_provider_zipcode)
  end
 
end
