require File.dirname(__FILE__)+'/../test_helper'

class OutputEobTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :insurance_payment_eobs, 
    :payers , :facility_output_configs, :images_for_jobs, :image_types
  
  def setup
    @eob = Output835::OutputEob.new(insurance_payment_eobs(:ins_pay_eob_17), facilities(:facility_3), payers(:payer7),1, '*')
    @facility = facilities(:facility_3)
    @fac_config = facility_output_configs(:facility_output_config_9)
    @ins_eob = insurance_payment_eobs(:ins_pay_eob_17)
    @nm182 = "NM1*82*1*#{@ins_eob.rendering_provider_last_name.upcase}*#{@ins_eob.rendering_provider_first_name.upcase}*#{@ins_eob.rendering_provider_middle_initial.upcase}**#{@ins_eob.rendering_provider_suffix.upcase}*PC*#{@ins_eob.patient_first_name.upcase}"
  end
  
  include AdjustmentReason

  def test_parse_output_configurations
    assert_equal(@nm182, @eob.parse_output_configurations(:nm182_segment))
  end
  
  def test_make_segment_array
    nm1 =  ["NM1","82", "1", "[Provider Last Name]", "[Provider First Name]", "[Provider Middle Initial]","", "[Provider Suffix]", "PC","#{@fac_config.details[:nm182_segment]['9']}"]
    assert_equal(nm1, @eob.make_segment_array(@fac_config.details[:nm182_segment].convert_keys,:nm182_segment) )
  end

  def test_service_prov_name
    assert_equal(@nm182, @eob.service_prov_name)
  end

  def test_claim_supplemental_info
    assert_equal("AMT*I*#{@ins_eob.amount('claim_interest').to_s.to_dollar}", @eob.claim_supplemental_info)
  end

  def test_image_page_name_bac
    assert_equal("REF*F8*#{images_for_jobs(:image12).filename}", @eob.image_page_name_bac)
  end

  def test_insured_name
    assert_equal("NM1*IL*1*#{@ins_eob.subscriber_last_name}*#{@ins_eob.
      subscriber_first_name}*#{@ins_eob.subscriber_middle_initial}**#{@ins_eob.\
      subscriber_suffix}*MI", @eob.insured_name)
  end

  def test_claim_interest_information_bac
    assert_equal("CAS*1*2*#{@ins_eob.amount('claim_interest').to_s.to_dollar}*4",@eob.claim_interest_information_bac)
  end

  def test_reference_id_bac
    assert_equal("REF*CK*#{@facility.facility_tin}", @eob.reference_id_bac)
  end

  def test_service_prov_identifier_bac
    nm1pr = @fac_config.details[:nm1pr_segment]
    assert_equal("NM1*#{nm1pr['1']}*#{nm1pr['2']}******#{nm1pr['8']}*#{@ins_eob.rendering_provider_identification_number}", @eob.service_prov_identifier_bac)
  end

  def test_claim_level_allowed_amount_bac
    assert_equal("AMT*AU*#{@ins_eob.sum('service_allowable').to_s.to_dollar}", @eob.claim_level_allowed_amount_bac)
  end

  def test_claim_to_date
    @eob.instance_variable_set('@eob',insurance_payment_eobs(:ins_pay_eob_46))
    assert_nil(@eob.claim_to_date)
  end

  def test_payer_reason_codes_for_nyu
    @eob.instance_variable_set('@eob', insurance_payment_eobs(:ins_pay_eob_47))
    @eob.instance_variable_set('@facility', facilities(:facility_209))
    assert_equal({0 => 'REF'}, @eob.payer_reason_codes_for_nyu)
    @eob.instance_variable_set('@facility', facilities(:facility_210))
    assert_nil(@eob.payer_reason_codes_for_nyu)
  end
  
end