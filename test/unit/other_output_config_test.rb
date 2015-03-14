require File.dirname(__FILE__)+'/../test_helper'
class OtherOutputConfigTest < ActiveSupport::TestCase
  

  def test_config_with_positive_data
    hash = sample_hash
    config = OtherOutput::Config.new(hash)
    config.instance_variable_set("@config", hash)
    assert_equal config.format, "csv"
    assert_equal config.grouping, "batch"
    assert_equal config.header_fields,   [["Line Total Charge", ""], ["Patient Control Number", ""], ["Payer Name", ""], ["Check Number", ""], ["Bank Acct Number", ""], ["Bank Routing Number", ""], ["Captured Provider Adjustments", ""], ["Carrier Code or Insurance Plan", ""], ["Check Batch Date", ""], ["Claim Coins Amt.", ""], ["Claim Deductible Amt.", ""], ["Claim Payment Amt.", ""], ["Client Data File", ""], ["Financial Class", ""], ["HCPCS Code", ""], ["HLSC CHECK Number", ""], ["HLSC PAYER ID", ""], ["Image Reference Number", ""], ["Invoice Number", ""], ["Line Total Payment", ""], ["LOCKBOX BATCH CUT", ""], ["LOCKBOX BATCH ID", ""], ["Lockbox Number", ""], ["Patient First Name", ""], ["Patient Last Name", ""], ["Patient Number", ""], ["Provider Adjustment", ""], ["Service Date", ""], ["Thru Date", ""], ["Transmit Date", ""], ["Batch Id", ""], ["Source File", ""], ["Lockbox Number", ""]]
    assert_equal config.zip_file_name , "[Batch date(YMMDD)][Batch date(MMDD)][NNN][Cut][3-Cut][Lockbox Number]"
    assert_equal config.file_name , "[Batch date(YMMDD)][Batch date(MMDD)][Cut][Lockbox Number][NNN][3-Cut]"
    assert_equal config.report_type, "A37 Report"

  end
  
  def test_config_with_negative_data
    hash = sample_hash
    config = OtherOutput::Config.new(hash)
    config.instance_variable_set("@config", hash)
    assert_not_equal config.format, "xml"
    assert_not_equal config.grouping, "batch date"
    # assert_not_equal config.header_fields,  [["Line Total Charge", ""], ["Patient Control Number", ""], ["Payer Name", ""], ["Check Number", ""], ["Bank Acct Number", ""], ["Bank Routing Number", ""], ["Captured Provider Adjustments", ""], ["Carrier Code or Insurance Plan", ""], ["Check Batch Date", ""], ["Claim Coins Amt.", ""], ["Claim Deductible Amt.", ""], ["Claim Payment Amt.", ""], ["Client Data File", ""], ["Financial Class", ""], ["HCPCS Code", ""], ["HLSC CHECK Number", ""], ["HLSC PAYER ID", ""], ["Image Reference Number", ""], ["Invoice Number", ""], ["Line Total Payment", ""], ["LOCKBOX BATCH CUT", ""], ["LOCKBOX BATCH ID", ""], ["Lockbox Number", ""], ["Patient First Name", ""], ["Patient Last Name", ""], ["Patient Number", ""], ["Provider Adjustment", ""], ["Service Date", ""], ["Thru Date", ""], ["Transmit Date", ""], ["Batch Id", ""], ["Source File", ""], ["Lockbox Number", ""]]

    assert_not_equal config.zip_file_name , "[][Batch date(MMDD)][NNN][Cut][3-Cut][Lockbox Number]"
    assert_not_equal config.file_name, "[][Batch date(MMDD)][Cut][Lockbox Number][NNN][3-Cut]"
    assert_not_equal config.report_type, "A36 report"    
  end

  def sample_hash
{"zip_format_options"=>"Lockbox Number", "format"=>"csv", "group by"=>"batch", "header"=>{"6"=>"Captured Provider Adjustments", "22"=>"Lockbox Number", "11"=>"Claim Payment Amt.", "7"=>"Carrier Code or Insurance Plan", "23"=>"Patient First Name", "12"=>"Client Data File", "8"=>"Check Batch Date", "24"=>"Patient Last Name", "13"=>"Financial Class", "9"=>"Claim Coins Amt.", "25"=>"Patient Number", "14"=>"HCPCS Code", "26"=>"Provider Adjustment", "15"=>"HLSC CHECK Number", "27"=>"Service Date", "16"=>"HLSC PAYER ID", "0"=>"Line Total Charge", "28"=>"Thru Date", "17"=>"Image Reference Number", "1"=>"Patient Control Number", "30"=>"Batch Id", "29"=>"Transmit Date", "18"=>"Invoice Number", "2"=>"Payer Name", "31"=>"Source File", "20"=>"LOCKBOX BATCH CUT", "19"=>"Line Total Payment", "3"=>"Check Number", "32"=>"Lockbox Number", "21"=>"LOCKBOX BATCH ID", "10"=>"Claim Deductible Amt.", "4"=>"Bank Acct Number", "5"=>"Bank Routing Number"}, "file_format_options"=>"3-Cut", "header_label"=>{"6"=>"", "22"=>"", "11"=>"", "7"=>"", "23"=>"", "12"=>"", "8"=>"", "24"=>"", "13"=>"", "9"=>"", "25"=>"", "14"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "30"=>"", "29"=>"", "18"=>"", "2"=>"", "31"=>"", "20"=>"", "19"=>"", "3"=>"", "32"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "zip_name_format"=>"[Batch date(YMMDD)][Batch date(MMDD)][NNN][Cut][3-Cut][Lockbox Number]", "report_type"=>"A37 Report", "file_name_format"=>"[Batch date(YMMDD)][Batch date(MMDD)][Cut][Lockbox Number][NNN][3-Cut]"}
  end

end
