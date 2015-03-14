require File.dirname(__FILE__) + '/../test_helper'

class ReasonCodesClientsFacilitiesSetNameTest < ActiveSupport::TestCase

  fixtures :reason_codes, :ansi_remark_codes, :payers,
    :reason_codes_clients_facilities_set_names, :reason_codes_ansi_remark_codes,
    :hipaa_codes, :client_codes, :facilities, :clients, :service_payment_eobs,
    :default_codes_for_adjustment_reasons,
    :reason_codes_clients_facilities_set_names_client_codes, :reason_code_set_names

  def setup
    @svc_line_1 = service_payment_eobs(:svc_1)
    @svc_line_with_reason_code = service_payment_eobs(:svc_with_reason_codes)
    @reason_code_mapping = ReasonCodesClientsFacilitiesSetName.new
  end

  def test_hipaa_code
    assert_equal nil,reason_codes_clients_facilities_set_names(:unassociated_client_facility_payer_reason_cd).hipaa_code
  end

  def test_client_code
    assert_equal nil,reason_code_client_facility_payer.client_code
  end

  def test_return_reason_code
    assert_equal reason_codes_clients_facilities_set_names(:mapping_reason_codes_1).reason_code_id,reason_code_client_facility_payer.reason_code.id
  end

  private
  
  def reason_code_client_facility_payer
    reason_codes_clients_facilities_set_names(:mapping_reason_codes_1)
  end
  
end
