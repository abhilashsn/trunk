require File.dirname(__FILE__) + '/../test_helper'

class EobErrorTest < ActiveSupport::TestCase
  fixtures :eob_errors

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_to_s
    new_eob_error = EobError.new(:error_type => 'severe', :severity => 8)
    new_eob_error.save
    error_type = new_eob_error.to_s
    assert_equal("severe", error_type)
  end
end
