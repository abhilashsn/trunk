require File.dirname(__FILE__) + '/../test_helper'
require 'dashboard_controller'

# Re-raise errors caught by the controller.
class DashboardController; def rescue_action(e) raise e end; end

class DashboardControllerTest < Test::Unit::TestCase
fixtures :users

  def setup
    @controller = DashboardController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    #TODO: add tests to test authentication based on REMOTE_ADDR
    @request.env['REMOTE_ADDR'] = "127.0.0.1"
  end

  def test_index
    get :index
    assert_response :redirect
    assert_equal "Please login to continue", flash[:notice]
  end

  def test_login_with_invalid_user_id
    post :login, :user => {:userid => 'Unknown', :password => 'kar'}
    assert_response :success
    assert_equal "Invalid user/password combination", flash[:notice]
  end

  def test_login_with_invalid_password
    post :login, :user => {:userid => 'karuna', :password => 'karu'}
    assert_response :success
    assert_equal "Invalid user/password combination", flash[:notice]
  end

  def test_login_with_invalid_username_password
    post :login, :user => {:userid => 'karuna1', :password => 'wrong'}
    assert_template 'login'
    assert_equal "Invalid user/password combination", flash[:notice]
  end

  def test_login_with_valid_user
    post :login, :user => {:userid => 'gaur', :password => 'gaur'}
    assert_redirected_to :controller => 'dashboard'
    assert_not_nil(session[:user])
    user = User.find(session[:user])
    assert_equal 'Gaurav Sohoni', user.name, "Login name should match session name"
  end

  def test_login_with_valid_user1
    post :login, :user => {:userid => 'karuna1', :password => 'karuna1'}
    assert_redirected_to :controller => 'dashboard'
    assert_equal "Login successful", flash[:notice]
    assert_not_nil(session[:user])
    user = User.find(session[:user])
    assert_equal 'Karunakar Revuri', user.name, "Login name should match session name"
  end

  def test_logout
    post :login, :user => {:userid => 'gaur', :password => 'gaur'}
    get :logout
    assert_nil(session[:user])
    assert_equal session[:user], nil, "You are successfully loged out"
  end
  
  def test_change_password_correct
    #user required to login for changing password
    post :login, :user => {:userid => 'gaur', :password => 'gaur'}
    post :change_password, :password => {:new => 'abcd', :retyped => 'abcd'}, :commit => 'Change'
    assert_response :redirect
    assert_equal(flash[:notice], "Password changed successfully.")
  end
  
  def test_change_password_incorrect
    post :change_password, :password => {:new => 'good_pass', :retyped => 'oops_wrong'}, :commit => 'Change'
    assert_equal(flash[:notice], "Passwords do not match.")
    post :change_password, :password => {:new => 'no', :retyped => 'oops_wrong'}, :commit => 'Change'
    assert_equal(flash[:notice], "Password length should be greater than 4 characters.")
  end
  
  def test_login_with_unallowed_ip
    @request.env['REMOTE_ADDR'] = "127.100.100.100"
    post :login, :user => {:userid => 'karuna1', :password => 'karuna1'}
    #currently IPs are not being filtered
    #assert_redirected_to :action => 'index'
    #assert_equal(flash[:notice], "You are not authorized to enter.")
  end
  
end
