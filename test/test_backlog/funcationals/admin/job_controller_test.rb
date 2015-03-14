require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/job_controller'

# Re-raise errors caught by the controller.
class Admin::JobController; def rescue_action(e) raise e end; end

class Admin::JobControllerOldTest < Test::Unit::TestCase
  fixtures :jobs, :users, :facilities, :batches, :payers

  def setup
    @controller = Admin::JobController.new
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
    post :list
    assert_response :success
    assert_template 'list'
    assert_not_nil assigns(:jobs)
  end

  def test_show
    login_as(:gs)
    post :show, :id => 1
    assert_response :success
    assert_template 'show'
  end

  def test_new
    login_as(:gs)
    post :new, :id => 1
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:job)
  end


  def test_split
    login_as(:gs)
    get :split, :id => 1
    assert_response :success
    assert_template 'split'
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:job)
  end

  def test_update
    login_as(:gs)
    post :update, :id => 1, :job => {:check_number => 100, :tiff_number => 200, :estimated_eob => 20}
    assert_equal(flash[:notice], 'Job was successfully updated.')
    #assert_redirected_to :controller => 'batch', :action => 'add_job', :id => assigns(:job).batch
    assert_response :redirect
  end

  def test_allocate
    login_as(:gs)
    facility = facilities(:facility2)
    batch = Batch.create!(:batchid => 1111, :date => Date.today.strftime("%m/%d/%Y"), :facility => facility, :arrival_time => "#{Time.now}")
    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor_id => 1, :estimated_eob => 60)
    get :allocate, {:id => batch.id}
    assert_response :success
    assert_template 'allocate'
  end

  def test_add_qa
    login_as(:gs)
    batch = batches(:batch4)
    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :estimated_eob => 60)
    job1 = Job.create!(:batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :estimated_eob => 60)
    job_hash = {job.id  => 1, job1.id => 1}
    get :add_qa, :jobs => job_hash
    assert_not_nil assigns(:jobs)
    assert_equal job_hash.length, assigns(:jobs).size
    assert_not_nil assigns(:users)
  end

  def test_add_processor
    login_as(:gs)
    batch = batches(:batch4)
    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :estimated_eob => 60)
    job1 = Job.create!(:batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :estimated_eob => 60)
    job_array = [job.id, job1.id]
    get :add_processor, :jobs => job_array
    assert_not_nil assigns(:jobs)
    assert_equal job_array.length, assigns(:jobs).size
    assert_not_nil assigns(:users)
  end

  def test_assign
    user = login_as(:gs)
    batch = batches(:batch4)
    job_hash = Array.new
    job = Job.create!(:id => 20, :batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :estimated_eob => 60)
    job1 = Job.create!(:id =>21, :batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :estimated_eob => 60)
    job_hash << job.id << job1.id
    post :assign, :jobs => job_hash, :user => users(:processor01).id
    assert_not_nil assigns(:jobs)
    assert_redirected_to :action => "allocate"
  end

  def test_allocate_deallocate
    login_as(:gs)
    batch = batches(:batch4)

    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :estimated_eob => 60)
    job1 = Job.create!(:batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :estimated_eob => 60)
    job_hash = {job.id  => 1, job1.id => 1}
    get :allocate_deallocate, {:jobs_to_allocate => job_hash, :user => users(:processor01), :option1 => 'Allocate QA'}
    assert_not_nil assigns(:jobs)
    assert_redirected_to :action => "add_qa"
  end

  def test_deallocate_processor
    login_as(:gs)
    batch = batches(:batch4)
    job_hash = Array.new
    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60)
    job1 = Job.create!(:batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60)
    job_hash << job.id << job1.id
    get :deallocate_processor, :jobs => job_hash
    assert_not_nil assigns(:jobs)
    assert_redirected_to :action => "allocate"
  end

  def test_deallocate_qa
    login_as(:gs)
    batch = batches(:batch4)
    job_hash = Array.new
    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60)
    job1 = Job.create!(:batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60)
    job_hash << job.id << job1.id
    get :deallocate_qa, :jobs => job_hash
    assert_not_nil assigns(:jobs)
    assert_redirected_to :action => "allocate"
  end
  
  def test_create
    login_as(:gs)
    @request.session[:batch] = batches(:batch2).id
    post :create, :job => {:check_number => 111, :tiff_number => 222, :estimated_eob => 10}
    assert_redirected_to :action => 'list'
    assert_equal(flash[:notice], 'Job was successfully created.')
  end
  
  def test_split_update
    login_as(:gs)
    job = jobs(:job2)
    post :split_update, :id => job.id, :new_job => {:check_number => 111, :tiff_number => 222, :estimated_eob => 10}
    assert_equal(flash[:notice], 'Job was successfully updated.')
    #assert_redirected_to :controller => "/admin/batch", :action => "add_job", :id => job.batch
    assert_response :redirect
  end
  
  def test_destroy
    login_as(:gs)
    post :destroy, :id => jobs(:job3).id
    #assert_redirected_to :controller => 'batch', :action => 'add_job'
    assert_response :redirect
  end

end
