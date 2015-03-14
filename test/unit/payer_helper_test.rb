require File.dirname(__FILE__)+'/../test_helper'

class PayerHelperTest < ActiveSupport::TestCase
  include Admin::PayerHelper
  fixtures :payers, :micr_line_informations, :check_informations

  def setup
    @controller = Admin::PayerController.new
    @object = Object.new
    @helper = @object.extend(Admin::PayerHelper)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Approval UI. |
  # Assumption: Partner is BAC                                                 |
  # Input  : Commercial payer                                                  |
  # Output : Returns true as Payer ID is non editable for BAC.                 |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_approval_of_bac
    commercial_payer = payers(:payer_228)
    @helper.instance_variable_set("@is_partner_bac", true)
    @helper.instance_variable_set("@payer", commercial_payer)
    assert_equal(true, @helper.readonly_payid_conditions_for_payer_approval, "Payer ID is readonly for BAC")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Approval UI. |
  # Assumption: Partner is Non BAC                                             |
  # Input  : Patient pay payer                                                 |
  # Output : Returns true as Payer ID is non editable for Patient pay payer.   |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_approval_of_patient_pay_payers_of_non_bac
    patpay_payer = payers(:payer_227)
    @helper.instance_variable_set("@is_partner_bac", false)
    @helper.instance_variable_set("@payer", patpay_payer)
    assert_equal(true, @helper.readonly_payid_conditions_for_payer_approval, "Payer ID is readonly for patpay payers")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Approval UI. |
  # Assumption: Partner is Non BAC                                             |
  # Input  : Mapped Commercial payer                                           |
  # Output : Returns true as Payer ID is non editable for mapped payers.       |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_approval_of_mapped_payers_of_non_bac
    mapped_commercial_payer = payers(:payer_229)
    @helper.instance_variable_set("@is_partner_bac", false)
    @helper.instance_variable_set("@payer", mapped_commercial_payer)
    assert_equal(true, @helper.readonly_payid_conditions_for_payer_approval, "Payer ID is readonly for mapped payers")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Approval UI. |
  # Assumption: Partner is Non BAC                                             |
  # Input  : Commercial payer                                                  |
  # Output : Returns false as Payer ID is editable for Commercial payer.       |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_approval_of_commercial_payers_of_non_bac
    commercial_payer = payers(:payer_228)
    @helper.instance_variable_set("@is_partner_bac", false)
    @helper.instance_variable_set("@payer", commercial_payer)
    assert_equal(false, @helper.readonly_payid_conditions_for_payer_approval, "Payer ID is editable only for commercial payers of non bank")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Administration UI.
  # Assumption: Partner is BAC                                                 |
  # Input  : Commercial payer                                                  |
  # Output : Returns true as Payer ID is non editable for BAC.                 |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_administarion_of_bac
    commercial_payer = payers(:payer_228)
    @helper.instance_variable_set("@is_partner_bac", true)
    @helper.instance_variable_set("@payer", commercial_payer)
    assert_equal(true, @helper.readonly_payid_conditions_for_payer_administarion, "Payer ID is readonly BAC")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Administration UI.
  # Assumption: Partner is Non BAC                                             |
  # Input  : Patient Pay payer                                                 |
  # Output : Returns true as Payer ID is non editable for Patient Pay payers.  |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_administarion_of_patpay_payer_with_non_bac
    patpay_payer = payers(:payer_227)
    @helper.instance_variable_set("@is_partner_bac", false)
    @helper.instance_variable_set("@payer", patpay_payer)
    assert_equal(true, @helper.readonly_payid_conditions_for_payer_administarion, "Payer ID is readonly for patpay payers")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Administration UI.
  # Assumption: Partner is Non BAC                                             |
  # Input  : Insurance payer                                                   |
  # Output : Returns true as Payer ID is non editable for Insurance payers.    |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_administarion_of_insurance_payer_with_non_bac
    insurance_payer = payers(:payer_300)
    @helper.instance_variable_set("@is_partner_bac", false)
    @helper.instance_variable_set("@payer", insurance_payer)
    assert_equal(true, @helper.readonly_payid_conditions_for_payer_administarion, "Payer ID is readonly for insurance payers")
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the readonly conditions of PayId in Payer Administration UI.
  # Assumption: Partner is Non BAC                                             |
  # Input  : Commercial payer                                                  |
  # Output : Returns false as Payer ID is editable for Commercial payer.       |
  # Owner  : Ramya Periyangat                                                  |
  # +--------------------------------------------------------------------------+
  def test_readonly_payid_conditions_for_payer_administarion_of_commercial_payer_with_non_bac
    commercial_payer = payers(:payer_228)
    @helper.instance_variable_set("@is_partner_bac", false)
    @helper.instance_variable_set("@payer", commercial_payer)
    assert_equal(false, @helper.readonly_payid_conditions_for_payer_administarion, "Payer ID is editable for Commercial payers")
  end
end
