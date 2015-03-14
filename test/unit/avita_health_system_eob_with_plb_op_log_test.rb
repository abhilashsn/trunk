require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__)+'/../../lib/operation_log/avita_health_system_eob_with_plb'

class AvitaHealthSystemEobWithPlbOpLogTest < ActiveSupport::TestCase
  fixtures :batches, :jobs, :provider_adjustments
  include OperationLog::AvitaHealthSystemEobWithPlb

  # ************************ Tests For Lockboxes other than 637234, 637260, 637235 *******************

  def test_insurance_client_code_for_a_batch_of_different_lockbox_not_applied_for_printing_client_code_in_op_log
    @batch = batches(:batch78)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_patpay_client_code_for_a_batch_of_different_lockbox_not_applied_for_printing_client_code_in_op_log
    @batch = batches(:batch78)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000002")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  # ************************ Tests For Lockbox Number 637234 *******************

  def test_client_code_for_insurance_eob_with_number_nil_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => nil)
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end
  
  def test_client_code_for_insurance_eob_with_number_0003buxpo_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_000300_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "000300")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_001g4xpo_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'G4XP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_length_6_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'B2XP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_003buxpo_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "003BUXP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_0003123abc_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003123ABC")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_nil_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => nil)
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_0003buxpo_and_format_a_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_001g4xpo_and_format_a_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_b_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_c_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000002_and_format_c_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000002")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000003_and_format_a_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000003")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000001_and_format_c_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000001")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_00000003buxpo_and_format_c_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "00000003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_a_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end


  # ************************ Tests For Lockbox Number 637260 *******************

  def test_client_code_for_insurance_eob_with_number_nil_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => nil)
    observed_client_code = eval_plb_client_code
    expected_client_code = 'CHXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_0003buxpo_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_000300_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "000300")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_001g4xpo_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'G4XP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_length_6_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'CHXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_000003_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "000003")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'CHXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_0003123abc_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003123ABC")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_nil_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => nil)
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_0003buxpo_and_format_a_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_001g4xpo_and_format_a_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_b_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_c_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000002_and_format_c_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000002")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000003_and_format_a_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000003")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000001_and_format_c_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000001")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_00000003buxpo_and_format_c_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "00000003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_a_in_lockbox_637260
    @batch = batches(:batch75)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  # *****************************Tests for Lockbox Number 637235 *********************************

  def test_client_code_for_insurance_eob_with_number_nil_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => nil)
    observed_client_code = eval_plb_client_code
    expected_client_code = 'G4XP'
    assert_equal expected_client_code, observed_client_code
  end
  
  def test_client_code_for_insurance_eob_with_number_0003buxpo_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_000300_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "000300")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_001g4xpo_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'G4XP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_length_6_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'GHXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_001g4xpo_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'G4XP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_insurance_eob_with_number_0003123abc_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003123ABC")
    observed_client_code = eval_plb_client_code
    expected_client_code = 'BUXP'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_nil_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => nil)
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_0003buxpo_and_format_a_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "0003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_001g4xpo_and_format_a_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_b_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_c_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000002_and_format_c_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000002")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000003_and_format_a_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000003")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000001_and_format_c_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000001")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_000001_and_format_a_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "000001")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_00000003buxpo_and_format_c_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "00000003BUXPO")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  def test_client_code_for_patpay_eob_with_number_123456_and_format_a_in_lockbox_637235
    @batch = batches(:batch76)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "123456")
    observed_client_code = eval_plb_client_code
    expected_client_code = '-'
    assert_equal expected_client_code, observed_client_code
  end

  #  *******************Xpeditor Number********************

  def test_xpeditor_number_for_insurance_eob_with_number_001g4xpo_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'Insurance')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_xpeditor_number = eval_plb_xpeditor_document_number
    expected_xpeditor_number = 'G4XP'
    assert_equal expected_xpeditor_number, observed_xpeditor_number
  end

  def test_xpeditor_number_for_insurance_eob_with_number_001g4xpo_in_lockbox_637234
    @batch = batches(:batch74)
    @job = Job.new(:payer_group => 'PatPay')
    @eob = ProviderAdjustment.new(:patient_account_number => "001G4XP0")
    observed_xpeditor_number = eval_plb_xpeditor_document_number
    expected_xpeditor_number = '-'
    assert_equal expected_xpeditor_number, observed_xpeditor_number
  end

end
