require File.dirname(__FILE__)+'/../test_helper'
require 'application_controller'
require 'mocha/setup'

class ApplicationControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :roles, :roles_users, :clients,
    :jobs , :check_informations, :batches, :facilities,
    :insurance_payment_eobs, :payers, :service_payment_eobs, :reason_code_set_names,
    :insurance_payment_eobs_reason_codes, :service_payment_eobs_reason_codes,
    :reason_codes, :reason_codes_jobs, :balance_record_configs, :ansi_remark_codes, :service_payment_eobs_ansi_remark_codes
  def setup
    @controller = ApplicationController.new
  end
#Correspondence check amount - (total_paid+fund+interest+LF)
  def test_get_job_level_balance_correspondence_check_case_one
    assert_equal(-13, @controller.get_job_level_balance(check_informations(:correspondence_check_with_eob_with_svc_missing_check_89), jobs(:job_86)))
  end

  #Correspondence check amount - (total_paid+fund+interest)
  def test_get_job_level_balance_correspondence_check_case_two
    assert_equal(0, @controller.get_job_level_balance(check_informations(:correspondence_check_with_eob_without_svc__for_correspondence_82), jobs(:job_83)))
  end

  #Correspondence check amount - (total_paid)
  def test_get_job_level_balance_correspondence_check_case_three
    assert_equal(0, @controller.get_job_level_balance(check_informations(:correspondence_check_with_eob_with_svc_complete_eob_88), jobs(:job_85)))
  end

  #Payment check amount - (total_paid+fund+interest+LF)
  def test_get_job_level_balance_payment_check_case_one
    assert_equal(100, @controller.get_job_level_balance(check_informations(:payment_check_with_eob_without_svc_check_only_90), jobs(:job_87)))
  end

  #Correspondence check amount - (total_paid+fund)+provider_adj
  def test_get_job_level_balance_payment_check_case_two
    assert_equal(0, @controller.get_job_level_balance(check_informations(:payment_check_with_eob_with_svc_complete_eob_85), jobs(:job_84)))
  end
  
 private 
  def test_format_date
    assert_equal(nil, @controller.format_date(nil))
    assert_equal(nil, @controller.format_date(""))
    assert_equal("12/01/2011", @controller.format_date("12/01/11"))
    assert_equal(nil, @controller.format_date("mm/dd/yy"))
  end
end