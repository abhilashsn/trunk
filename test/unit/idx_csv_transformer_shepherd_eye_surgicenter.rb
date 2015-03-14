require File.dirname(__FILE__)+'/../test_helper'
require 'csv'
class InputBatch::IdxCsvTransformerShepherdEyeSurgicenterTest < ActiveSupport::TestCase
  fixtures :facilities, :clients
  def setup
    facility = facilities(:facility7)
    zip_file_name = "HORIZANLAB.CMS.LBX2.20101013204543_VENDOR_HX2010286205235_20101013205233"
    @transformer = IdxCsvTransformerShepherdEyeSurgicenter.new("#{File.dirname(__FILE__)}/../../lib/yml/idx_navicure_csv.yml",facility,"/asd/asd",zip_file_name)
    csv = CSV.open("#{File.dirname(__FILE__)}/../expected/1cQC056g-clinic_111710.csv", "r", :headers => @transformer.cnf['PAYMENT']['HEADER'] || false)     
    csv.each do |r|
      @transformer.row = r
      break
    end
  end
  
   def test_find_type
     @transformer.find_type
     assert_equal("PAYMENT",@transformer.type)
  end
  
  def test_find_batchid
    @transformer.type = "PAYMENT"
    assert_equal("111710_11172010",@transformer.find_batchid)
  end
  
  def test_job_condition
    @transformer.type = "PAYMENT"
    assert_equal(true,@transformer.job_condition)
  end
  
  
end