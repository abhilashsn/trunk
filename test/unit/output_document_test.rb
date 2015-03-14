require File.dirname(__FILE__)+'/../test_helper'

class OutputDocumentTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :payers , :facility_output_configs, :isa_identifiers
  
  def setup
    @check = check_informations(:check_7)
    @document = Output835::OutputDocument.new([check_informations(:check_7)])
    @facility = facilities(:facility_3)
    @fac_config = facility_output_configs(:facility_output_config_9)
    @isa = "ISA*00*#{' '*10}*00*#{' '*10}*ZZ*123481         *ZZ*#{@facility.facility_tin.ljust(15)}*#{Time.now().strftime('%y%m%d')}*#{Time.now().strftime('%H%M')}*U*00401*000008888*0*P*&&"
  end
  
  def test_parse_output_configurations
    assert_equal(@isa, @document.parse_output_configurations(:isa_segment))
  end
  
  def test_make_segment_array
    isa = ["ISA","00","#{' '*10}","00","#{' '*10}","ZZ","#{@fac_config.details[:isa_segment]['6']}#15","ZZ","#{@fac_config.details[:isa_segment]['8']}#15","#{Time.now().strftime('%y%m%d')}","#{Time.now().strftime('%H%M')}","U","00401","#{@fac_config.details[:isa_segment]['13']}","0","P","&&"]
    assert_equal(isa, @document.make_segment_array(@fac_config.details[:isa_segment].convert_keys,:isa_segment) )
  end
  
  def test_interchange_control_header
    assert_equal(@isa, @document.interchange_control_header)
  end

  def test_functional_group_trailer
    assert_equal("GE*#{@document.checks_in_functional_group(@check.batch.id)}*1", @document.functional_group_trailer(@check.batch.id))
  end

  def test_cpid
    assert_equal("123481", @document.cpid)
  end
  
end