require File.dirname(__FILE__) + '/../test_helper'
require 'ajaxcontroller_controller'

# Re-raise errors caught by the controller.
class AjaxcontrollerController; def rescue_action(e) raise e end; end

class AjaxcontrollerControllerTest < Test::Unit::TestCase
  def setup
    @controller = AjaxcontrollerController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
