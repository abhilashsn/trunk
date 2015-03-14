require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/user_controller'

# Re-raise errors caught by the controller.
class Admin::UserController; def rescue_action(e) raise e end; end

class Admin::UserControllerTest < Test::Unit::TestCase
  fixtures :users, :batches

  def setup
    @controller = Admin::UserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def login_as(user)
    user = users(user)
    @request.session[:user] = user.id
    return user
  end

  #def test_index
  #  login_as(:gs)
  #  get :index
  #  assert_response :success
  #  assert_template 'list'
  #end

  def test_list
    login_as(:gs)
    get :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:users)
  end

  def test_show
    login_as(:gs)
    get :show, :id => 15
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:user)
  end

  def test_update
    login_as(:gs)
    post :update, :id => 2, :user => {:name => "GauravS", :userid => "gs",:password => "gs", :shift => 1,
                        :remark       =>   "user",
                        :role         =>   "Supervisor",
                        :status       =>   "Online",
                        :processing_rate_triad => 5,
                        :processing_rate_others => 8
                        }
    assert_equal('User was successfully updated.',flash[:notice] )
    assert_redirected_to :action => 'list'
  end


  def test_destroy
    login_as(:gs)
    assert_not_nil Batch.find(1)
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      User.find(1)
    }
  end

  def test_new
    login_as(:gs)
    post :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:user)
  end

  def test_create
    login_as(:gs)
    num_users = User.count
    post :create, :user => {:name => "GauravS", :userid => "gs",:password => "gs", :shift => 1,
                        :remark       =>   "user",
                        :role         =>   "Supervisor",
                        :status       =>   "Online"}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal flash[:notice], "User was successfully created."
    assert_equal num_users + 1, User.count
  end

  def test_delete_users
    num_users = User.count
    user1 = User.create!(:name => "GauravS", :userid => "gs",:password => "gs", :shift => 1,
                        :remark       =>   "user",
                        :role         =>   "Supervisor",
                        :status       =>   "Online")
    user2 = User.create!(:name => "Anand", :userid => "anum",:password => "anum", :shift => 1,
                        :remark       =>   "user",
                        :role         =>   "Supervisor",
                        :status       =>   "Online")
    user_hash = {user1.id => 1, user2.id => 2}
    get :delete_users, :users_to_delete => user_hash
    assert_response :redirect
    assert_equal num_users + 1, User.count
  end

  def test_list_jobs
    user = login_as(:gs)
    user_new = User.create!(:name => 'new_user', :userid => 'new_user', :role => 'Processor', :password => 'new', :status => 'Online')
    job1 = Job.create!(:batch => batches(:batch4), :check_number => 1234, :tiff_number => 4321, :processor => user_new, :estimated_eob => 60)
    job2 = Job.create!(:batch => batches(:batch4), :check_number => 1235, :tiff_number => 4320, :processor => user_new, :estimated_eob => 60)
    get :list_jobs, :id => user_new.id
    assert_response :success
    assert_equal user_new.jobs.size, assigns(:jobs).size
  end

  def test_list_jobs_with_no_jobs
    login_as(:gs)
    user_new = User.create!(:name => 'new_user', :userid => 'new_user', :role => 'Processor', :password => 'new', :status => 'Online')
    get :list_jobs, :id => user_new.id
    assert_equal 0, assigns(:jobs).size
    assert_equal "No job has been assigned to the processor!", flash[:notice]
  end

  def test_validate
    login_as(:processor01)
    get :validate
    assert_equal 'You don\'t have necessary permission.', flash[:notice]
    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
  end

  def test_delete_users
    login_as(:gs)
    user_new = users(:coty)
    user_hash = {users(:coty).id.to_s => 1}
    get :delete_users, :users_to_delete => user_hash
    assert_equal 1, assigns(:flag)
    assert_equal 'The default Admin user cannot be deleted.', flash[:notice1]
  end

end
