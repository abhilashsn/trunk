require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/operation_log_csv/quadax_eob'
require File.dirname(__FILE__)+'/../../lib/operation_log_csv'

class OperationLogCsvQuadaxEobTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :payers, :clients, 
    :insurance_payment_eobs, :facility_output_configs
  
  include OperationLogCsv
  
  def setup
    check1 = check_informations(:check_information6)
    check2 = check_informations(:check_information7)
    check3 = check_informations(:check_information8)
    check4 = check_informations(:check_information9)
    check5 = check_informations(:check_information10)
    check6 = check_informations(:check_information11)
    eob1 = insurance_payment_eobs(:ins_pay_eob_9)
    eob2 = insurance_payment_eobs(:ins_pay_eob_10)
    eob3 = insurance_payment_eobs(:ins_pay_eob_11)
    eob4 = insurance_payment_eobs(:ins_pay_eob_12)
    eob5 = insurance_payment_eobs(:ins_pay_eob_13)
    eob6 = insurance_payment_eobs(:ins_pay_eob_14)
    eob7 = insurance_payment_eobs(:ins_pay_eob_15)
    facility1 = facilities(:facility_quadax)
    facility2 = facilities(:facility_23)
    @quadax_eob1 = QuadaxEob.new(eob1, check1, facility1, 0, 'csv')
    @quadax_eob2 = QuadaxEob.new(eob2, check1, facility1, 0, 'csv')
    @quadax_eob3 = QuadaxEob.new(eob3, check2, facility1, 0, 'csv')
    @quadax_eob4 = QuadaxEob.new(eob4, check3, facility1, 0, 'csv')
    @quadax_eob5 = QuadaxEob.new(eob5, check4, facility2, 0, 'csv')
    @quadax_eob6 = QuadaxEob.new(eob6, check5, facility2, 0, 'csv')
    @quadax_eob7 = QuadaxEob.new(eob7, check6, facility2, 0, 'csv')
  end

  def test_reject_reason
    insurance_pay = insurance_payment_eobs(:ins_pay_eob_3)
    check = check_informations(:check_information_4)
    eob = QuadaxEob.new(insurance_pay, check, facilities(:facility_2), 1, 'xls')
    facility_output_config = facility_output_configs(:facility_output_config_op_log)
    eob.expects(:operation_log_config).returns(facility_output_config)
    reject_reason = eob.reject_reason
    assert_not_nil reject_reason
    assert_equal 'Rejection Comment', reject_reason
  end

  def test_blank_reject_reason
    insurance_pay = insurance_payment_eobs(:ins_pay_eob_4)
    check = check_informations(:check_information_4)
    eob = QuadaxEob.new(insurance_pay, check, facilities(:facility_2), 1, 'xls')
    facility_output_config = facility_output_configs(:facility_output_config_op_log)
    eob.expects(:operation_log_config).returns(facility_output_config)
    reject_reason = eob.reject_reason
    assert_equal '-', reject_reason
  end
  
  #  def test_statement_number_quadax_patpay_checks
  #    assert_equal("111", @quadax_eob1.statement_number)
  #  end
  #
  #  def test_statement_number_nil_quadax_patpay_checks
  #    assert_equal("-", @quadax_eob2.statement_number)
  #  end
  #
  #  def test_statement_number_quadax_non_patpay_checks
  #    assert_equal("-", @quadax_eob3.statement_number)
  #  end
  #
  #  def test_statement_number_quadax_payer_nil
  #    assert_equal("-", @quadax_eob4.statement_number)
  #  end
  #
  #  def test_statement_number_non_quadax_non_patpay_checks
  #    assert_equal("-", @quadax_eob5.statement_number)
  #  end
  #
  #  def test_statement_number_non_quadax_patpay_checks
  #    assert_equal("-", @quadax_eob6.statement_number)
  #  end
  #
  #  def test_statement_number_non_quadax_payer_nil
  #    assert_equal("-", @quadax_eob7.statement_number)
  #  end

end
