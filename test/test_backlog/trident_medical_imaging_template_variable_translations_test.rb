require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/output_xml/templates/trident_medical_imaging_template_variable_translations'
require File.dirname(__FILE__)+'/../../lib/output_xml'
class OutputXml::TridentMedicalImagingTemplateVariableTranslationsTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :payers, :insurance_payment_eobs,
    :service_payment_eobs, :check_informations,
    :reason_codes_clients_facilities_set_names, :reason_codes,
    :reason_codes_clients_facilities_set_names_hipaa_codes, :hipaa_codes
  
  def setup
    @service = service_payment_eobs(:one)
    @reason_code = get_reason_code(@service,'noncovered')
    @check = check_informations(:check_7)
  end
  
  include OutputXml::TridentMedicalImagingTemplateVariableTranslations

  def ntest_get_reason_code
    @reason_code = get_reason_code(@service,'noncovered')
    assert_equal(380 , @reason_code.reason_code_id)
  end
   
  def ntest_adjustment_reason_code
    assert_equal("1",adjustment_reason_code(@reason_code))
  end

  def test_payer_tax_id
    assert_equal(facilities(:facility_3).default_patpay_payer_tin, payer_tax_id(@check))
  end
end