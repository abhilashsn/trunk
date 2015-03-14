require File.dirname(__FILE__) + '/../test_helper'

class BatchStatusTest < ActiveSupport::TestCase
  fixtures :batch_statuses
  
  def test_to_s
    status = batch_statuses(:bs2)
    assert_equal status.name, status.name.to_s
  end
end
