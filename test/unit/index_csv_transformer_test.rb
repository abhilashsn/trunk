require File.dirname(__FILE__)+'/../test_helper'

class InputBatch::IndexCsvTransformerTest < ActiveSupport::TestCase
  fixtures :facilities, :clients, :jobs, :client_images_to_jobs, :images_for_jobs 
  
    #this test needs to be fixed by the developer and checked in
  
  def setup
    @tranf = InputBatch::IndexCsvTransformer.new('D:/ongoing_dev/lib/yml/idx_pathology_consultants_llc_csv.yml', facilities(:facility_4), 'test_location', 'PATHOLOGYCONSULTANTS_12082010_VENDOR_YM2010342065344.zip')
    @transformer = InputBatch::IndexCsvTransformer.new('D:/ongoing_dev/lib/yml/idx_pathology_consultants_llc_csv.yml', facilities(:facility_153), 'D:/ongoing_dev/test/expected', 'PATHOLOGYCONSULTANTS_12082010_VENDOR_YM2010342065344_20101208065344')
  end
  
   def ntest_number_of_pages
    assert_equal(3,@transformer.number_of_pages(jobs(:job_56)))
  end
  
  def ntest_get_batchid_quadax
    assert_equal('YM2010342065344', @tranf.get_batchid_quadax)
  end
end