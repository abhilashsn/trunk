require File.dirname(__FILE__)+'/../test_helper'

class InputBatch::IndexXmlTransformerTest < ActiveSupport::TestCase
  fixtures :facilities, :jobs, :client_images_to_jobs, :images_for_jobs, :facilities, :clients 
  def setup
    @transformer = InputBatch::IndexCsvTransformer.new('D:/ongoing_dev/lib/yml/idx_medistreams_xml.yml', facilities(:facility_153), 'D:/ongoing_dev/test/expected', '12082010_VENDOR_YM2010342065344_20101208065344')
  end
  
    #this test needs to be fixed by the developer and checked in
  def ntest_number_of_pages
    assert_equal(3,@transformer.number_of_pages(jobs(:job_56)))
  end
end