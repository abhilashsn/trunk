require File.dirname(__FILE__)+'/../test_helper'
require 'csv'
class InputBatch::IdxDatTransformerDaytonPhysiciansTest < ActiveSupport::TestCase
  fixtures :facilities, :clients
  def setup
    facility = facilities(:facility7)
    zip_file_name = "HORIZANLAB.CMS.LBX2.20101013204543_VENDOR_HX2010286205235_20101013205233"
    @transformer = IdxDatTransformerDaytonPhysicians.new("#{File.dirname(__FILE__)}/../../lib/yml/idx_dayton_physicians_dat.yml",facility,"/asd/asd",zip_file_name)
    dat = File.readlines("#{File.dirname(__FILE__)}/../expected/index.dat")     
    dat.each do |r|
      @transformer.row = r.chomp.strip
      if r[0..0] == "5"
      break
      end
    end
    @transformer.type = "CK"
  end
  
   def test_find_type 
     assert_equal("CK",@transformer.find_type)
  end
  
  def test_job_condition
    assert_equal(true,@transformer.job_condition)
  end
  
  def test_find_batchid
    assert_equal("99999",@transformer.find_batchid)
  end
  
end