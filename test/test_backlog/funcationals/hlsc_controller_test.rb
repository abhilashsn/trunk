require File.dirname(__FILE__) + '/../test_helper'
require 'hlsc_controller'

# Re-raise errors caught by the controller.
class HlscController; def rescue_action(e) raise e end; end

class HlscControllerTest < Test::Unit::TestCase
  fixtures :users, :jobs, :facilities, :batches, :job_statuses, :batch_statuses, :qa_statuses, :processor_statuses, :tats

  def setup
    @controller = HlscController.new
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
    login_as(:hlsc01)
    get :index
    assert_response :success
  end

  def test_batch_status
    login_as(:hlsc01)
    post :batch_status
    assert_response :success
  end

  def test_Accept_Batch
    login_as(:Revuri)
    batch = Batch.find_by_batchid(6)
    first = batch.status
    post :batch_status, :batch => 6, :accept => 1
    batch = Batch.find_by_batchid(6)
    after = batch.status
    assert_not_equal(first,after)
    assert_response :success
  end

  def test_batch_status_mark
    login_as(:gs)
    post :batch_status, :batch => 1, :mark => 1
    assert_equal 'Batch marked successfully.', flash[:notice]
    session[:user] = nil
    login_as(:hlsc01)
    batch = Batch.find(1)
    post :batch_status, :batch => 1, :mark => 1
    assert_equal 'Batch already marked by ' + "#{batch.hlsc}", flash[:notice]
    assert_response :success
  end

  def test_batch_status_unmark
    login_as(:gs)
    post :batch_status, :batch => 1, :unmark => 1
    assert_equal 'Batch unmarked successfully.', flash[:notice]
    assert_response :success
  end

  def test_batch_status_check_client_history
    login_as(:hlsc01)
    batch = Batch.find(1)
    count = batch.client_status_histories.count
    post :batch_status, :batch => batch.batchid, :mark => 1, :accept => 1
    batch.update_status
    assert_equal("HLSC Verified", batch.status)
    assert_not_equal(count,batch.client_status_histories.count)
    assert_response :success
  end

  def test_unprocessed_batches
    login_as(:hlsc01)
    get :unprocessed_batches
    assert_response :success
    assert_not_nil assigns(:batch_pages)
    assert_not_nil assigns(:batches)
  end

  def test_unprocessed_batches_batchid
    login_as(:hlsc01)
    get :unprocessed_batches, :to_find => 6, :compare => '=', :criteria => 'Batch ID'
    assert_not_nil assigns(:batches)
    assert_response :success
  end

  def test_reject_batch
    # failing when tests are run as test:functionals
    #login_as(:hlsc01)
    #batch = Batch.find(1)
    #count = batch.client_status_histories.count
    #comments = {:comment => "no good work"}
    #post :reject_batch, :id => 1, :commit => "Reject", :batch_rejection_comment => comments
    #batch = Batch.find(1)
    #assert_equal("HLSC Rejected",batch.status)
    #assert_not_equal(count,batch.client_status_histories.count)
    #assert_redirected_to :action => "batch_status"
  end

  def test_reject_checks
    # failing when tests are run as test:functionals
    #login_as(:hlsc01)
    #batch = Batch.find(1)
    #comments = {:comment => "Check Check_numbers"}
    #count = batch.client_status_histories.count
    #get :reject_checks, :id => 1, :commit => "Reject", :job_rejection_comment => comments, :job => {:check_number => 1}
    #batch = Batch.find(1)
    #assert_not_equal(count,batch.client_status_histories.count)
    #assert_equal("HLSC Rejected",batch.status)
    #assert_equal("Sub Jobs Rejected",batch.comment)
    #assert_response :success
  end

  def test_create_entry_for_check_rejection
  end

  def test_hlsc_report
    login_as(:hlsc01)
    get :hlsc_report
    assert_response :success
    assert_not_nil assigns(:report_pages)
    assert_not_nil assigns(:reports)
  end

  def test_summary_report
  end

  def test_filter_batches
  end

  def test_completed_batches_report
    login_as(:hlsc01)
    get :completed_batches_report
    assert_response :success
    assert_not_nil assigns(:report_pages)
    assert_not_nil assigns(:reports)
    assert_not_nil assigns(:complete_reports)
  end

end
