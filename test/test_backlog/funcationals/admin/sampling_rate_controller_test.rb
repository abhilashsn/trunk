require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/sampling_rate_controller'

# Re-raise errors caught by the controller.
class Admin::SamplingRateController; def rescue_action(e) raise e end; end

class Admin::SamplingRateControllerTest < Test::Unit::TestCase
  fixtures :sampling_rates, :users, :facilities

  def setup
    @controller = Admin::SamplingRateController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def login_as(user)
	user = users(user)
    @request.session[:user] = user.id
    facility = facilities(:facility2)
	return user
  end

  def test_index
    login_as(:gs)
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    login_as(:gs)
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:sampling_rates)
  end

  def test_show
    login_as(:gs)
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:sampling_rate)
    assert assigns(:sampling_rate).valid?
  end

  def test_new
    login_as(:gs)
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:sampling_rate)
  end

  def test_create
    login_as(:gs)
    num_sampling_rates = SamplingRate.count

    post :create, :sampling_rate => {:slab => '100', :value => 2}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_sampling_rates + 1, SamplingRate.count
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:sampling_rate)
    assert assigns(:sampling_rate).valid?
  end

  def test_update
    login_as(:gs)
    post :update, :id => 1, :sampling_rate => {:slab => '100', :value => 2}
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => 1
  end

  def test_destroy
    login_as(:gs)
    assert_not_nil SamplingRate.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      SamplingRate.find(1)
    }
  end
end
