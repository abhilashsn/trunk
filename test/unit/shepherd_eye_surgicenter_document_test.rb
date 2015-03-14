require File.dirname(__FILE__)+'/../test_helper'

class Output835::ShepherdEyeSurgicenterDocumentTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations, :isa_identifiers, :payers, :facility_output_configs
  
  def setup
    @document = Output835::ShepherdEyeSurgicenterDocument.new([check_informations(:check_7)])
    facility_tin = facilities(:facility_3).facility_tin.strip
    @isa_test_segment = "ISA*00*          *00*          *30*#{'582574363'.ljust\
        (15)}*30*#{facility_tin.ljust(15)}*#{Time.now().strftime("%y%m%d")}*#{Time.now()\
        .strftime("%H%M")}*U*00401*#{isa_identifiers(:isa_1).isa_number.to_s.rjust(9, '0')}*1*P*:"
    @gs_segment = "GS*HP*#{payers(:payer7).payid}*1000000*#{Time.now().strftime("%Y%m%d")\
        }*#{Time.now().strftime("%H%M")}*#{isa_identifiers(:isa_1).isa_number.to_s.rjust(9, '0')}*X*004010X091A1"
    isa = IsaIdentifier.first
    @ge_segment = "GE*#{@document.checks_in_functional_group(nil)}*#{isa.isa_number.to_s.rjust(9, '0')}"
  end
  
  def test_interchange_control_header
    assert_equal(@isa_test_segment,@document.interchange_control_header)
  end
  
  def test_functional_group_header
    assert_equal(@gs_segment, @document.functional_group_header)
  end
  
  def test_functional_group_trailer
    assert_equal(@ge_segment, @document.functional_group_trailer(nil))
  end
  
end