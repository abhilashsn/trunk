require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/site_settings_controller'

# Re-raise errors caught by the controller.
class Admin::SiteSettingsController; def rescue_action(e) raise e end; end

class Admin::SiteSettingsControllerTest < Test::Unit::TestCase
  fixtures :site_settings

  def setup
    @controller = Admin::SiteSettingsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:site_settings)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:site_setting)
    assert assigns(:site_setting).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:site_setting)
  end

  def test_create
    num_site_settings = SiteSetting.count

    post :create, :site_setting => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_site_settings + 1, SiteSetting.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:site_setting)
    assert assigns(:site_setting).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil SiteSetting.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      SiteSetting.find(1)
    }
  end
end
