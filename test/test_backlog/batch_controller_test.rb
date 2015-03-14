require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/batch_controller'

# Re-raise errors caught by the controller.
class Admin::BatchController; def rescue_action(e) raise e end; end

class Admin::BatchControllerTest < Test::Unit::TestCase
  fixtures :batches,:users, :facilities, :jobs, :payers

  def setup
    @controller = Admin::BatchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def login_as(user)
    user = users(user)
    @request.session[:user] = user.id
    facility = facilities(:facility2)
    return user
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
    assert_not_nil assigns(:batches)
  end

  def test_comments
    login_as(:gs)
    get :comments, :id => 1
    assert_response :success
    assert_template 'comments'
  end

  def test_show
    login_as(:gs)
    post :show, :id => 1
    assert_response :success
    assert_template 'show'
  end

  def test_new
    login_as(:gs)
    post :new
    assert_response :success
    assert_template 'new'
    assert_not_nil assigns(:batch)
  end

  def test_create
    login_as(:gs)
    num_batches = Batch.count
    post :create, :batch => {:batchid => "123456789", :facility_id => 1, :date => Date.today, :arrival_time => Time.now, :target_time => Time.now}
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal flash[:notice], "Batch was successfully created."
    assert_equal num_batches + 1, Batch.count
  end

  def test_edit
    login_as(:gs)
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    assert_not_nil assigns(:batch)
  end

  def test_update
    login_as(:gs)
    post :update, :id => 1
    assert_response :success
    assert_template 'edit'
  end

  def test_destroy
    login_as(:gs)
    assert_not_nil Batch.find(1)
    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_raise(ActiveRecord::RecordNotFound) {
      Batch.find(1)
    }
  end

  def test_delete_batches
    login_as(:gs)
    num_batches = Batch.count
    batch1 = Batch.create!(:batchid => "123456789", :facility_id => 1, :date => Date.today, :arrival_time => Time.now, :target_time => Time.now)
    batch2 = Batch.create!(:batchid => "123456790", :facility_id => 1, :date => Date.today, :arrival_time => Time.now, :target_time => Time.now)
    assert_not_equal(num_batches,Batch.count)
    num_batches_after_add = Batch.count
    batch_hash = {batch1.id => 1, batch2.id => 2}
    get :delete_batches, :batches_to_delete => batch_hash
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_not_equal(num_batches_after_add,Batch.count)
    assert_equal(num_batches,Batch.count)
  end

  def test_allocate
    login_as(:gs)
    post :allocate
    assert_response :success
    assert_template 'allocate'
  end

  def test_non_compliant
    login_as(:gs)
    get :non_compliant
    assert_response :redirect
    assert_redirected_to :action => 'allocate'
  end

  def test_add_job
    login_as(:gs)
    get :add_job, :id => 1
    assert_response :success
    assert_template 'add_job'
  end

  def test_delete_jobs
    login_as(:gs)
    batch = Batch.find(1)
    job = Job.create!(:batch => batch, :check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60)
    job1 = Job.create!(:batch => batch, :check_number => 223, :tiff_number => 2225, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60)
    job_hash = {job.id => 1,job1.id => 1}
    get :delete_jobs, {:jobs_to_delete => job_hash, :batch => batch.id}
    assert_response :redirect
    assert_redirected_to :action => 'add_job'
  end

  def test_create_job
    login_as(:gs)
    batch = Batch.find(1)
    job = {:check_number => 123, :tiff_number => 2345, :processor => users(:processor01), :qa => users(:qa01), :estimated_eob => 60}
    get :create_job, {:job => job, :batch => batch.id}
    assert_response :redirect
    assert_not_equal flash[:notice], 'Job was successfully created'
    assert_redirected_to :action => 'add_job'
  end

  def test_update_tat_comments
    login_as(:gs)
    batch = Batch.find(1)
    tat = Tat.create!(:expected_time => '12/12/06', :batch_id => 1)
    tat1 = {:expected_time => '12/12/06'}
    get :update_tat_comments, {:id => batch.id, :tat => tat1}
    assert_response :redirect
    assert_redirected_to :action => 'allocate'
  end
  
  def test_index
    login_as(:gs)
    post :index
    assert_redirected_to :action => :list
  end

  def test_list_with_search_fields
    login_as(:gs)
    post :list, :to_find => '2', :compare => '<', :criteria => 'Batch ID'
    assert_response :success
    post :list, :to_find => '10101', :compare => '>', :criteria => 'Batch ID'
    assert_equal(flash[:notice], " No record found for <i>Batch ID > \"10101\"</i>")
    post :list, :to_find => '200', :compare => '<', :criteria => 'Estimated EOB'
    assert_response :success
    post :list, :to_find => '200', :compare => '<', :criteria => 'Estimated EOB'
    assert_response :success
    post :list, :to_find => 'Processing', :compare => '=', :criteria => 'Status'
    assert_response :success
    assert_equal("String search, '#{@request.request_parameters[:compare]}' ignored.", flash[:notice])
    post :list, :to_find => 'apria', :compare => '=', :criteria => 'Facility'
    assert_response :success
    assert_equal("String search, '#{@request.request_parameters[:compare]}' ignored.", flash[:notice])
  end
	
  def test_allocate
    login_as(:gs)
    post :allocate, :to_find => '2', :compare => '<', :criteria => 'Batch ID'
    assert_response :success
    post :allocate, :to_find => '10101', :compare => '>', :criteria => 'Batch ID'
    assert_equal(flash[:notice], " No record found for <i>Batch ID > \"10101\"</i>")
  end
	
  def test_add_job
    login_as(:gs)
    get :add_job
    assert_equal(flash[:notice], "Job administration screen cannot be accessed directly.")
    #assert_redirected_to(:controller => '/admin/batch', :action => 'index')
    assert_response :redirect
  end
	
  def test_delete_jobs
    login_as(:gs)
    get :delete_jobs, :batch => '2', :jobs_to_delete => {}
    assert_equal(flash[:notice], "Please select atleast one Job to delete.")
  end
	
  def test_non_compliant
    login_as(:gs)
    post :non_compliant, :to_find => '2', :compare => '<', :criteria => 'Batch ID'
    assert_equal(flash[:notice], " No record found for <i>Batch ID < \"2\"</i>")
  end
	
  def test_update_tat_comments
    login_as(:gs)
    batch = batches(:batch1)
    get :update_tat_comments, :id => 1
    assert_not_nil batch.tat
  end
end
