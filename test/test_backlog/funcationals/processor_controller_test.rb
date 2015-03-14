require File.dirname(__FILE__) + '/../test_helper'
require 'processor_controller'

# Re-raise errors caught by the controller.
class ProcessorController; def rescue_action(e) raise e end; end

class ProcessorControllerTest < Test::Unit::TestCase
  fixtures :users, :jobs, :batches, :job_statuses, :qa_statuses, :processor_statuses, :batch_statuses

  def setup
    @controller = ProcessorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def login_as(user)
    user = users(user)
    @request.session[:user] = user.id
    return user
  end

  def test_my_job
    login_as(:processor01)
    get :my_job
    assert_not_nil assigns(:job_pages)
    assert_not_nil assigns(:jobs)
    assert_template 'my_job'
  end

  def test_list_payer
    login_as(:processor01)
    get :list_payer
    assert_not_nil assigns(:payers)
    assert_not_nil assigns(:payer_pages)
  end

  def test_complete_job_count_nill
    login_as(:processor01)
    get :complete_job, :id => '1', :job => ''
    assert_equal flash[:notice], "EOB Count Incorrect"
    assert_redirected_to :action => 'my_job'
  end

  def test_complete_job_qa_not_nill
    login_as(:processor01)
    job1 = {:count => '10', :check_number => '9098'}

    #QA with status QA Complete
    post :complete_job, :id => 6, :job => job1
    j = Job.find(6)
  	assert_equal flash[:notice], "Job was sucessfully updated"
  	assert_equal("Complete",j.job_status)
	  assert_redirected_to :action => 'my_job'

    #Qa with status QA Rejected
	  post :complete_job, :id => '7', :job => job1
	  j =Job.find(7)
	  assert_equal("QA Allocated",j.qa_status)
	  assert_equal flash[:notice], "Job was sucessfully updated"
	  assert_redirected_to :action => 'my_job'

    #Without QA
	  post :complete_job, :id => '8', :job => job1
	  j = Job.find(8)
    assert_equal("Complete",j.job_status)
    assert_equal flash[:notice], "Job was sucessfully updated"
    assert_redirected_to :action => 'my_job'
  end

end
