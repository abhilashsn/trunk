require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/payer_controller'

# Re-raise errors caught by the controller.
class Admin::PayerController; def rescue_action(e) raise e end; end

class Admin::PayerControllerTest < Test::Unit::TestCase
  fixtures :payers, :users, :facilities

  def setup
    @controller = Admin::PayerController.new
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
    assert_not_nil assigns(:payers)
  end

  def test_show
    login_as(:gs)
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:payer)
    assert assigns(:payer).valid?
  end

  def test_new
    login_as(:gs)
    get :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:payer)
  end

  def test_create
    login_as(:gs)
    num_payers = Payer.count
    post :create, :payer => {:id=>12,:payer=>"anu",:payid=>'4',:gateway=>"gateway1"}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal num_payers + 1, Payer.count
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:payer)
    assert assigns(:payer).valid?
  end

  def test_update
    login_as(:gs)
    post :update, :id => 1
    assert_response :redirect
    assert_equal flash[:notice],'Payer was successfully updated.'
    assert_redirected_to :action => 'list'
  end

  def test_destroy
    login_as(:gs)
    assert_not_nil Payer.find(1)
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      Payer.find(1)
    }
  end

  def test_delete_payers
    login_as(:gs)
    befor_num_payer = Payer.count
    payer1 = Payer.create!(:payer => "anu", :payid => '4', :gateway => "gateway1")
	payer2 = Payer.create!(:payer => "anu", :payid => '5', :gateway => "gateway2")
	num_payer = Payer.count
	payer_hash = {payer1.id  => 1, payer2.id => 1}
	get :delete_payers, :payers_to_delete => payer_hash
	assert_not_equal num_payer, Payer.count
	assert_equal befor_num_payer, Payer.count
  end


end
