require File.dirname(__FILE__) + '/../test_helper'
class UserTest < ActiveSupport::TestCase
  include AuthenticatedTestHelper
  fixtures :users, :roles, :roles_users, :clients_users, :clients, :jobs
  
  def test_get_online_user_names_for_role
    assert_equal(["quentin", "RTY", "DEF", "LMN", "PQR", "UVW", "ABC", "ZYX", "UIO"], User.get_online_user_names_for_role('processor'),
      message="Should return Online Processor's name" )
    assert_equal(['QA1'], User.get_online_user_names_for_role('qa'),
      message="Should return Online QA's name" )
  end
  
  def test_authentication_for_is_deleted_0
    u = User.authenticate(users(:undeleted_user).login,"GOOD*123")
    assert_not_nil (u)
  end
  
  def test_authentication_for_is_deleted_nil
    u = User.authenticate(users(:is_deleted_nil_user).login,"GOOD*123")
    assert_not_nil (u)
  end
  
  def test_authentication_for_is_deleted_1
    u = User.authenticate(users(:deleted_user).login,"GOOD*123")
    assert_nil (u)
  end
  
  def test_for_processor_to_have_jobs_assigned_but_not_completed
    processor = users(:processor_12)
    count_of_jobs = processor.count_of_jobs_processing
    assert_equal 1, count_of_jobs
  end
  
  def test_for_processor_to_have_jobs_assigned_but_completed
    processor = users(:processor_13)
    count_of_jobs = processor.count_of_jobs_processing
    assert_equal 0, count_of_jobs
  end
  
  def test_for_processor_to_have_no_jobs_assigned
    processor = users(:processor_14)
    count_of_jobs = processor.count_of_jobs_processing
    assert_equal 0, count_of_jobs
  end
  
  def test_update_of_allocation_status_for_a_processor_having_no_jobs_and_completion_time
    processor = users(:processor_14)
    updated_processor = processor.update_processing_attributes(nil, nil)
    assert_equal false, updated_processor.allocation_status
    assert_not_nil updated_processor.last_job_completed_at
  end
  
  def test_do_not_update_of_allocation_status_for_a_processor_having_jobs_and_allocation_status_as_true_and_completion_time
    processor = users(:processor_16)
    updated_processor = processor.update_processing_attributes(nil, nil)
    assert_equal true, updated_processor.allocation_status
    assert_not_nil updated_processor.last_job_completed_at
  end

  def test_do_not_update_of_allocation_status_for_a_processor_having_jobs_and_allocation_status_as_nil_and_completion_time
    processor = users(:processor_12)
    updated_processor = processor.update_processing_attributes(nil, nil)
    assert_nil updated_processor.allocation_status
    assert_not_nil updated_processor.last_job_completed_at
  end
  
  def test_do_not_update_allocation_status_for_a_qa_processor_and_update_on_completion_time
    processor = users(:qa_15)
    updated_processor = processor.update_processing_attributes(nil, nil)
    assert_equal true , updated_processor.allocation_status
    assert_not_nil updated_processor.last_job_completed_at
  end
  
  def test_first_login_time_for_day
    processor = users(:processor_20)
    first_login_time_for_day = processor.first_login_time_for_day
    assert_equal Date.today.strftime('%Y-%m-%d') , first_login_time_for_day.strftime('%Y-%m-%d')
  end
  
  def test_last_logout_time_for_day
    processor = users(:processor_20)
    last_logout_time_for_day = processor.last_logout_time_for_day
    assert_equal Date.today.strftime('%Y-%m-%d') , last_logout_time_for_day.strftime('%Y-%m-%d')
  end
  
end

