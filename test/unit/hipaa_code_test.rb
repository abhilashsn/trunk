require 'test_helper'

class HipaaCodeTest < ActiveSupport::TestCase
  fixtures :hipaa_codes
  # Replace this with your real tests.
  def test_truth
    assert true
  end

  def test_valid_hipaa_adjustment_code
    assert_equal hipaa_codes(:hipaa_code_1).hipaa_adjustment_code, hipaa_codes(:hipaa_code_1).valid_hipaa_adjustment_code
  end

  def test_invalid_hipaa_adjustment_code
    assert_equal nil, hipaa_codes(:invalid_hipaa_code_1).valid_hipaa_adjustment_code
    assert_equal nil, hipaa_codes(:invalid_hipaa_code_2).valid_hipaa_adjustment_code
  end

end
