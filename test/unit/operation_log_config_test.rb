require File.dirname(__FILE__)+'/../test_helper'
class OperationLogConfigTest < ActiveSupport::TestCase

  def test_process_config_with_positive_data
    hash = sample_hash
    config = OperationLog::Config.new(hash)
    assert_equal config.file_name ,"[Client Id]_[Batch date(YYMMDD)]_[Facility Name abbreviation]_[Batch date(DD_MM_YY)]"
    assert_equal config.format, "xls"
    assert_equal config.content_layout, "check"
    assert_equal config.group_by, ["batch date", "payer"]
    assert_equal config.header_fields, [["Facility Name", "", ""], ["Batch Name", "", ""], ["Deposit Date", "", ""], ["Export Date", "", ""], ["Check", "", ""], ["Check Amount", "", ""], ["Check Date", "", ""], ["Check Number", "", ""], ["Sub Total", "", ""], ["Eft Amount", "", ""], ["Payer Name", "", ""], ["Processed (Y/N)", "", ""], ["Image Id", "", ""], ["Zip File Name", "", ""], ["Reason Not Processed", "", ""], ["Statement #", "", ""], ["Processed (Y/N)", "", ""], ["Payer", "", ""], ["Correspondence", "", ""], ["Eft Amount", "", ""], ["835 Amount", "", ""], ["Harp Source", "", ""]]
    assert_equal config.custom_header_fields,  ["custom Field One", "Custome Field Two", "custome Field Three", "custome Field Four", "Custome Field Five"]
    assert_equal config.summary_fields,[]
    assert_equal config.summary_position, "footer"
    assert_equal config.summarize_by, nil
    assert_equal config.quote_prefixed,false
    assert_equal config.show_summary_header,true
    assert_equal config.summary_header,"Summary:"
    assert_equal config.total,[["Batch Total", ""], ["Grand Total", ""], ["Payer Total", ""]]
    assert_equal config.primary_group, "payer"
    assert_equal config.for_date, true
    assert_equal config.for_facility, false
    assert_equal config.batch_total, true
    assert_equal config.payer_total, true
    assert_equal config.grand_total, true
    assert_equal config.deposit_total, false
    assert_equal config.without_batch_grouping,true
  end

  def test_process_config_with_negative_assertions
    hash = sample_hash
    config = OperationLog::Config.new(hash)
    assert_not_equal config.file_name ,"[Client]_[Batch date(YYMMDD)]_[Facility Name abbreviation]_[Batch date(DD_MM_YY)]"
    assert_not_equal config.format, "txt"
    assert_not_equal config.content_layout, "eob"
    assert_not_equal config.group_by, ["batch date"]
    assert_not_equal config.header_fields, [["Facility Name", "", ""], ["Batch Name", "", ""], ["Deposit Date", "", ""], ["Export Date", "", ""], ["Check", "", ""], ["Check Amount", "", ""], ["Check Date", "", ""], ["Check Number", "", ""], ["Sub Total", "", ""], ["Eft Amount", "", ""], ["Payer Name", "", ""], ["Processed (Y/N)", "", ""], ["Image Id", "", ""], ["Zip File Name", "", ""], ["Reason Not Processed", "", ""], ["Statement #", "", ""]]
    assert_not_equal config.custom_header_fields,  ["custom Field One"]
    assert_not_equal config.summary_fields,["one"]
    assert_not_equal config.summary_position, "header"
    assert_not_equal config.summarize_by,"d"
    assert_not_equal config.quote_prefixed,true
    assert_not_equal config.show_summary_header,false
    assert_not_equal config.summary_header,""
    assert_not_equal config.total,[["", ""], ["Grand Total", ""], ["Payer Total", ""]]
    assert_not_equal config.primary_group, "batch"
    assert_not_equal config.for_date, false
    assert_not_equal config.for_facility, true
    assert_not_equal config.batch_total, false
    assert_not_equal config.payer_total, false
    assert_not_equal config.grand_total, false
    assert_not_equal config.deposit_total, true
    assert_not_equal config.without_batch_grouping,false
  end

  private
  
  def sample_hash
    {"summary_field_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>"", "5"=>""}, "group_by"=>{"0"=>"batch date", "1"=>"payer", "2"=>"", "3"=>""}, "summary_field"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>"", "4"=>"", "5"=>""}, "oplogformat"=>"xls", "prefix_quotes"=>"", "total"=>{"0"=>"Batch Total", "1"=>"Grand Total", "2"=>"Payer Total", "3"=>""}, "header"=>{"22"=>"", "11"=>"Processed (Y/N)", "6"=>"Check Date", "23"=>"", "12"=>"Image Id", "7"=>"Check Number", "24"=>"", "13"=>"Zip File Name", "8"=>"Sub Total", "25"=>"", "14"=>"Reason Not Processed", "9"=>"Eft Amount", "26"=>"", "15"=>"Statement #", "27"=>"", "16"=>"Processed (Y/N)", "0"=>"Facility Name", "28"=>"", "17"=>"Payer", "1"=>"Batch Name", "18"=>"Correspondence", "2"=>"Deposit Date", "20"=>"835 Amount", "19"=>"Eft Amount", "3"=>"Export Date", "21"=>"Harp Source", "10"=>"Payer Name", "4"=>"Check", "5"=>"Check Amount"}, "header_rules"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "header_label"=>{"22"=>"", "11"=>"", "6"=>"", "23"=>"", "12"=>"", "7"=>"", "24"=>"", "13"=>"", "8"=>"", "25"=>"", "14"=>"", "9"=>"", "26"=>"", "15"=>"", "27"=>"", "16"=>"", "0"=>"", "28"=>"", "17"=>"", "1"=>"", "18"=>"", "2"=>"", "20"=>"", "19"=>"", "3"=>"", "21"=>"", "10"=>"", "4"=>"", "5"=>""}, "content_layout"=>"check", "total_label"=>{"0"=>"", "1"=>"", "2"=>"", "3"=>""}, "custom_header"=>{"0"=>"custom Field One", "1"=>"Custome Field Two", "2"=>"custome Field Three", "3"=>"custome Field Four", "4"=>"Custome Field Five"}, "summary_header"=>"Summary:", "summary_position"=>"footer", "file_name_format"=>"[Client Id]_[Batch date(YYMMDD)]_[Facility Name abbreviation]_[Batch date(DD_MM_YY)]"}
  end
  
end
