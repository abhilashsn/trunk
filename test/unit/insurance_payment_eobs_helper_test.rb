require File.dirname(__FILE__)+'/../test_helper'

class InsurancePaymentEobsHelperTest < ActiveSupport::TestCase
  fixtures :payers, :micr_line_informations, :check_informations
  
  def setup
    @object = Object.new
    @helper = @object.extend(InsurancePaymentEobsHelper)
    Partner.expects(:is_partner_bac?).returns(false)
  end

  def test_applicable_payer_indicator

    payer_united = payers(:payer_35)
    payer_aetna_1 =  payers(:payer_36)
    payer_aetna_2 =  payers(:payer_37)
    payer_hip =  payers(:payer_38)
    payer_other = payers(:payer18)
    assert_equal([{"" => "", "CHK" => "UHC", "PAY" => "UHS"}, "UHC"], @helper.applicable_payer_indicator(payer_united.payid))
    assert_equal([{"" => "", "EOB" => "AET", "PAY" => "APP"}, ""], @helper.applicable_payer_indicator(payer_aetna_1.payid))
    assert_equal([{"" => "", "EOB" => "AET", "PAY" => "APP"}, ""], @helper.applicable_payer_indicator(payer_aetna_2.payid))
    assert_equal([{"HIP" => "HIP"}, "HIP"], @helper.applicable_payer_indicator(payer_hip.payid))
    assert_equal([{"ALL" => "ALL"}, "ALL"], @helper.applicable_payer_indicator(payer_other.payid))
  end

  def test_readonly_attribute_for_payer_details_having_check_with_mapped_payer
    @helper.instance_variable_set("@payer", payers(:payer_221))
    assert_equal(true, @helper.readonly_attribute_for_payer_address)
  end

  def test_readonly_attribute_for_payer_details_having_check_with_unmapped_payer
    @helper.instance_variable_set("@payer", payers(:payer_222))
    assert_equal(false, @helper.readonly_attribute_for_payer_address)
  end

  def test_readonly_attribute_for_payer_details_having_check_with_no_payer
    @helper.instance_variable_set("@payer", nil)
    assert_equal(false, @helper.readonly_attribute_for_payer_address)
  end

  def test_bg_color_attribute_for_payer_address_having_check_with_mapped_payer
    @helper.instance_variable_set("@payer", payers(:payer_221))
    assert_equal('background-color:#A9A9A9', @helper.bg_color_attribute_for_payer_address(true))
  end

  def test_bg_color_attribute_for_payer_address_having_check_with_unmapped_payer
    @helper.instance_variable_set("@payer", payers(:payer_222))
    assert_equal('', @helper.bg_color_attribute_for_payer_address(false))
  end

  def test_bg_color_attribute_for_payer_address_having_check_with_no_payer
    @helper.instance_variable_set("@payer", nil)
    assert_equal('', @helper.bg_color_attribute_for_payer_address(false))
  end

  def test_payer_address_not_mandatory_for_bac
    @helper.instance_variable_set("@is_partner_bac", true)
    assert_equal('', @helper.is_payer_address_mandatory)
  end

  def test_payer_address_mandatory_for_non_bac
    @helper.instance_variable_set("@is_partner_bac", false)
    assert_equal('required', @helper.is_payer_address_mandatory)
  end

  def test_set_payer_name_as_readonly_when_payer_is_accepted_and_eob_is_not_saved
    @helper.expects(:is_eob_saved?).returns(false)
    @helper.instance_variable_set("@payer", payers(:payer_221))
    assert_equal true, @helper.set_payer_name_as_readonly
  end

  def test_set_payer_name_as_readonly_when_eob_is_saved
    @helper.expects(:is_eob_saved?).returns(true)
    @helper.instance_variable_set("@payer", payers(:not_accepted_payer))
    assert_equal true, @helper.set_payer_name_as_readonly
  end

  def test_set_payer_name_as_readonly_when_payer_is_associated_to_another_check_with_micr_and_payer_is_not_accepted_and_eob_is_not_saved
    @helper.expects(:is_eob_saved?).returns(false)
    @helper.instance_variable_set("@micr_line_information", micr_line_informations(:micr_info_3))
    @helper.instance_variable_set("@payer", payers(:payer_48))

    assert_equal true, @helper.set_payer_name_as_readonly
  end

  def test_set_payer_name_as_not_readonly_when_micr_and_payer_are_not_present_with_eobs_not_saved
    @helper.expects(:is_eob_saved?).returns(false)
    @helper.instance_variable_set("@payer", nil)
    assert_equal false, @helper.set_payer_name_as_readonly
  end
  
  def test_set_payer_name_as_readonly_when_micr_is_associated_with_accepted_payer_and_eob_is_not_saved
    @helper.expects(:is_eob_saved?).returns(false)
    @helper.instance_variable_set("@payer", payers(:approved_payer))
    assert_equal true, @helper.set_payer_name_as_readonly
  end

  def test_set_payer_name_as_not_readonly_when_micr_is_not_present_with_eobs_not_saved_but_with_a_payer
    @helper.expects(:is_eob_saved?).returns(false)
    @helper.instance_variable_set("@payer", payers(:not_accepted_payer))
    assert_equal false, @helper.set_payer_name_as_readonly
  end
  
end
