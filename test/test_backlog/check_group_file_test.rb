# 
# To change this template, choose Tools | Templates
# and open the template in the editor.
 

#$:.unshift File.join(File.dirname(__FILE__),'..','lib')
require File.dirname(__FILE__)+'/../test_helper'
require 'test/unit'
require 'check_group_file'

 
class CheckGroupFileTest < ActiveSupport::TestCase
  fixtures :check_informations, :jobs, :batches, :payers, :clients, :facilities,:facility_output_configs
 
  def setup
    facility = facilities(:facility7)
    @checkgroup = CheckGroupFile.new(facility)
    @checkgroup.facility_name = facility[:name]
  end
  
  def test_file_name_south_coast
    facility = facilities(:facility_southcoast)
    client = facility.client.name
    checks = check_informations(:check_information_navicure_1, :check_information_navicure_2)
    facilities_list = ['SOUTH COAST','HORIZON EYE','SAVANNAH PRIMARY CARE','ORTHOPAEDIC FOOT AND ANKLE CTR','SAVANNAH SURGICAL ONCOLOGY','CHATHAM HOSPITALISTS','GEORGIA EAR ASSOCIATES','DAYTON PHYSICIANS LLC UROLOGY']
    if facilities_list.include?(facility.name.upcase)
      batch_id = checks.first.batch.batchid.split('_').fetch(-2)
    else
      batch_id = checks.first.batch.batchid     
    end
    actual_file_name = client+"_"+checks.first.batch.date.strftime("%y%m%d")+"_"+facility.abbr_name+"_"+batch_id+"_"+facility.name.upcase+" LOCKBOX PAYER"
    facility_config = facility_output_configs(:facility_output_config_southcoast)
    expected_file_name = facility_config.file_name
    assert_equal(expected_file_name,actual_file_name)
  end
  
  def test_file_name_operation_log
    facility = facilities(:facility_quadax)
    configured_file_name = facility.sitecode + "_" + facility.name + "_" + facility.lockbox_number + "_Operation Log"
    facility_output_config = facility_output_configs(:facility_output_config_op_log)
    expected_file_name = facility_output_config.file_name
    assert_equal(expected_file_name, configured_file_name)
  end
  
  def test_folder_structure
    checks = check_informations(:check_info5, :check_info6)
    folder_name = @checkgroup.folder_structure(checks,'835',nil)
    assert_equal(folder_name,"private/data/STANFORD UNIVERSITY MEDICAL CENTER/835s/2011-02-02/20110202_batch_65_COR_835")
  end
  
end
