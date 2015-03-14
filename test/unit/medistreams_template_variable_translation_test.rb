require File.dirname(__FILE__)+'/../test_helper'

class OutputXml::MedistreamsTemplateVariableTranslationsTest < ActiveSupport::TestCase
  fixtures :batches, :jobs, :facilities, :clients, :check_informations, :payers,
    :reason_code_set_names, :reason_codes_clients_facilities_set_names, :reason_codes
  
  def setup
    checks = [check_informations(:check_303)]
    @output_xml_obj = OutputXml::Document.new(checks)
    @reason_code1 = reason_codes(:reason_code8).reason_code_description
    @reason_code2 = reason_codes(:reason_code9).reason_code_description
    @reason_code3 = reason_codes(:reason_code10).reason_code_description
  end
  
  # Testing the validity of reason code description data. It should contain only 
  # alphabets, numeric, periods, hyphen(-), space, comma(,), slash(/), ')', '('and
  # underscore(_). All other special charactes should be removed from desc before printing in output.
  def test_format_reason_code_description
    valid_rc_desc = "The impact of prior payer(s) adjudication including payments and/or adjustments"
    assert_equal(valid_rc_desc, @output_xml_obj.format_reason_code_description(@reason_code1))
    assert_equal(valid_rc_desc, @output_xml_obj.format_reason_code_description(@reason_code2))
    assert_equal(valid_rc_desc, @output_xml_obj.format_reason_code_description(@reason_code3))
  end
  
end
