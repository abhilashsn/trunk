require File.dirname(__FILE__) + '/../test_helper'

class JobAllocatorTest < ActiveSupport::TestCase
  fixtures :clients, :facilities, :batches, :jobs,
    :check_informations, :users, :facilities_users, :roles, :roles_users

  def test_get_user_ids_in_the_order_of_work_completion
    user_ids = [users(:processor_23).id, users(:processor_24).id,
      users(:processor_25).id]
    expected_user_ids = [24, 25, 23]
    observed_user_ids = JobAllocator.get_user_ids_in_the_order_of_work_completion(user_ids)
    assert_equal expected_user_ids, observed_user_ids
  end

  def test_allocate_job_65_for_user_23
    user_id = 23
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])
    
    job = Job.find(65)
    batch = job.batch
    user = User.find(user_id)
    
    assert_equal user_id, job.processor_id
    assert_equal 'ALLOCATED', job.processor_status
    assert_equal 'PROCESSING', job.job_status

    assert_equal true, user.allocation_status
    
    assert_equal 'PROCESSING', batch.status
    assert_not_nil batch.processing_start_time
    assert_not_nil batch.expected_completion_time
    
    assert_equal user_id, allocator.instance_variable_get("@processor_id")
    assert_equal 65, allocator.instance_variable_get("@job_id")
    assert_equal 53, allocator.instance_variable_get("@batch_id")
  end

  def test_allocate_job_69_for_user_24
    user_id = 24
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    job = Job.find(69)
    batch = job.batch
    user = User.find(user_id)
    
    
    assert_equal user_id, job.processor_id
    assert_equal 'ALLOCATED', job.processor_status
    assert_equal 'PROCESSING', job.job_status

    assert_equal true, user.allocation_status

    assert_equal 'PROCESSING', batch.status
    assert_not_nil batch.processing_start_time
    assert_not_nil batch.expected_completion_time

    assert_equal user_id, allocator.instance_variable_get("@processor_id")
    assert_equal 69, allocator.instance_variable_get("@job_id")
    assert_equal 58, allocator.instance_variable_get("@batch_id")
  end

  def test_allocate_no_job_to_user_26
    user_id = 26
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    user = User.find(user_id)
    assert_equal false, user.allocation_status
    idle_processor = IdleProcessor.find_by_user_id(user_id)
    assert_not_nil idle_processor
  end

  def test_no_allocation_for_offline_user
    user_id = 27
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    user = User.find(user_id)
    assert_equal false, user.allocation_status
    assert_equal nil, allocator.instance_variable_get("@processor_id")
  end

  def test_no_allocation_for_user_which_has_stopped_allocation
    user_id = 28
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    user = User.find(user_id)
    assert_equal false, user.allocation_status
    assert_equal nil, allocator.instance_variable_get("@processor_id")
  end

  def test_no_allocation_for_user_which_has_no_association_with_any_clients
    user_id = 29
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    user = User.find(user_id)
    assert_equal false, user.allocation_status
    assert_equal nil, allocator.instance_variable_get("@processor_id")
  end

  def test_no_allocation_for_user_which_is_not_eligible_for_auto_allocation_for_any_client
    user_id = 30
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    user = User.find(user_id)
    assert_equal false, user.allocation_status
    assert_equal nil, allocator.instance_variable_get("@processor_id")
  end

  def test_no_allocation_for_occupied_user
    user_id = 31
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    assert_equal nil, allocator.instance_variable_get("@processor_id")
  end

  def test_no_allocation_for_user_when_there_is_no_batch_with_allocation_enabled
    user_id = 32
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])

    user = User.find(user_id)
    assert_equal false, user.allocation_status
    
    assert_equal user_id, allocator.instance_variable_get("@processor_id")
    assert_equal nil, allocator.instance_variable_get("@job_id")
    assert_equal nil, allocator.instance_variable_get("@batch_id")

    idle_processor = IdleProcessor.find_by_user_id(user_id)
    assert_not_nil idle_processor
  end

  def test_no_allocation_for_user_when_there_is_no_eligible_job
    user_id = 25
    allocator = JobAllocator::AutoJobAllocator.new
    allocator.allocate_facility_wise([user_id])
    
    user = User.find(user_id)
    assert_equal false, user.allocation_status

    assert_equal user_id, allocator.instance_variable_get("@processor_id")
    assert_equal nil, allocator.instance_variable_get("@job_id")
    assert_equal nil, allocator.instance_variable_get("@batch_id")

    idle_processor = IdleProcessor.find_by_user_id(user_id)
    assert_not_nil idle_processor
  end  

end