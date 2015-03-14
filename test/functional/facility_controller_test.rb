#require File.dirname(__FILE__) + '/../test_helper'
require 'test_helper'
require 'admin/facility_controller'

class FacilityControllerTest < ActionController::TestCase
  fixtures :jobs, :users, :facilities, :clients, :batches, :micr_line_informations,
           :check_informations, :client_images_to_jobs, :roles, :roles_users
         
  def setup
    @controller = Admin::FacilityController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new 
  end
  
  def ntest_edit
    get :edit, {:id => facilities(:facility_20).id},{:user_id => users(:admin).id}
    assert_select "input[id=facility_default_patpay_payer_tin][value=#{facilities(:facility_20).default_patpay_payer_tin}]"
  end
end
