require File.dirname(__FILE__)+'/../test_helper'
require 'provider_adjustments_controller'

class ProviderAdjustmentsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  fixtures :provider_adjustments, :jobs

  def setup
    @controller = ProviderAdjustmentsController.new
  end

  def test_provider_adjustment_summary_of_normal_job
    get :provider_adjustment_summary, {:job_id => 223}
    provider_adjusments = @controller.provider_adjustment_summary
    assert_equal(7, provider_adjusments[0].id)
  end

  def test_provider_adjustment_summary_of_parent_job
    get :provider_adjustment_summary, {:job_id => 222}
    provider_adjusments = @controller.provider_adjustment_summary
    assert_equal(4, provider_adjusments[0].id)
    assert_equal(5, provider_adjusments[1].id)
  end
  
  def test_provider_adjustment_summary_of_child_job
    get :provider_adjustment_summary, {:job_id => 225}
    provider_adjusments = @controller.provider_adjustment_summary
    assert_equal(5, provider_adjusments[0].id)
  end
end
