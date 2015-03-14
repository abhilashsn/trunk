require File.dirname(__FILE__)+'/../test_helper'

class OutputCheckTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :payers , :facility_output_configs, :insurance_payment_eobs,
    :client_images_to_jobs, :images_for_jobs, :image_types
  
  def setup
    Output835::OutputCheck.class_eval("@@batch_based_index = ''")
    @check = Output835::OutputCheck.new(check_informations(:check_7), facilities(:facility_3),1, '*')
    @fac_config = facility_output_configs(:facility_output_config_9)
    @trn = "TRN*1*#{batches(:batch_11).batchid}*1#{payers(:payer7).payer_tin}"
    @facility = facilities(:facility_3)
  end

  def test_parse_output_configurations
    assert_equal(@trn, @check.parse_output_configurations(:trn_segment))
  end

  def test_make_segment_array
    trn = ["TRN", "1", @fac_config.details[:trn_segment]['2'], @fac_config.details[:trn_segment]['3']]
    assert_equal(trn, @check.make_segment_array(@fac_config.details[:trn_segment].convert_keys,:trn_segment) )
  end

  def test_reassociation_trace
    assert_equal(@trn, @check.reassociation_trace)
  end

  def test_transaction_set_line_number
    assert_equal("LX*1", @check.transaction_set_line_number(1))
  end

  def test_address
    assert_equal("N3*#{payers(:payer7).address_one.upcase}", @check.address(payers(:payer_45)))
  end

  def test_geographic_location
    payer = payers(:payer7)
    assert_equal("N4*#{payer.city.upcase}*#{payer.state.upcase}*#{payer.zip_code.upcase}", @check.geographic_location(payers(:payer_45)))
  end

  def test_payee_additional_identification
    assert_equal("REF*TJ*#{facilities(:facility_3).facility_tin}", @check.payee_additional_identification)
  end

  def test_payee_identification_code
    assert_equal("1801992631", @check.payee_identification_code)
  end

  def test_output_payer
    assert_equal(payers(:payer7).payer_city.to_s.upcase, @check.output_payer("city"))
    assert_equal("", @check.output_payer("cit"))
  end

  def test_output_payer_for_facility_with_sitecode_00877
    check = check_informations(:check_61)
    facility = facilities(:facility_29)
    payer = payers(:two)
    @check.instance_variable_set("@facility", facility)
    @check.instance_variable_set("@payer", payer)
    @check.create_default_payers
    default_payer_address = payer.default_payer_address(facility, check)
    @check.instance_variable_set("@default_payer_address", default_payer_address)

    expected_address_one = '100 WEST BIG BEAVER, SUITE 600'
    expected_city = 'TROY'
    expected_state = 'MI'
    expected_zip_code = '48084'
    
    obtained_address_one = @check.output_payer("address_one")
    obtained_city = @check.output_payer("city")
    obtained_state = @check.output_payer("state")
    obtained_zip_code = @check.output_payer("zip_code")

    assert_equal expected_address_one, obtained_address_one
    assert_equal expected_city, obtained_city
    assert_equal expected_state, obtained_state
    assert_equal expected_zip_code, obtained_zip_code
  end

  def test_output_payer_for_obtaining_facility_default_payer_address
    check = check_informations(:check_61)
    facility = facilities(:facility_2)
    payer = payers(:non_patpay_payer)
    @check.instance_variable_set("@facility", facility)
    @check.instance_variable_set("@payer", payer)
    @check.create_default_payers
    default_payer_address = payer.default_payer_address(facility, check)
    @check.instance_variable_set("@default_payer_address", default_payer_address)
    expected_address_one = 'ADDRESS ONE'
    expected_city = 'PAYER CITY'
    expected_state = 'SS'
    expected_zip_code = '00099'
    
    obtained_address_one = @check.output_payer("address_one")
    obtained_city = @check.output_payer("city")
    obtained_state = @check.output_payer("state")
    obtained_zip_code = @check.output_payer("zip_code")
    
    assert_equal expected_address_one, obtained_address_one
    assert_equal expected_city, obtained_city
    assert_equal expected_state, obtained_state
    assert_equal expected_zip_code, obtained_zip_code
  end

  def test_output_payer_for_obtaining_address_that_belongs_to_payer
    check = check_informations(:check_61)
    facility = facilities(:facility_2)
    payer = payers(:payer1)
    @check.instance_variable_set("@facility", facility)
    @check.instance_variable_set("@payer", payer)
    @check.create_default_payers
    default_payer_address = payer.default_payer_address(facility, check)
    @check.instance_variable_set("@default_payer_address", default_payer_address)
    expected_address_one = payer.address_one
    expected_city = payer.city
    expected_state = payer.state
    expected_zip_code = payer.zip_code

    obtained_address_one = @check.output_payer("address_one")
    obtained_city = @check.output_payer("city")
    obtained_state = @check.output_payer("state")
    obtained_zip_code = @check.output_payer("zip_code")

    assert_equal expected_address_one, obtained_address_one
    assert_equal expected_city, obtained_city
    assert_equal expected_state, obtained_state
    assert_equal expected_zip_code, obtained_zip_code
  end

  def test_reciever_id
    assert_equal("REF*EV*#{images_for_jobs(:img_for_jb11).filename}", @check.reciever_id)
  end

  def test_transaction_set_line_number
    assert_equal("LX*#{@fac_config.details[:lx_segment]['1']}", @check.transaction_set_line_number(1, 1, @fac_config.details[:lx_segment]['1']))
  end

  def test_submitter_identification_bac
    assert_equal("REF*SI*#{@check.submitter_identification_number}",@check.submitter_identification_bac)
  end

end
