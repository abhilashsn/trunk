require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/admin_report_controller'

# Re-raise errors caught by the controller.
class Admin::AdminReportController; def rescue_action(e) raise e end; end

class Admin::AdminReportControllerTest < Test::Unit::TestCase
  fixtures :batches, :site_settings, :clients, :facilities
  
  def setup
    @controller = Admin::AdminReportController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # For #481 - TAT report failing when run against batch with missing completion_time
  # This depends on having a batch fixture that is "Complete" but has not completion_time set
  def test_tat_report_with_incomplete_batch
    get :tat_report
    assert_response :success
  end
end
