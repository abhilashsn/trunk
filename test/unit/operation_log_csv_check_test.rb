#This class test the OperationLogCsv::Check
require File.dirname(__FILE__) + '/../test_helper'

class OperationLogCsv::OperationLogCsvCheckTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :payers, :clients, :micr_line_informations, :facility_output_configs
  def setup
    @check_1 = OperationLogCsv::Check.new(check_informations(:check_10),facilities(:facility_1), 0, "csv")
    @check_2 = OperationLogCsv::Check.new(check_informations(:check_11),facilities(:facility_1), 0, "csv")
    @check_3 = OperationLogCsv::Check.new(check_informations(:check_12),facilities(:facility_1), 0, "csv")
    @check_4 = OperationLogCsv::Check.new(check_informations(:check_13),facilities(:facility_1), 0, "csv")
    @check_5 = OperationLogCsv::Check.new(check_informations(:check_14),facilities(:facility_1), 0, "csv")
  end

  def test_payer_name_quadax_patpay_checks
    assert_equal(nil, @check_1.payer_name)
  end

  def test_payer_name_quadax_non_payer_checks
    assert_equal(nil, @check_2.payer_name)
  end

  def test_payer_name_non_quadax__patpay_checks
    assert_equal(nil, @check_3.payer_name)
  end

  def test_payer_name_non_quadax_non_patpay_checks
    assert_equal(nil, @check_4.payer_name)
  end

  def test_payer_name_nil
    assert_equal(nil, @check_5.payer_name)
  end


end
