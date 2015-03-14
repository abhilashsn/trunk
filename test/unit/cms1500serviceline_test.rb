require File.dirname(__FILE__) + '/../test_helper'

class Cms1500servicelineTest < ActiveSupport::TestCase
  
  # disabling tests due to non-exitence of Cms1500serviceline
  
  def ntest_sv101
    service_line = Cms1500serviceline.new(:cpt_hcpcts => "92301", 
                                          :modifier1 => "LT",
                                          :modifier2 => "25",
                                          :modifier3 => "", 
                                          :modifier4 => "")
    assert_equal "HC<92301<LT<25", service_line.sv101
  end
  
  def ntest_sv107
    service_line = Cms1500serviceline.new(:diagnosis_pointer => 124)
    assert_equal "1<2<4", service_line.sv107
  end
  
  def ntest_qual_id_for_837
    service_line = Cms1500serviceline.new(:qual_id => "0B")
    assert_equal "0B", service_line.qual_id_for_837
  end

  def ntest_qual_id_for_837_out_of_range
    service_line = Cms1500serviceline.new(:qual_id => "F0")
    assert_equal "G2", service_line.qual_id_for_837
  end
end