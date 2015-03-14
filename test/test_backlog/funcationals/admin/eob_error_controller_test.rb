require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/eob_error_controller'

# Re-raise errors caught by the controller.
class Admin::EobErrorController; def rescue_action(e) raise e end; end

class Admin::EobErrorControllerTest < Test::Unit::TestCase
  fixtures :eob_errors, :users, :facilities

  def setup
    @controller = Admin::EobErrorController.new
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

    assert_not_nil assigns(:eob_errors)
  end

  def test_show
    login_as(:gs)
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:eob_error)
  end

  def test_new
    login_as(:gs)
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:eob_error)
  end

  def test_create
    login_as(:gs)
    num_eob_errors = EobError.count

    post :create, :eob_error => {:error_type => 'Simple Error', :severity => 3}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_eob_errors + 1, EobError.count
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:eob_error)
  end

  def test_update
    login_as(:gs)
    post :update, :id => 1, :eob_error => {:error_type => 'Simple error', :severity => 3}
    assert_response :redirect
    assert_redirected_to :action => 'list', :id => 1
  end

  def test_destroy
    login_as(:gs)
    assert_not_nil EobError.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      EobError.find(1)
    }
  end
end
