#This class test the IndexedImageFile::Check
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__)+'/../../lib/indexed_image_file/check'
require File.dirname(__FILE__)+'/../../lib/indexed_image_file'

class IndexedImageFile::IndexedImageFileCheckTest < ActiveSupport::TestCase
  fixtures :clients, :facilities, :batches, :jobs, :check_informations, :payers,
    :micr_line_informations, :facility_output_configs, :facilities_micr_informations,
    :insurance_payment_eobs
  
  def setup
    @check_with_no_payer_and_no_micr = IndexedImageFile::Check.new(check_informations(:check_50), 0, insurance_payment_eobs(:ins_pay_eob__for_pm_facility_50))
    @check_with_payer_and_no_micr = IndexedImageFile::Check.new(check_informations(:check_47), 0, insurance_payment_eobs(:ins_pay_eob_for_gcbs_49))
    @check_with_no_payer_and_micr_with_payer_having_onbase_name = IndexedImageFile::Check.new(check_informations(:check_51), 0, insurance_payment_eobs(:ins_pay_eob__for_pm_facility_50))
    @check_with_no_payer_and_micr_with_payer_not_having_onbase_name = IndexedImageFile::Check.new(check_informations(:check_49), 0, insurance_payment_eobs(:ins_pay_eob_for_gcbs_49))
    @check_with_payer_and_micr_with_payer_having_onbase_name = IndexedImageFile::Check.new(check_informations(:check_having_micr_associated_to_insurance_payer_59), 0, insurance_payment_eobs(:insurance_eob_with_svc_lines_without_interest))
    @check_with_payer_and_micr_with_payer_not_having_onbase_name = IndexedImageFile::Check.new(check_informations(:check_having_micr_associated_to_patpay_payer_58), 0, insurance_payment_eobs(:eob_58))
  end

  #check_with_no_payer_and_no_micr - Result : Others
  def test_insurance_type_of_check_with_no_payer_and_no_micr
    assert_equal("\"Others\"", @check_with_no_payer_and_no_micr.insurance_type)
  end

  #check_with_payer_and_no_micr - Result : Others
  def test_insurance_type_of_check_with_payer_and_no_micr
    assert_equal("\"Others\"", @check_with_payer_and_no_micr.insurance_type)
  end

  #check_with_no_payer_and_micr_with_payer_having_onbase_name - Result : Payer name
  def test_insurance_type_of_check_with_no_payer_and_micr_with_payer_having_onbase_name
    assert_equal("\"APRIYA\"", @check_with_no_payer_and_micr_with_payer_having_onbase_name.insurance_type)
  end

  #check_with_no_payer_and_micr_with_payer_not_having_onbase_name - Result : "Others"
  def test_insurance_type_of_check_with_no_payer_and_micr_with_payer_not_having_onbase_name
    assert_equal("\"Others\"", @check_with_no_payer_and_micr_with_payer_not_having_onbase_name.insurance_type)
  end

  #check_with_payer_and_micr_with_payer_having_onbase_name - Result : Payer name
  def test_insurance_type_of_check_with_payer_and_micr_with_payer_having_onbase_name
    assert_equal("\"APRIYA\"", @check_with_payer_and_micr_with_payer_having_onbase_name.insurance_type)
  end

  #check_with_payer_and_micr_with_payer_not_having_onbase_name - Result : "Others"
  def test_insurance_type_of_check_with_payer_and_micr_with_payer_not_having_onbase_name
    assert_equal("\"Others\"", @check_with_payer_and_micr_with_payer_not_having_onbase_name.insurance_type)
  end

end

