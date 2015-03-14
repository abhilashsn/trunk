require File.dirname(__FILE__)+'/../test_helper'
require 'csv'

class InputBatch::CsvParserTest < ActiveSupport::TestCase
  fixtures :facilities, :clients, :batches
  
  def setup
    InputBatch::Log.instance_variable_set(:@status_logger, Logger.new("#{Rails.root}/test/expected/BatchLoadingStatus.log"))
    InputBatch::Log.instance_variable_set(:@error_logger, Logger.new("#{Rails.root}/test/expected/BatchLoadingError.log"))
    
    facility = facilities(:facility_23) 
    location = "#{File.dirname(__FILE__)}/../expected/batch"   
    @transformer = InputBatch::CsvParser.new("#{Rails.root}/lib/yml/idx_boa_csv.yml",facility,location,"0816B890")
    @index_file = "#{File.dirname(__FILE__)}/../expected/SUMMARY.CSV"    
  end
  
  def test_find_type
    assert_equal("PAYMENT", @transformer.find_type)
  end
  
  #invalid test accessing a non-existent method
  def test_conf
    @transformer.transform(@index_file) 
    assert_equal(@transformer.instance_variable_get("@config_hash")['BANK_OF_AMERICA']['PAYMENT'],  @transformer.config)
  end
  
  def test_valid_record?
    @transformer.transform(@index_file) 
    assert(@transformer.valid_record?)
  end
  
  def test_get_batchid_general
    @transformer.transform(@index_file) 
    assert_equal("32_08162010",@transformer.get_batchid_general)
  end
  
  def test_find_batchid
    @transformer.transform(@index_file) 
    assert_equal("ZZZZZW",@transformer.find_batchid)
  end
  
  def test_job_condition
    @transformer.transform(@index_file) 
    assert(@transformer.job_condition)
  end
  
  def test_parse
    @transformer.transform(@index_file) 
    assert_equal("G-2073878",@transformer.parse(2) )
  end
  
  def test_prepare_batch
    @transformer.transform(@index_file) 
    assert_equal("ZZZZZW", @transformer.prepare_batch)
  end
  
  def test_prepare_cheque
    @transformer.transform(@index_file)
    assert_equal(CheckInformation, @transformer.prepare_cheque.class)
  end

  def test_unique_date
    @transformer.transform(@index_file)
    assert_equal(true, @transformer.unique_date?)
  end
  
end