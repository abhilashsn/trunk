require File.dirname(__FILE__) + '/../test_helper'

class EdiHelperTest < ActiveSupport::TestCase
  include EdiHelper::InstanceMethods
  
  def test_empty_composite_element
    assert_equal "", composite_element([])
  end

  def test_blank_composite_element
    assert_equal "", composite_element(["", "", "", "", ""])
  end

  def test_partially_blank_composite_element
    assert_equal "HC<92301", composite_element(["HC", "92301", "", "", ""])
  end

  def test_composite_element
    assert_equal "HC<92301<25<LT", composite_element(["HC", "92301", "25", "LT"])
  end
end