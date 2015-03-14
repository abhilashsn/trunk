require File.dirname(__FILE__) + '/../test_helper'

class BatchTest < ActiveSupport::TestCase
  fixtures :batches, :jobs, :check_informations, :payers

  def test_alias_attribute 
    assert_equal(batches(:batch_107).date, batches(:batch_107).bank_deposit_date )
  end
  
  def test_total_check_amount_for_undeleted_checks
    batch = batches(:batch_02)
    j = batch.jobs
    check_infs = []
    
    j.each do |a_job|
      check_infs << a_job.check_informations      
    end
    assert_equal(2,batch.jobs.count)
    assert_equal(2,check_infs.count)
    assert_equal(200,batch.total_check_amount)
  end

  # This test is replaced as test_total_check_amount. Because deleting a check is irrelevant.
  # def test_total_check_amount_for_deleted_checks
  
  def test_total_check_amount    
    batch = batches(:batch_01)
    j = batch.jobs
    check_infs = []
    
    j.each do |a_job|
      check_infs << a_job.check_informations      
    end
    assert_equal(4,batch.jobs.count)
    assert_equal(4,check_infs.count)
    assert_equal(400,batch.total_check_amount)
  end
  
  def test_incomplete?
    complete_batch = batches(:batch1)  
    ready_batch = batches(:batch7)
    incomplete_batch = batches(:batch5)
    assert_equal(true, complete_batch.incomplete?, message = "Should return true")
    assert_equal(false, ready_batch.incomplete?, message = "Should return false")
    assert_equal(true, incomplete_batch.incomplete?, message = "Should return true")
  end

  def test_count_of_urgent_batches_for_payer_with_current_time_greater_than_threshold_time
    payer = payers(:payer_29)
    count = Batch.count_of_urgent_batches_for_payer(payer.id, 1)
    assert_equal 1, count
  end

  def test_count_of_urgent_batches_for_payer_with_current_time_equal_to_threshold_time
    payer = payers(:payer_31)
    count = Batch.count_of_urgent_batches_for_payer(payer.id, 1)
    assert_equal 1, count
  end

  def test_count_of_urgent_batches_for_payer_with_current_time_less_than_threshold_time
    payer = payers(:payer_32)
    count = Batch.count_of_urgent_batches_for_payer(payer.id, 1)
    assert_equal 0, count
  end

  def test_add_to_facility_wise_allocation_queue
    batch_ids = [batches(:batch_32).id, batches(:batch_33).id]
    number_of_updated_records = Batch.add_to_facility_wise_allocation_queue(batch_ids)
    assert_equal 2, number_of_updated_records

    batches = Batch.find(batch_ids)
    batch_1, batch_2 = batches[0], batches[1]
    assert_equal true, batch_1.facility_wise_auto_allocation_enabled
    assert_equal false, batch_1.payer_wise_auto_allocation_enabled
    assert_equal true, batch_2.facility_wise_auto_allocation_enabled
    assert_equal false, batch_2.payer_wise_auto_allocation_enabled
  end

  def test_add_to_payer_wise_allocation_queue
    batch_ids = [batches(:batch_34).id, batches(:batch_35).id]
    number_of_updated_records = Batch.add_to_payer_wise_allocation_queue(batch_ids)
    assert_equal 2, number_of_updated_records

    batches = Batch.find(batch_ids)
    batch_1, batch_2 = batches[0], batches[1]
    assert_equal false, batch_1.facility_wise_auto_allocation_enabled
    assert_equal true, batch_1.payer_wise_auto_allocation_enabled
    assert_equal false, batch_2.facility_wise_auto_allocation_enabled
    assert_equal true, batch_2.payer_wise_auto_allocation_enabled
  end

  def test_remove_from_allocation_queue
    batch_ids = [batches(:batch_34).id, batches(:batch_35).id]
    number_of_updated_records = Batch.remove_from_allocation_queue(batch_ids)
    assert_equal 2, number_of_updated_records

    batches = Batch.find(batch_ids)
    batch_1, batch_2 = batches[0], batches[1]
    assert_equal false, batch_1.facility_wise_auto_allocation_enabled
    assert_equal false, batch_1.payer_wise_auto_allocation_enabled
    assert_equal false, batch_2.facility_wise_auto_allocation_enabled
    assert_equal false, batch_2.payer_wise_auto_allocation_enabled
  end

  def test_change_status_to_output_ready
    batch_ids = [batches(:batch_35).id, batches(:batch_36).id, batches(:batch_37).id]
    number_of_updated_records = Batch.change_status_to_output_ready(batch_ids)
    assert_equal 2, number_of_updated_records

    batches = Batch.find(batch_ids)
    batch_1, batch_2, batch_3 = batches[0], batches[1], batches[2]
    assert_equal BatchStatus::NEW, batch_1.status
    assert_equal BatchStatus::OUTPUT_READY, batch_2.status
    assert_equal BatchStatus::OUTPUT_READY, batch_3.status
  end

  def test_batch_internal_tat_with_giving_client_internal_tat
    batch = batches(:batch_32)
    client_internal_tat = 24
    batch_internal_tat = batch.batch_internal_tat(client_internal_tat)
    assert_equal '2010-02-15 00:00:00', batch_internal_tat.strftime('%Y-%m-%d %H:%M:%S')
  end

  def test_batch_internal_tat_with_out_giving_client_internal_tat
    batch = batches(:batch_32)
    batch_internal_tat = batch.batch_internal_tat(nil)
    assert_equal '2010-02-15 00:00:00', batch_internal_tat.strftime('%Y-%m-%d %H:%M:%S')
  end

  def test_batch_client_tat_with_giving_client_tat
    batch = batches(:batch_32)
    client_tat = 48
    batch_tat = batch.batch_client_tat(client_tat)
    assert_equal '2010-02-16 00:00:00', batch_tat.strftime('%Y-%m-%d %H:%M:%S')
  end

  def test_batch_internal_tat_with_out_giving_client_tat
    batch = batches(:batch_32)
    batch_tat = batch.batch_client_tat(nil)
    assert_equal '2010-02-16 00:00:00', batch_tat.strftime('%Y-%m-%d %H:%M:%S')
  end
  
  def test_batch_facility_tat_with_giving_facility_tat
    batch = batches(:batch_32)
    facility_tat = 48
    batch_tat = batch.batch_facility_tat(facility_tat)
    assert_equal '2010-02-16 00:00:00', batch_tat.strftime('%Y-%m-%d %H:%M:%S')
  end

  def test_manual_allocation_type
    batch = batches(:batch_32)
    expected_allocation_type = 'Manual'
    observed_allocation_type = batch.allocation_type
    assert_equal expected_allocation_type, observed_allocation_type
  end

  def test_payer_wise_allocation_type
    batch = batches(:batch_33)
    expected_allocation_type = 'Payer Wise'
    observed_allocation_type = batch.allocation_type
    assert_equal expected_allocation_type, observed_allocation_type
  end

  def test_facility_wise_allocation_type
    batch = batches(:batch_35)
    expected_allocation_type = 'Facility Wise'
    observed_allocation_type = batch.allocation_type
    assert_equal expected_allocation_type, observed_allocation_type
  end

  def test_should_set_qa_status_to_completed_even_if_some_jobs_not_allocated_to_qa
    require File.join(File.dirname(__FILE__), '..', 'test_helper')
    batch = batches(:completed_batch)
    batch.set_qa_status
    assert_equal QaStatus::COMPLETED, batch.qa_status
  end

  def test_should_set_qa_status_to_processing_even_if_some_jobs_are_allocated_to_qa
    batch = batches(:qa_in_progress_batch)
    batch.set_qa_status
    assert_equal QaStatus::PROCESSING, batch.qa_status
  end

  def test_should_set_qa_status_to_allocated_even_if_some_jobs_not_allocated_to_qa
    batch = batches(:qa_allocated_batch)
    batch.set_qa_status
    assert_equal QaStatus::ALLOCATED, batch.qa_status
  end

  def test_should_not_set_qa_status_to_completed_when_jobs_are_allocated_to_qa
    batch = batches(:qa_partially_completed_batch)
    batch.set_qa_status
    assert_not_equal QaStatus::COMPLETED, batch.qa_status
    assert_equal QaStatus::ALLOCATED, batch.qa_status
  end

  def test_should_set_qa_status_to_new_when_all_jobs_are_in_new_qa_status
    batch = batches(:qa_unallocated_batch)
    batch.set_qa_status
    assert_equal QaStatus::NEW, batch.qa_status
  end

  def test_should_not_set_qa_status_to_new_when_all_jobs_are_not_in_new_qa_status
    batch = batches(:qa_allocated_batch)
    batch.set_qa_status
    assert_not_equal QaStatus::NEW, batch.qa_status
  end
  
  # Tests to check the status set for batches.
  # conditions for setting the batch status were defined in
  # update_status method in batch.rb
  def test_set_batch_status_when_all_jobs_completed
    batch = batches(:batch45)
    batch.update_status
    assert_equal BatchStatus::OUTPUT_READY, batch.status
  end
  
  def test_set_batch_status_when_all_jobs_incompleted
    batch = batches(:batch46)
    batch.update_status
    assert_equal BatchStatus::OUTPUT_READY, batch.status
  end
  
  def test_set_batch_status_when_all_jobs_processing
    batch = batches(:batch47)
    batch.update_status
    assert_equal BatchStatus::PROCESSING, batch.status
  end
  
  def test_set_batch_status_when_all_jobs_completed_and_qa_status_allocated
    batch = batches(:batch48)
    batch.update_status
    assert_equal BatchStatus::COMPLETED, batch.status
  end
  
  def test_set_batch_status_when_all_jobs_completed_and_qa_status_new
    batch = batches(:batch49)
    batch.update_status
    assert_equal BatchStatus::COMPLETED, batch.status
  end
  
  def test_set_batch_status_when_all_jobs_new
    batch = batches(:batch50)
    batch.update_status
    assert_equal BatchStatus::NEW, batch.status
  end
  
  # testing the number of jobs qualified for setting the batch status as 'OUTPUT_READY'
  def test_get_output_ready_jobs
    batch1 = batches(:batch45)
    batch2 = batches(:batch46)
    batch3 = batches(:batch47)
    batch4 = batches(:batch48)
    batch5 = batches(:batch49)
    final_jobs1 = batch1.get_output_ready_jobs(batch1.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED, QaStatus::COMPLETED)
    final_jobs2 = batch2.get_output_ready_jobs(batch2.jobs, JobStatus::INCOMPLETED, 
      ProcessorStatus::INCOMPLETED, QaStatus::INCOMPLETED)
    final_jobs3 = batch3.get_output_ready_jobs(batch3.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED, QaStatus::COMPLETED)
    final_jobs4 = batch4.get_output_ready_jobs(batch4.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED, QaStatus::COMPLETED)
    final_jobs5 = batch5.get_output_ready_jobs(batch5.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED, QaStatus::COMPLETED)
    assert_equal 2, final_jobs1.size
    assert_equal 1, final_jobs2.size
    assert_equal 0, final_jobs3.size
    assert_equal 0, final_jobs4.size
    assert_equal 0, final_jobs5.size
  end
  
  # testing the number of jobs qualified for setting the batch status as 'COMPLETED'
  def test_get_complete_jobs
    batch1 = batches(:batch47)
    batch2 = batches(:batch48)
    batch3 = batches(:batch49)
    batch4 = batches(:batch50)
    batch5 = batches(:batch51)
    final_jobs1 = batch1.get_complete_jobs(batch1.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED)
    final_jobs2 = batch2.get_complete_jobs(batch2.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED)
    final_jobs3 = batch3.get_complete_jobs(batch3.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED)
    final_jobs4 = batch4.get_complete_jobs(batch4.jobs, JobStatus::COMPLETED, 
      ProcessorStatus::COMPLETED)
    final_jobs5 = batch5.get_complete_jobs(batch5.jobs, JobStatus::INCOMPLETED, 
      ProcessorStatus::INCOMPLETED)
    assert_equal 0, final_jobs1.size
    assert_equal 1, final_jobs2.size
    assert_equal 1, final_jobs3.size
    assert_equal 0, final_jobs4.size
    assert_equal 2, final_jobs5.size
  end

end
