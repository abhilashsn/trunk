require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/facility_controller'

# Re-raise errors caught by the controller.
class Admin::FacilityController; def rescue_action(e) raise e end; end

class Admin::FacilityControllerTest < Test::Unit::TestCase
  fixtures :users, :facilities, :clients

  def setup
    @controller = Admin::FacilityController.new
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
    assert_not_nil assigns(:facilities)
  end

  def test_show
    login_as(:gs)
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:facility)
    assert assigns(:facility).valid?
  end

  def test_new
    login_as(:gs)
    get :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:facility)
  end

  def test_create
    login_as(:gs)
    num_facilities = Facility.count
    post :create, :facility => {:id=>20,:name=>"abc",:sitecode=>"0091"}, :form => {:client =>'Apria'}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_facilities + 1, Facility.count
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:facility)
    assert assigns(:facility).valid?
  end

  def test_update
    login_as(:gs)
    post :update, :id => 1, :facility => {:id=>20,:name=>"abc",:sitecode=>"0091"}, :form => {:client =>'Apria'}
    assert_response :redirect
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    login_as(:gs)
    assert_not_nil Facility.find(1)
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      Facility.find(1)
    }
  end

  def test_delete_fecility
    login_as(:gs)
    facility1 = Facility.create!(:id => 20, :name => "abc", :client_id => 1, :sitecode => "0091")
    facility2 = Facility.create!(:id => 21, :name => "xyz", :client_id => 1, :sitecode => "0092")
    num_facilities = Facility.count
    job_hash = {facility1.id  => 1, facility2.id => 1}
    post :delete_facilities, :facility_to_delete => job_hash
    assert_redirected_to :action => 'list'
    assert_not_equal num_facilities, Facility.count
  
    job_hash = {}
    post :delete_facilities, :facility_to_delete => job_hash
    assert_equal("Please select atleast one facility to delete .", flash[:notice])
  end
  
  def test_list_with_params
		login_as(:gs)
		post :list, {:to_find => 'Apria - Home Medical', :criteria => 'Name'}
		assert_response :success
		post :list, {:to_find => 'Apria', :criteria => 'Client'}
		assert_response :success
		post :list, {:to_find => '00811', :criteria => 'Code'}
		assert_response :success
  end
  
  def test_create_without_client
		login_as(:gs)
		post :create , {:sitecode => 76777, :name => 'aaaa', :client => clients(:Apria)}
		assert_template 'new'
		post :create , {:sitecode => 76777, :name => 'aaaa', :client => clients(:Apria)}
  end

end
