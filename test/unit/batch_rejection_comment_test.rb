require File.dirname(__FILE__) + '/../test_helper'

class BatchRejectionCommentTest < ActiveSupport::TestCase
  fixtures :batch_rejection_comments

  # Replace this with your real tests.
  def test_truth
    assert true
  end
  
  def test_to_s
    comment_one = batch_rejection_comments(:comment1)
    assert_equal comment_one.comment, comment_one.to_s
  end
end
