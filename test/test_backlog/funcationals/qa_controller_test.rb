require File.dirname(__FILE__) + '/../test_helper'
require 'qa_controller'

# Re-raise errors caught by the controller.
class QaController; def rescue_action(e) raise e end; end

class QaControllerTest < Test::Unit::TestCase
  fixtures :users, :jobs, :batches, :payers, :sampling_rates, :eob_qas, :job_statuses, :batch_statuses, :qa_statuses, :processor_statuses

  def setup
    @controller = QaController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def login_as(user)
    user = users(user)
    @request.session[:user] = user.id
    return user
  end

  def test_my_job
    login_as(:qa01)
    get :my_job
    assert_not_nil assigns(:job_pages)
    assert_not_nil assigns(:jobs)
  end

  def test_jobs_for_online_users
    login_as(:qa01)
    user_qa = User.create(:userid => 'qa1', :password => 'qa', :role => 'QA', :name => 'QA')
    user_pro = User.create(:userid => 'pro1', :password => 'pro', :role => 'Processor', :name => 'Pro')
    Job.create!(:batch => batches(:batch1), :check_number => 1, :tiff_number => 2, :processor => user_pro, :qa => user_qa, :estimated_eob => 130)
    Job.create!(:batch => batches(:batch1), :check_number => 4, :tiff_number => 3, :processor => user_pro, :qa => user_qa, :estimated_eob => 150)
    post :jobs_for_onlineusers, :id => user_qa.id
    assert_not_nil assigns(:jobs)
    assert_not_nil assigns(:job_pages)
  end

  def test_list_payer
    login_as(:qa01)
    get :list_payer
    assert_not_nil assigns(:payers)
    assert_not_nil assigns(:payer_pages)
    assert_template 'list_payer'
  end

  def test_online_users
    login_as(:qa01)
    get :online_users
    assert_not_nil assigns(:users)
    assert_not_nil assigns(:user_pages)
    assert_template 'online_users'
  end

  def test_eob_complete
    login_as(:qa01)
    payers = {:id => '1'}
    errors = {:type => "Correct"}
    eobs = {:total_fields => '10', :total_incorrect_fields => '9', :account_number => '1', :comment => "first one", :status => 'Verified'}
    first_count = EobQa.count
    eobs = {:total_fields => '10', :total_incorrect_fields => '9', :account_number => '1', :comment => "first one", :status => 'Rejected'}
    post :eob_complete, {:payer => payers, :job => 1, :eob => eobs, :error => errors}
    assert_redirected_to :action => 'verify'
    assert_not_equal(first_count,EobQa.count)
  end

  def test_eob_complete_validation
    login_as(:qa01)
    payers = {:id => '1'}
    errors = {:type => "Correct"}
    eobs = {:total_fields => '8',:total_incorrect_fields => '9', :account_number => '1', :comment => "first one"}
    get :eob_complete, :payer => payers, :job => '1', :eob => eobs, :error => errors
    assert_equal flash[:notice], '"Total Incorrect fields" count exceeds "Total fields" count'
    assert_redirected_to :action => 'verify'
  end

  def test_eob_delete
    login_as(:qa01)
    j = Job.find(1)
    user = User.find(j.processor_id)
    eob_qa_checked = user.eob_qa_checked
    get :clear_verified_eobs, :job => '1'
    j = Job.find(1)
    user = User.find(j.processor_id)
    assert_equal(eob_qa_checked, user.eob_qa_checked)
    assert_redirected_to :action => 'verify'
  end

  def test_complete_job
    login_as(:qa01)
    get :complete_job, :job => '9'
    j = Job.find(9)
    assert_equal flash[:notice], "Job was successfully updated."
    assert_equal("Complete",j.job_status)
    assert_redirected_to :action => 'my_job'
  end

  def test_clear_verified_eobs
    login_as(:qa01)
    get :clear_verified_eobs, :job => '1'
    assert_redirected_to :action => 'verify'
  end

  def test_verify
    login_as(:qa01)
    get :verify, :job => '1'
    assert_not_nil assigns(:user)
    assert_not_nil assigns(:eobs)
    assert_not_nil assigns(:sample_rate)
    assert_template 'verify'
  end

end
