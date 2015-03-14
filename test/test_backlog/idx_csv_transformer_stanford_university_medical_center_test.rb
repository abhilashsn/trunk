require File.dirname(__FILE__)+'/../test_helper'
class InputBatch::IdxCsvTransformerStanfordUniversityMedicalCenterTest < ActiveSupport::TestCase 
  fixtures :facilities, :clients
    
  def setup
    facility = facilities(:facility7)
    zip_file_name = "HTTP-LBX-IMAGED-CAFSLBX_SX2010355094155.zip"
    @transformer = IdxCsvTransformerStanfordUniversityMedicalCenter.new("#{File.dirname(__FILE__)}/../../lib/yml/idx_stanford_university_medical_center_csv.yml",facility,"/asd/asd",zip_file_name)
  end
   
  def test_find_batchid
    assert_equal("SX2010355094155", @transformer.find_batchid)
  end
end