require File.dirname(__FILE__)+'/../test_helper'
require 'csv'
class InputBatch::IndexDatTransformerTest < ActiveSupport::TestCase
  fixtures :facilities, :clients
  def setup
    facility = facilities(:facility7)
    zip_file_name = "HORIZANLAB.CMS.LBX2.20101013204543_VENDOR_HX2010286205235_20101013205233"
    @transformer = InputBatch::IndexDatTransformer.new("#{File.dirname(__FILE__)}/../../lib/yml/idx_atlanticar_clinical_lab_dat.yml",facility,"/asd/asd",zip_file_name)
    dat = File.readlines("#{File.dirname(__FILE__)}/../expected/images.dat")     
    dat.each do |r|
      @transformer.row = r.split
      break
    end
    @transformer.type = "CK"
    @transformer1 = InputBatch::IndexDatTransformer.new("#{File.dirname(__FILE__)}/../../lib/yml/idx_atlanticar_clinical_lab_dat.yml",facility,"/asd/asd",'2102011 234805 PMA5_A52011041181722.zip')
  end
    #this test needs to be fixed by the developer and checked in
   def ntest_find_type 
     assert_equal("CK",@transformer.find_type)
  end
  
  def test_get_check_details
    assert_equal(["343","10.00"],@transformer.get_check_details("10.00343"))
  end
    #this test needs to be fixed by the developer and checked in
  def ntest_job_condition
    assert_equal(true,@transformer.job_condition)
  end
   #this test needs to be fixed by the developer and checked in 
  def ntest_get_lockbox
    assert_equal("785616",@transformer.get_lockbox)
  end
  
  def test_find_batchid
    assert_equal("A52011041181722",@transformer1.find_batchid)
  end
  
  def test_get_batch_date
    assert_equal("2010-10-22",@transformer.get_batch_date)
  end
  
end