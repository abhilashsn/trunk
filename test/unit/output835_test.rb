require File.dirname(__FILE__)+'/../test_helper'


class Output835Test < ActiveSupport::TestCase
 
  fixtures :clients, :facilities, :batches, :check_informations,
    :payers, :reason_code_set_names, :reason_codes, :reason_codes_clients_facilities_set_names,
    :hipaa_codes, :ansi_remark_codes, :reason_codes_ansi_remark_codes,
    :service_payment_eobs, :service_payment_eobs_ansi_remark_codes,
    :service_payment_eobs_reason_codes, :insurance_payment_eobs,
    :insurance_payment_eobs_reason_codes, :insurance_payment_eobs_ansi_remark_codes,
    :reason_codes_clients_facilities_set_names_client_codes, :client_codes

  def setup
    @array = [1,"quadax"," pathology ",678.90,"horizon   ","","","",nil,nil,""]
    @svc_line = service_payment_eobs(:svc_with_reason_codes)
    @facility_with_remark_code = facilities(:facility_with_remark_code)
  end
  
  def test_trim_segment
    assert_equal(Output835.trim_segment(@array), [1,"quadax","pathology",678.90,"horizon"]) 
  end

  def test_group_code_as_cas_01_element_for_crosswalk
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:cas_01] = 'PR'

    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)

    amount, cas_01_code, cas_02_code, parameters = Output835.cas_elements(parameters)
    assert_equal 'PR', cas_01_code
  end

  def test_client_code_as_cas_01_element_for_crosswalk
    facility = facilities(:facility_with_rcc_crosswalk_and_client_code_as_cas01)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:cas_01] = 'CC1'
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    amount, cas_01_code, cas_02_code, parameters = Output835.cas_elements(parameters)
    assert_equal 'CC1', cas_01_code
  end

  def test_hipaa_code_as_cas_02_element_for_crosswalk
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:cas_02] = 'H1'
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    amount, cas_01_code, cas_02_code, parameters = Output835.cas_elements(parameters)
    assert_equal 'H1', cas_02_code
  end

  def test_client_code_as_cas_02_element_for_crosswalk
    facility = facilities(:facility_with_rcc_crosswalk_and_client_code_as_cas02)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:cas_02] = 'CC1'
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    amount, cas_01_code, cas_02_code, parameters = Output835.cas_elements(parameters)
    assert_equal 'CC1', cas_02_code
  end

  def do_not_test_group_code_as_default_cas_01_element_for_crosswalk
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'copay'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    Output835.expects(:log).at_least_once.returns(Logger.new("log/test.log"))
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    Output835.expects(:cas_02_element).at_least_once.returns(true)
    amount, cas_01_code, cas_02_code, parameters = Output835.cas_elements(parameters)
    assert_equal 'PR', cas_01_code
  end

  def test_cas_elements_for_no_crosswalk   
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    crosswalked_codes[:reason_code] = 'R1'
    crosswalked_codes[:cas_02] = 'R1'
    crosswalked_codes[:cas_01] = 'PR'
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    amount, cas_01_code, cas_02_code, parameters = Output835.cas_elements(parameters)
    assert_equal 'PR', cas_01_code
    assert_equal 'R1', cas_02_code
  end

  def do_not_test_client_code_in_standard_industry_code_segments
    client = clients(:hlsc)
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping_and_global_mapping)
    entity = @svc_line
    payer = payers(:payer17)
    element_seperator = '*'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    reason_code_crosswalk.instance_variable_set("@is_partner_bac", true)    
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    industry_code = Output835.standard_industry_code_segments(entity, client, facility, payer, element_seperator)
    assert_not_nil industry_code
    assert_equal ["LQ*HE*RC1", "LQ*HE*CC1", "LQ*HE*RC2", "LQ*HE*RC3",
      "LQ*HE*RC4", "LQ*HE*RC5", "LQ*HE*RC6", "LQ*HE*RC7", "LQ*HE*RC8"], industry_code
  end

  def do_not_test_reason_code_and_client_code_in_standard_industry_code_segments
    client = clients(:hlsc)
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping_and_global_mapping)
    entity = @svc_line
    payer = payers(:payer17)
    cas_02_elements = ['H1', 'AB']
    element_seperator = '*'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    crosswalked_codes[:all_reason_codes] = [["RC1", "DESC RC1", false], ["RC2", "DESC RC2", false], ["RC3", "DESC RC3", false]]
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    reason_code_crosswalk.instance_variable_set("@is_partner_bac", true)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    industry_code = Output835.standard_industry_code_segments(entity, client, facility, payer, element_seperator)
    assert_not_nil industry_code
    assert_equal ["LQ*HE*RC1", "LQ*HE*RC2", "LQ*HE*RC3", "LQ*HE*RC4",
      "LQ*HE*RC5", "LQ*HE*RC6", "LQ*HE*RC7", "LQ*HE*RC8", "LQ*HE*CC1"], industry_code
  end

  def test_printing_lqhe_code_if_it_is_not_same_as_cas_02
    client = clients(:hlsc)
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    payer = payers(:payer17)
    entity = @svc_line
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:all_reason_codes] = [["RC1", "DESC RC1", false], ["RC2", "DESC RC2", false], ["RC3", "DESC RC3", false]]
    rcc = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    rcc.instance_variable_set("@reason_codes", reason_codes)
    rcc.instance_variable_set("@adjustment_reason", 'coinsurance')
    rcc.instance_variable_set("@zero_payment", false)
    Output835.instance_variable_set("@reason_code_crosswalk", rcc)
    rcc.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    lqhe_code = Output835.standard_industry_code_segments(entity, client, facility, payer, '*')
    assert_not_nil lqhe_code
    #assert_equal ["LQ*HE*RC1", "LQ*HE*RC2", "LQ*HE*RC3", "LQ*HE*RC4","LQ*HE*RC5", "LQ*HE*RC6", "LQ*HE*RC7", "LQ*HE*RC8"], lqhe_code
  end
  
  def test_not_printing_lqhe_code_if_it_is_same_as_cas_02
    client = clients(:hlsc)
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    payer = payers(:payer17)
    entity = @svc_line
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'RC1'
    crosswalked_codes[:group_code] = 'PR'
    crosswalked_codes[:all_reason_codes] = [["RC1", "DESC RC1", false], ["RC2", "DESC RC2", false], ["RC3", "DESC RC3", false]]
    rcc = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    rcc.instance_variable_set("@reason_codes", reason_codes)
    rcc.instance_variable_set("@adjustment_reason", 'coinsurance')
    rcc.instance_variable_set("@zero_payment", false)
    Output835.instance_variable_set("@reason_code_crosswalk", rcc)
    rcc.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    lqhe_code = Output835.standard_industry_code_segments(entity, client, facility, payer, '*')
    assert_not_nil lqhe_code
    #assert_equal ["LQ*HE*RC2", "LQ*HE*RC3", "LQ*HE*RC4", "LQ*HE*RC5","LQ*HE*RC6", "LQ*HE*RC7", "LQ*HE*RC8"], lqhe_code
  end

  def test_cas_01_element_for_no_crosswalked_code
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    crosswalked_codes[:cas_01] = 'G1'
    Partner.expects(:is_partner_bac?).returns(true)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).returns(crosswalked_codes)
    cas_01_code, parameters = Output835.cas_01_element(crosswalked_codes)
    assert_equal 'G1', cas_01_code
  end

  def test_cas_02_element_for_no_crosswalked_code_if_crosswalked_code_exists
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    crosswalked_codes[:cas_02] = 'R1'
    crosswalked_codes[:reason_code] = 'R1'
    Partner.expects(:is_partner_bac?).at_least_once.returns(false)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    reason_code_crosswalk.instance_variable_set("@is_partner_bac", false)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    cas_02_code, parameters = Output835.cas_02_element(parameters, crosswalked_codes)
    assert_equal 'R1', cas_02_code
  end

  def test_cas_02_element_for_no_crosswalked_code_if_crosswalked_code_do_not_exists
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    crosswalked_codes[:cas_02] = 'RC1'
    crosswalked_codes[:reason_code] = ''
    crosswalked_codes[:all_reason_codes] = [['RC1', 'RC1 DESC', false], ['RC2', 'RC2 DESC', false]]
    Partner.expects(:is_partner_bac?).at_least_once.returns(false)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@is_partner_bac", false)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    cas_02_code, parameters = Output835.cas_02_element(parameters, crosswalked_codes)
    assert_equal 'RC1', cas_02_code
  end

  def test_cas_02_element_for_no_crosswalked_code_for_bac
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = 'hipaa_code'
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = '999'
    crosswalked_codes[:cas_02] = '999'
    crosswalked_codes[:reason_code] = ''
    crosswalked_codes[:all_reason_codes] = [['RC1', 'RC1 DESC', false], ['RC2', 'RC2 DESC', false]]
    Partner.expects(:is_partner_bac?).at_least_once.returns(true)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@is_partner_bac", true)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).at_least_once.returns(crosswalked_codes)
    cas_02_code, parameters = Output835.cas_02_element(parameters, crosswalked_codes)
    assert_equal '999', cas_02_code
  end

  def test_remark_codes_in_get_industry_codes
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = 'hipaa_code'
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = '999'
    crosswalked_codes[:remark_codes] = ['RM1', 'RM2']
    crosswalked_codes[:reason_code] = ''
    crosswalked_codes[:all_reason_codes] = [['RC1', 'RC1 DESC', false], ['RC2', 'RC2 DESC', false]]
    Partner.expects(:is_partner_bac?).at_least_once.returns(true)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@is_partner_bac", true)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_industry_codes).at_least_once.returns(crosswalked_codes)
    lqhe_codes = Output835.get_industry_codes(@svc_line, 'remark_code', crosswalked_codes)
    assert_equal ['RM1', 'RM2'], lqhe_codes
  end

  def test_client_codes_in_get_industry_codes
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = 'hipaa_code'
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = '999'
    crosswalked_codes[:remark_codes] = ['RM1', 'RM2']
    crosswalked_codes[:reason_code] = ''
    crosswalked_codes[:all_reason_codes] = [['RC1', 'RC1 DESC', false], ['RC2', 'RC2 DESC', false]]
    Partner.expects(:is_partner_bac?).at_least_once.returns(true)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@is_partner_bac", true)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_industry_codes).at_least_once.returns(crosswalked_codes)
    lqhe_codes = Output835.get_industry_codes(@svc_line, 'client_code', crosswalked_codes)
    assert_equal ['CC1'], lqhe_codes
  end

  def test_cas_01_element_for_crosswalked_code
    facility = facilities(:facility_with_no_rcc_crosswalk)
    parameters = {}
    parameters[:entity] = @svc_line
    parameters[:facility] = facility
    parameters[:payer] = payers(:payer17)
    parameters[:cas_01_config] = facility.details[:cas_01].to_s.downcase.gsub(' ', '_')
    parameters[:cas_02_config] = facility.details[:cas_02].to_s.downcase.gsub(' ', '_')
    parameters[:adjustment_reason] = 'coinsurance'
    crosswalked_codes = {}
    crosswalked_codes[:hipaa_code] = 'H1'
    crosswalked_codes[:group_code] = 'G1'
    crosswalked_codes[:client_code] = 'CC1'
    crosswalked_codes[:default_code] = 'MAP'
    crosswalked_codes[:cas_01] = 'PI'
    Partner.expects(:is_partner_bac?).returns(false)
    reason_code_crosswalk = ReasonCodeCrosswalk.new(payers(:payer17), @svc_line, facility.client, facility)
    Output835.instance_variable_set("@reason_code_crosswalk", reason_code_crosswalk)
    reason_code_crosswalk.expects(:get_crosswalked_codes_for_adjustment_reason).returns(crosswalked_codes)
    cas_01_code, parameters = Output835.cas_01_element(crosswalked_codes)
    assert_equal 'PI', cas_01_code
  end

  # test invoking non-existent method
  def ntest_output_generator_group
    assert_equal("SHEPHERD EYE SURGICENTER", Output835.output_generator_group(facilities(:facility_211)))
    assert_equal(facilities(:facility_24).name, Output835.output_generator_group(facilities(:facility_24)))
  end

  def test_get_pr_cas_elements_for_pr_adjustment_reason
    adjustment_reason = 'copay'
    cas_element = ['PR', '45', 11]
    observed_cas_pr_element = Output835.get_pr_cas_elements(adjustment_reason, cas_element)
    assert_equal ['PR', '45', 11.to_s.to_dollar], observed_cas_pr_element
  end
  
  def test_get_pr_cas_elements_for_non_pr_adjustment_reason
    adjustment_reason = 'noncovered'
    cas_element = ['OA', '45', 11]
    observed_cas_pr_element = Output835.get_pr_cas_elements(adjustment_reason, cas_element)
    assert_equal nil, observed_cas_pr_element
  end

  def test_group_cas_elements_with_same_cas_01_and_cas_02
    cas_elements = [['HR', '47', 5], ['HR', '45', 10], ['OA', '45', 10],  ['HR', '45', 20],
      ['HR', '45', 30], ['HR', '46', 30]]
    obtained_grouped_cas_elements = Output835.group_cas_elements_with_same_cas_01_and_cas_02(cas_elements)
    expected_grouped_cas_elements = {
      'HR' => {
        '45' => [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30]],
        '46' => [['HR', '46', 30]],
        '47' => [['HR', '47', 5]],
      },
      'OA' => {
        '45' => [['OA', '45', 10]]
      }
    }
    assert_equal expected_grouped_cas_elements, obtained_grouped_cas_elements
  end

  def test_normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02
    grouped_cas_elements = {
      'HR' => {
        '45' => [['HR', '45', 10], ['HR', '45', 20], ['HR', '45', 30]],
        '46' => [['HR', '46', 30]],
        '47' => [['HR', '47', 5], ['HR', '47', 3]],
      },
      'OA' => {
        '45' => [['OA', '45', 10]]
      }
    }
    expected_grouped_summed_up_elements = {
      'HR' => {
        '45' => [['HR', '45', 60.0]],
        '46' => [['HR', '46', 30.0]],
        '47' => [['HR', '47', 8.0]],
      },
      'OA' => {
        '45' => [['OA', '45', 10.0]]
      }
    }
    obtained_grouped_summed_up_elements = Output835.normalize_cas_segment_by_summing_up_amount_for_same_cas01_and_cas02(grouped_cas_elements)
    assert_equal expected_grouped_summed_up_elements, obtained_grouped_summed_up_elements
  end

  def test_normalize_cas_segment_for_same_cas01_and_different_cas02
    element_seperator = '*'
    grouped_elements = {
      'HR' => {
        '45' => [['HR', '45', 60.0]],
        '46' => [['HR', '46', 30.0]],
        '47' => [['HR', '47', 8.0]],
      },
      'OA' => {
        '45' => [['OA', '45', 10.0]]
      }
    }
    expected_grouped_elements = {
      'HR' => {},
      'OA' => {
        '45' => [['OA', '45', 10.0]]
      }
    }
    expected_cas_segments = [["CAS*HR*45*60.00**46*30.00**47*8.00"]]
    obtained_grouped_elements, obtained_cas_segments  = Output835.normalize_cas_segment_for_same_cas01_and_different_cas02(grouped_elements, element_seperator)
    assert_equal expected_grouped_elements, obtained_grouped_elements
    assert_equal expected_cas_segments, obtained_cas_segments
  end

  def test_normalize_cas_segment_for_different_cas01_and_cas02
    element_seperator = '*'
    grouped_elements = {
      'HR' => {},
      'OA' => {
        '45' => [['OA', '45', 10.0]]
      }
    }
    expected_cas_segments = ["CAS*OA*45*10.00"]
    obtained_cas_segments  = Output835.normalize_cas_segment_for_different_cas01_and_cas02(grouped_elements, element_seperator)
    assert_equal expected_cas_segments, obtained_cas_segments
  end

  def test_expanded_cas_segment
    elements = [[['PR', 'H1', 1], ['PR', 'H2', 2], ['PR', 'H3', 3]]]
    element_seperator = '*'
    expanded_cas_segment = Output835.expanded_cas_segment(elements, element_seperator)
    assert_equal ['CAS*PR*H1*1.00**H2*2.00**H3*3.00'], expanded_cas_segment
  end

  def test_cas_with_minimum_elements
    amount = 1
    cas_01_code = 'G1'
    cas_02_code = 'H1'
    elements = [cas_01_code, cas_02_code, amount]
    element_seperator = '*'
    cas_with_minimum_elements = Output835.cas_with_minimum_elements(elements, element_seperator)
    assert_equal 'CAS*G1*H1*1.00', cas_with_minimum_elements
  end

  def test_cas_with_minimum_elements_when_amount_is_missing
    amount = nil
    cas_01_code = 'G1'
    cas_02_code = 'H1'
    elements = [cas_01_code, cas_02_code, amount]
    element_seperator = '*'
    cas_element_when_amount_is_missing = Output835.cas_with_minimum_elements(elements, element_seperator)
    assert_equal nil, cas_element_when_amount_is_missing
  end

  def test_cas_with_minimum_elements_when_cas01_is_missing
    amount = 1
    cas_01_code = ''
    cas_02_code = 'H1'
    elements = [cas_01_code, cas_02_code, amount]
    element_seperator = '*'
    cas_element_when_cas01_is_missing = Output835.cas_with_minimum_elements(elements, element_seperator)
    assert_equal nil, cas_element_when_cas01_is_missing
  end

  def test_cas_with_minimum_elements_when_cas02_is_missing
    amount = 1
    cas_01_code = 'G1'
    cas_02_code = ''
    elements = [cas_01_code, cas_02_code, amount]
    element_seperator = '*'
    cas_element_when_cas02_is_missing = Output835.cas_with_minimum_elements(elements, element_seperator)
    assert_equal nil, cas_element_when_cas02_is_missing
  end

  def test_cas_with_maximum_elements
    cas_01_code = 'PR'
    cas_02_and_03_elements = [['H1', '1.00'], ['H2', '2.00'], ['H3', '3.00']]
    element_seperator = '*'
    expected_cas_segments = ['CAS*PR*H1*1.00**H2*2.00**H3*3.00']
    observed_cas_segments = Output835.cas_with_maximum_elements(cas_01_code, cas_02_and_03_elements, element_seperator)
    assert_equal expected_cas_segments, observed_cas_segments
  end
  
  def test_separate_cas_segments_with_no_pr_elements
    cas_elements = [['HR', '45', 10], ['OA', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '46', 30], ['HR', '47', 30]]

    observed_cas_segments = Output835.separate_cas_segments(cas_elements, nil, '*')
    expected_observed_cas_segments = ["CAS*HR*45*60.00", "CAS*HR*46*30.00",
      "CAS*HR*47*30.00", "CAS*OA*45*10.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_separate_cas_segments_with_pr_elements_with_different_cas02_codes
    cas_elements = [['HR', '45', 10], ['OA', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '46', 30], ['HR', '47', 30]
    ]
    pr_elements = [['PR', '11', 5], ['PR', '22', 3], ['PR', '33', 20]]
    observed_cas_segments = Output835.separate_cas_segments(cas_elements, pr_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*60.00", "CAS*HR*46*30.00",
      "CAS*HR*47*30.00", "CAS*OA*45*10.00", "CAS*PR*11*5.00**22*3.00**33*20.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_separate_cas_segments_with_pr_elements_with_same_cas02_codes
    cas_elements = [['HR', '45', 10], ['OA', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30],
      ['HR', '46', 30], ['HR', '47', 30]
    ]
    pr_elements = [['PR', '11', 5], ['PR', '11', 3], ['PR', '11', 20]]
    observed_cas_segments = Output835.separate_cas_segments(cas_elements, pr_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*60.00", "CAS*HR*46*30.00",
      "CAS*HR*47*30.00", "CAS*OA*45*10.00", "CAS*PR*11*28.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_separate_cas_segments_for_all_elements_with_same_cas01_and_cas02
    cas_elements = [['HR', '45', 10], ['HR', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '45', 30]
    ]
    pr_elements = [['HR', '45', 5], ['HR', '45', 3], ['HR', '45', 20]]
    observed_cas_segments = Output835.separate_cas_segments(cas_elements, pr_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*128.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_separate_cas_segments_for_all_elements_with_same_cas01_and_different_cas02
    cas_elements = [['HR', '45', 10], ['HR', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '45', 30]
    ]
    pr_elements = [['HR', '46', 5], ['HR', '46', 3], ['HR', '46', 20]]
    observed_cas_segments = Output835.separate_cas_segments(cas_elements, pr_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*100.00", "CAS*HR*46*28.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combine_pr_and_non_pr_segments_for_all_elements_with_same_cas01_and_cas02
    cas_elements = [['HR', '45', 10], ['HR', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '45', 30]
    ]
    non_pr_segment = ["CAS*HR*45*100.00"]
    pr_elements = [['HR', '45', 5], ['HR', '45', 3], ['HR', '45', 20]]
    pr_segment = ["CAS*HR*45*28.00"]
    observed_cas_segments = Output835.combine_pr_and_non_pr_segments(non_pr_segment, pr_segment, '*')
    expected_observed_cas_segments = "CAS*HR*45*128.00"
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combine_pr_and_non_pr_segments_for_all_elements_with_same_cas01_and_different_cas02
    cas_elements = [['HR', '45', 10], ['HR', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '45', 30]
    ]
    pr_elements = [['HR', '46', 5], ['HR', '46', 3], ['HR', '46', 20]]
    observed_cas_segments = Output835.combine_pr_and_non_pr_segments(cas_elements, pr_elements, '*')
    expected_observed_cas_segments = nil
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combined_with_no_pr_elements
    cas_elements = [['HR', '45', 10], ['OA', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '46', 30],
      ['HR', '47', 30], ['CO', '45', 10], ['CO', '45', 20], ['CO', '45', 10]]

    pr_elements = []
    cas_elements = cas_elements + pr_elements
    observed_cas_segments = Output835.combined_cas_segments(cas_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*60.00**46*30.00**47*30.00",
      "CAS*OA*45*10.00", "CAS*CO*45*40.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combined_with_pr_elements_with_different_cas02_codes
    cas_elements = [['HR', '45', 10], ['OA', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '46', 30], ['HR', '47', 30]      
    ]
    pr_elements = [['PR', '11', 5], ['PR', '22', 3], ['PR', '33', 20]]
    cas_elements = cas_elements + pr_elements
    observed_cas_segments = Output835.combined_cas_segments(cas_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*60.00**46*30.00**47*30.00",
      "CAS*PR*11*5.00**22*3.00**33*20.00", "CAS*OA*45*10.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combined_with_pr_elements_with_same_cas02_codes
    cas_elements = [['HR', '45', 10], ['OA', '45', 10],
      ['HR', '45', 20], ['HR', '45', 30],
      ['HR', '46', 30], ['HR', '47', 30], 
    ]
    pr_elements = [['PR', '11', 20], ['PR', '11', 3], ['PR', '11', 5]]
    cas_elements = cas_elements + pr_elements
    observed_cas_segments = Output835.combined_cas_segments(cas_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*60.00**46*30.00**47*30.00",
      "CAS*OA*45*10.00", "CAS*PR*11*28.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combined_for_all_elements_with_same_cas01_and_cas02
    cas_elements = [['HR', '45', 10], ['HR', '45', 10], ['HR', '45', 5],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '45', 30], 
    ]
    pr_elements = [['HR', '45', 30], ['HR', '45', 3], ['HR', '45', 20]]
    cas_elements = cas_elements + pr_elements
    observed_cas_segments = Output835.combined_cas_segments(cas_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*158.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_combined_for_all_elements_with_same_cas01_and_different_cas02
    cas_elements = [['HR', '45', 10], ['HR', '45', 10], ['HR', '45', 5],
      ['HR', '45', 20], ['HR', '45', 30], ['HR', '45', 30]
    ]
    pr_elements = [['HR', '46', 30], ['HR', '46', 3], ['HR', '46', 20]]
    cas_elements = cas_elements + pr_elements
    observed_cas_segments = Output835.combined_cas_segments(cas_elements, '*')
    expected_observed_cas_segments = ["CAS*HR*45*105.00**46*53.00"]
    assert_equal expected_observed_cas_segments, observed_cas_segments
  end

  def test_no_mia_or_moa_segment_when_remark_codes_are_empty
    eob = insurance_payment_eobs(:ins_pay_eob_200)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal nil, observed_segments
  end

  def test_no_mia_or_moa_segment_when_patient_type_is_empty
    eob = insurance_payment_eobs(:ins_pay_eob_200)
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal nil, observed_segments
  end

  def test_claim_level_remark_codes_from_eob_association
    expected_segments = ['MIA*****AB***************AC']
    eob = insurance_payment_eobs(:eob_95)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_claim_level_remark_codes_from_reason_code_crosswalk
    expected_segments = ['MIA*****12']
    eob = insurance_payment_eobs(:svc_with_reason_codes)
    eob.patient_type = 'Inpatient'
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    payer = payers(:payer17)
    client = clients(:hlsc)
    cas_segments, clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(eob,
      client, facility, payer, '*')
    observed_segments = Output835.claim_level_remark_code_segments(eob, '*', crosswalked_codes)
    assert_equal expected_segments, observed_segments
  end

  def test_claim_level_remark_codes_from_eob_association_and_reason_code_crosswalk
    expected_segments = ["MIA*****12***************AB*AC*1"]
    eob = insurance_payment_eobs(:eob_102)
    eob.patient_type = 'Inpatient'
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    payer = payers(:payer17)
    client = clients(:hlsc)
    cas_segments, clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(eob,
      client, facility, payer, '*')
    observed_segments = Output835.claim_level_remark_code_segments(eob, '*', crosswalked_codes)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_one_remark_code
    expected_segments = ['MIA*****AB']
    eob = insurance_payment_eobs(:eob_94)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_two_remark_codes
    expected_segments = ['MIA*****AB***************AC']
    eob = insurance_payment_eobs(:eob_95)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_four_remark_codes
    expected_segments = ['MIA*****AB***************AC*1*12']
    eob = insurance_payment_eobs(:eob_96)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_five_remark_codes
    expected_segments = ['MIA*****AB***************AC*1*12*NC']
    eob = insurance_payment_eobs(:eob_97)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob, nil, nil)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_six_remark_codes
    expected_segments = ['MIA*****AB***************AC*1*12*NC',
      'MIA*****ABC']
    eob = insurance_payment_eobs(:eob_98)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_seven_remark_codes
    expected_segments = ['MIA*****AB***************AC*1*12*NC',
      'MIA*****ABC***************ACC']
    eob = insurance_payment_eobs(:eob_99)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_eight_remark_codes
    expected_segments = ['MIA*****AB***************AC*1*12*NC',
      'MIA*****ABC***************ACC*122']
    eob = insurance_payment_eobs(:eob_100)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_ten_remark_codes
    expected_segments = ['MIA*****AB***************AC*1*12*NC',
      'MIA*****ABC***************ACC*122*121*NCC']
    eob = insurance_payment_eobs(:eob_101)
    eob.patient_type = 'Inpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_one_remark_code
    expected_segments = ['MOA***AB']
    eob = insurance_payment_eobs(:eob_94)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_two_remark_codes
    expected_segments = ['MOA***AB*AC']
    eob = insurance_payment_eobs(:eob_95)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_four_remark_codes
    expected_segments = ['MOA***AB*AC*1*12']
    eob = insurance_payment_eobs(:eob_96)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_five_remark_codes
    expected_segments = ['MOA***AB*AC*1*12*NC']
    eob = insurance_payment_eobs(:eob_97)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_six_remark_codes
    expected_segments = ['MOA***AB*AC*1*12*NC', 'MOA***ABC']
    eob = insurance_payment_eobs(:eob_98)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_seven_remark_codes
    expected_segments = ['MOA***AB*AC*1*12*NC', 'MOA***ABC*ACC']
    eob = insurance_payment_eobs(:eob_99)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_moa_segment_for_eight_remark_codes
    expected_segments = ['MOA***AB*AC*1*12*NC', 'MOA***ABC*ACC*122']
    eob = insurance_payment_eobs(:eob_100)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_mia_segment_for_ten_remark_codes
    expected_segments = ['MOA***AB*AC*1*12*NC', 'MOA***ABC*ACC*122*121*NCC']
    eob = insurance_payment_eobs(:eob_101)
    eob.patient_type = 'Outpatient'
    observed_segments = Output835.claim_level_remark_code_segments(eob)
    assert_equal expected_segments, observed_segments
  end

  def test_unit_value_in_sucharge_adjustment
    expected_segments = ["CAS*HGC*H1*2.00", "CAS*GC7*H5*2.00",
      "CAS*HGG*H1*1.00", "CAS*CO*137*20.00*1"]
    eob = insurance_payment_eobs(:eob_103)
    eob.patient_type = 'Inpatient'
    facility = facilities(:facility_with_rcc_crosswalk_and_default_mapping)
    payer = payers(:payer17)
    client = clients(:hlsc)
    cas_segments, clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(eob,
      client, facility, payer, '*')   
    assert_equal expected_segments, cas_segments
  end

end