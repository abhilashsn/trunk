require File.dirname(__FILE__) + '/../test_helper'
require 'remittors_controller'

# Re-raise errors caught by the controller.
class RemittorsController; def rescue_action(e) raise e end; end

class RemittorsControllerTest < ActionController::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :remittors

  def test_should_allow_signup
    assert_difference 'Remittor.count' do
      create_remittor
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'Remittor.count' do
      create_remittor(:login => nil)
      assert assigns(:remittor).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'Remittor.count' do
      create_remittor(:password => nil)
      assert assigns(:remittor).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'Remittor.count' do
      create_remittor(:password_confirmation => nil)
      assert assigns(:remittor).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'Remittor.count' do
      create_remittor(:email => nil)
      assert assigns(:remittor).errors.on(:email)
      assert_response :success
    end
  end
  

  

  protected
    def create_remittor(options = {})
      post :create, :remittor => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire69', :password_confirmation => 'quire69' }.merge(options)
    end
end
