require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/status_controller'

# Re-raise errors caught by the controller.
class Admin::StatusController; def rescue_action(e) raise e end; end

class Admin::StatusControllerTest < Test::Unit::TestCase
  fixtures :statuses, :users, :facilities

  def setup
    @controller = Admin::StatusController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def login_as(user)
	user = users(user)
    @request.session[:user] = user.id
    facility = facilities(:facility2)
	return user
  end

  def test_index_with_user
    login_as(:gs)
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_index_without_user
    get :index
    assert_redirected_to :action => "index"
    assert_equal "You don\'t have necessary permission.", flash[:notice]
  end

  def test_list
    login_as(:gs)
    get :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:statuses)
  end

  def test_show
    login_as(:gs)
    get :show, :id => 6
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:status)
    assert assigns(:status).valid?
  end

  def test_new
    login_as(:gs)
    get :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:status)
  end

  def test_create
    login_as(:gs)
    num_statuses = Status.count
    post :create, :status => {:id => 3, :value => "Inactive"}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_statuses + 1, Status.count
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 6
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:status)
    assert assigns(:status).valid?
  end

  def test_update
    login_as(:gs)
    post :update, :id => 6
    assert_response :redirect
    assert_not_nil assigns(:status)
    assert_redirected_to :action => 'show', :id => 6
  end

  def test_destroy
    login_as(:gs)
    assert_not_nil Status.find(6)
    post :destroy, :id => 6
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      Status.find(6)
    }
  end

  def test_delete_status
    login_as(:gs)
    befor_num_status = Status.count
    status1 = Status.create!(:id => 1, :value => "HLSC Verified")
	status2 = Status.create!(:id => 2, :value => "HLSC Rejected")
	num_status = Status.count
	status_hash = {status1.id  => 1, status2.id => 1}
	get :delete_status, :status_to_delete => status_hash
	assert_not_equal num_status, Status.count
	assert_equal befor_num_status, Status.count
  end

end
