require File.dirname(__FILE__) + '/../test_helper'

class BatchOldTest < Test::Unit::TestCase
  fixtures :batches, :jobs, :facilities, :users, :clients, :batch_statuses, :job_statuses, :qa_statuses, :processor_statuses

  # List of tests
  # 1. Empty batch create
  # 2. Create with invalid data
  #   - Check with nil batchid
  #   - Check with nil facility
  # 3. Check batch count
  # 4. Check job association
  #   - Batch and job have destroy relationship. When a batch is deleted all its subjobs are deleted.
  # 5. Test the custom get_eob method
  # 6. Test the custom update_method
  #   - The status of the batch should be dependent on the status of its subjobs.
  #     If the status of all the subjobs are completed, then the batch status should be completed.
  #     If the status of any one or more subjobs are not completed, then the batch status should be processing.
  #     If the status of all the subjobs are new, then the batch status should be new.
  #     If the batch status is HLSC Rejected then its status should not overwritten (For batch level rejections)
  #     If anyone of the sub jobs is in HLSC Rejected state and none of the jobs are in Allocated state, the status of the batch should be


  #test empty attribute
  def test_invalid_with_empty_attributes
    batch = Batch.new
    assert !batch.valid?
    assert batch.errors.invalid?(:batchid)
    assert batch.errors.invalid?(:facility)
  end

  #test uniqueness of batchid
  def test_uniqueness_of_batchid
    client1 = Client.create(:name => 'Test Client1',:tat => 12)
    facility1 = Facility.create(:name => "Test facility1",:sitecode => 8234,:client => client1)
    batch1 = Batch.new(:id => 20,
      :batchid=>999,
      :date => Date.today.strftime("%m/%d/%Y"),
      :eob => 30,
      :facility=> facility1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New"
    )
    assert_equal(true, batch1.save, "Save failed!")

    client2 = Client.create(:name => 'Test Client2',:tat => 13)
    facility2 = Facility.create(:name => "Test facility2",:sitecode => 8235,:client => client2)
    batch2 = Batch.new(:id => 21,
      :batchid=>999,
      :date => "2006-10-09",
      :eob => 30,
      :facility=> facility2,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New"
    )
    assert_equal(false, batch2.save)
  end

  #create without batchid
  def test_nil_batchid
    client = Client.create(:name => 'Test Client',:tat => 12)
    facility = Facility.create(:name => "Test facility",:sitecode => 8234,:client => client)
    batch = Batch.new(:id => 20,
      :date => Date.today.strftime("%m/%d/%Y"),
      :eob => 30,
      :facility=> facility,
      :arrival_time => "2006-11-14 15:16:00",
      :target_time  => "2006-11-14 15:16:00",
      :status       => "New"
    )
    assert_equal(false, batch.save)
  end

  #create without facility
  def test_nil_facility
    batch=Batch.new(:id => 9,
      :batchid => 9,
      :date => Date.today.strftime("%m/%d/%Y"),
      :eob => 30,
      :arrival_time => "2006-10-09 15:16:00",
      :target_time  => "2006-10-09 15:16:00",
      :status       => "New"
    )
    assert_invalid(batch, :facility)
  end

  #batch count after inserting
  def test_batch_count_after_inserted
    first_count=Batch.count
    client = Client.create(:name => 'Test Client',:tat => 12)
    facility = Facility.create(:name => "Test facility",:sitecode => 8234,:client => client)
    batch = Batch.new(:id => 20,
      :batchid=>20,
      :date => Date.today.strftime("%m/%d/%Y"),
      :eob => 30,
      :facility=> facility,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now.tomorrow}",
      :status       => "New"
    )
    assert_equal(true, batch.save, "Save failed!")
    second_count=Batch.count
    assert_not_equal(first_count,second_count)
  end

  #batch count after delete
  def test_count_after_delete
    first_count=Batch.count
    Batch.destroy(1)
    assert_not_equal(first_count,Batch.count)
  end


  #job count
  def test_job_association
    first_count=Job.count(:batch_id, :conditions => ["batch_id = ?", 1])
    Job.create!(:batch => Batch.find(1), :tiff_number => 123, :check_number => 121313, :estimated_eob => 12, :count => 50)
    second_count=Job.count(:batch_id, :conditions => ["batch_id = ?", 1])
    assert_not_equal(first_count,second_count)
  end

  def test_batch_jobs
    b = Batch.find_by_id(2)
    j = Job.find_by_batch_id(:all,2)
    assert_equal(b.jobs.count, j.length)
  end

  #job count after parent deleted
  def test_job_association_after_parent_delete
    Job.create(:batch => Batch.find(2), :tiff_number => 123, :check_number => 121313, :count => 12, :estimated_eob => 12)
    first_count=Job.count(:batch_id, :conditions => ["batch_id = ?", 2])
    Batch.destroy(2)
    second_count=Job.count(:batch_id, :conditions => ["batch_id = ?", 2])
    assert_not_equal(first_count,second_count)
  end

  #Test create without data
  def test_create
    @batch = Batch.new
    assert_invalid @batch, :batchid
    assert_invalid @batch, :facility
  end

  #Test all fields
  def test_create_incomplete_data
    @batch1 = Batch.new(:id => 8,
      :batchid => 8,
      :date => "2006-10-09",
      :eob => 30,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New"
    )
    assert_invalid @batch1, :facility
  end

  #test no batch
  def test_no_batch
    batch = Batch.new
    unless batch.valid?
      assert_invalid batch, :facility
    end
  end

  #Test validation of Batch Date
  def test_date_formats_and_ranges
    batch = Batch.new(:id => 20,
      :batchid=>20,
      :date => Date.today.strftime("%m/%d/%Y"),
      :eob => 30,
      :facility=> facilities(:facility1),
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New"
    )

    # Assert the validity of tommorrow, mm/dd/YYYY format, and sixty days prior
    assert_valid(batch, :date, [(Date.today + 1).to_s, Date.today.strftime("%m/%d/%Y"), (Date.today - 60).to_s])
    # Assert the invalidity of three days from today, more than sixty days ago, mm/dd/yy, and yy/mm/dd formats
    assert_invalid(batch, :date, [(Date.today + 4).to_s, (Date.today - 61).to_s, Date.today.strftime("%m/%d/%y"), Date.today.strftime("y/%m/%d")])
  end

  #Test Batch arrival Time validation
  def test_arrival_time_validation
    batch = Batch.new(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now.yesterday}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    batch.valid?
    assert_equal "must be within 6 hours window period from current time", batch.errors.on("arrival_time")
    
    batch = Batch.new(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now.tomorrow}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    batch.valid?
    assert_equal "must be within 6 hours window period from current time", batch.errors.on("arrival_time")
  end

  #Test get completed eobs method
  def test_get_completed_eobs
    batch=Batch.find(2)
    eob=batch.eob
    Job.create(:batch=>batch,:tiff_number=>123,:check_number=>121313,:count=>12, :estimated_eob => 12)
    assert_equal(12, batch.get_completed_eobs)
  end

  #   - The status of the batch should be dependent on the status of its subjobs.
  #     If the status of all the subjobs are either processor complete or QA complete, then the batch status should be completed.
  #     If the status of all the subjobs are new, then the batch status should be new.
  #     If the batch status is HLSC Rejected then its status should not overwritten (For batch level rejections).
  #     If anyone of the sub jobs is in HLSC Rejected state and none of the jobs are in Allocated state, the status of the batch should be  HLSC Rejected.
  #     If anyone of the sub jobs is in Allocated state then the batch is in processing state.

  def test_update_status
    batch = batches(:batch4)
    job_one = Job.create(:batch=>batch,:tiff_number=>1234,:check_number=>12131,:count=>12, :job_status => 'Complete', :estimated_eob => 12)
    job_two  = Job.create(:batch=>batch,:tiff_number=>1231,:check_number=>12135,:count=>12, :job_status => 'Allocated', :estimated_eob => 12)

    # Check for complete
    job_two.job_status = 'Complete'
    job_two.update

    batch.update_status
    assert_equal 'Complete', batch.status
    assert_in_delta(batch.completion_time.to_i, Time.now.to_i,1)

    # Check for processing
    job_one.job_status = 'Processing'
    job_one.update
    batch.update_status
    assert_equal('Processing', batch.status)
    assert_nil batch.completion_time

    # Check for new
    job_one.job_status = 'New'
    job_one.update
    job_two.job_status = 'New'
    job_two.update
    batch.update_status
    assert_equal 'New', batch.status
    assert_nil batch.completion_time

    # one new and one complete
    job_one.job_status = 'New'
    job_one.update
    job_two.job_status = 'Complete'
    job_two.update
    batch.update_status
    assert_equal 'Processing', batch.status
    assert_nil batch.completion_time

    # QA Rejected
    job_one.job_status = 'QA Rejected'
    job_one.update
    job_two.job_status = 'Complete'
    job_two.update
    batch.update_status
    assert_equal 'Processing', batch.status
    assert_nil batch.completion_time

    # one HLSC Rejected and the other Complete
    job_one.job_status = 'HLSC Rejected'
    job_one.update
    job_two.job_status = 'Complete'
    job_two.update
    batch.update_status
    assert_equal 'HLSC Rejected', batch.status
    job_one.job_status = 'Complete'
    job_one.update
    batch.update_status
    assert_equal 'Complete', batch.status

    # All HLSC Verified
    job_one.job_status = 'HLSC Verified'
    job_one.update
    job_two.job_status = 'HLSC Verified'
    job_two.update
    batch.update_status
    assert_equal 'HLSC Verified', batch.status

    # One HLSC Rejected and one processor allocated
    job_one.job_status = 'HLSC Rejected'
    job_one.update
    job_two.job_status = 'Complete'
    job_two.update
    batch.update_status
    assert_equal 'HLSC Rejected', batch.status
  end

  #Test for get_etc function by processor allocation and deallocation
  def test_get_etc_by_processor
		client = Client.create!(:name => 'New Client', :contracted_tat => 12, :tat => 30)
		facility = Facility.create!(:name => 'New Facility', :client => client, :sitecode => '00902')
		processor = User.new(:name => 'gg', :userid => 'gg', :password => 'gg',
      :processing_rate_triad => 10, :processing_rate_others => 15)
		batch = Batch.create!(:batchid 					=> 14567,
      :facility 				=> facility,
      :date 						=> Date.today.strftime("%m/%d/%Y"),
      :arrival_time 		=> "#{Time.now}",
      :target_time  		=> "#{Time.now.tomorrow - 64.minutes}",
      :status       		=> "New",
      :manual_override 	=> false)

		job_new = Job.create!(:batch=>batch,:tiff_number=>1234,
      :check_number=>12131,:count=>12,
      :estimated_eob => 50, :processor => processor,
      :processor_status => 'Processor Allocated',:job_status => 'Processing')
		batch.reload
    batch.expected_completion_time = batch.expected_time
    batch.save
		etc_with_one_job = batch.expected_completion_time

    job_one_more = Job.new(:batch=>batch,:tiff_number=>1231,
      :check_number=>12135,:count=>12,
      :estimated_eob => 50,:processor => processor,
      :processor_status => 'Processor Allocated',:job_status => 'Processing')
		job_one_more.save
		batch.reload
		batch.expected_completion_time = batch.expected_time
    batch.save
		etc_with_two_jobs = batch.expected_completion_time

		assert_not_equal(etc_with_one_job, etc_with_two_jobs)

		job_one_more.processor = nil
		job_one_more.job_status = ''
		job_one_more.update
		batch.reload
		batch.expected_completion_time = batch.expected_time
    batch.save
		etc_after_deallocation = batch.expected_completion_time
    assert_in_delta(etc_after_deallocation, etc_with_one_job, 1, "ETC after deallocation varys by more than 1 second.")
  end

  #Test get_etc function by QA allocation and deallocation
  def test_get_etc_function_by_qa
		batch = Batch.create!( :batchid => 291206,
      :facility => facilities(:facility1),
      :date => Date.today.strftime("%m/%d/%Y"),
      :arrival_time => "#{Time.now}",
      :target_time	=> "#{Time.now.tomorrow - 64.minutes}",
      :status => "New",
      :manual_override => false)

		job_new = Job.create!(:batch=>batch,
      :tiff_number=>1234,:check_number=>12131,
      :count=>12,:estimated_eob => 50,
      :qa_id => 1)
		batch.reload
		batch.expected_completion_time = batch.expected_time
    batch.save
		etc_with_qa = batch.expected_completion_time

    job_one_more = Job.create(:batch=>batch,:tiff_number=>1231,
      :check_number=>12135,:count=>12,
      :estimated_eob => 50,
      :qa_id => 2)
		batch.reload
		batch.expected_completion_time = batch.expected_time
    batch.save
		etc_with_two_jobs = batch.expected_completion_time
  	assert_in_delta etc_with_qa.to_i, etc_with_two_jobs.to_i,1

		job_one_more.qa_id = 1
		job_one_more.update
		batch.reload
		batch.expected_completion_time = batch.expected_time
    batch.save
		etc_after_change_qa = batch.expected_completion_time

		assert_not_equal(etc_with_qa, etc_after_change_qa)

		job_new.qa_id = nil
		job_new.update
		batch.reload
    batch.expected_completion_time = batch.expected_time
    batch.save
		etc_after_deallocate = batch.expected_completion_time
		assert_not_equal(etc_after_deallocate, etc_after_change_qa)
		assert_in_delta etc_after_deallocate.to_i, etc_with_two_jobs.to_i, 1
  end

  #SETUP FOR TESTING GET ETC BY DIFFERENT CLIENT, PROCESSOR AND QA
  def setup_for_etc_test_by_diff_client
    client1 = clients(:Triad)
    facility1 = Facility.create!(:name => "Test facility1",:sitecode => 8234,:client => client1)
		@batch_for_triad_client = Batch.create!(:batchid => 31120601,
      :facility => facility1,
      :date => Date.today.strftime("%m/%d/%Y"),
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now.tomorrow - 64.minutes}",
      :status => "New",
      :manual_override	=> false)

		client2 = clients(:Apria)
    facility2 = Facility.create(:name => "Test facility2",:sitecode => 8294,:client => client2)
		@batch_for_other_client = Batch.create!(:batchid => 31120602,
      :facility => facility2,
      :date => Date.today.strftime("%m/%d/%Y"),
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now.tomorrow - 64.minutes}",
      :status => "New",
      :manual_override	=> false)

		@processor1  = User.create!(:name => 'pro', :userid => 'pro_one', :password => 'pro', :role => 'Processor',
      :processing_rate_triad => 20, :processing_rate_others => 30)
		@processor2  = User.create!(:name => 'anu', :userid => 'anu_one', :password => 'anu', :role => 'Processor',
      :processing_rate_triad => 10, :processing_rate_others => 20)
		@qa          = User.create!(:name => 'anu2', :userid => 'anu2_one', :password => 'anu2', :role => 'QA')

  end


  #Test1
  def test_get_etc_by_other_client_two_same_processor_zero_qa
    setup_for_etc_test_by_diff_client
    @job1 = Job.create!(:batch=> @batch_for_other_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @job2 = Job.create!(:batch => @batch_for_other_client, :tiff_number => 12345,
      :check_number => 121312,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @batch_for_other_client.reload
    time_now = Time.now
    @batch_for_other_client.expected_completion_time = @batch_for_other_client.expected_time
    @batch_for_other_client.save
    expected_time = @batch_for_other_client.expected_completion_time
    assert_in_delta(4.hours, (expected_time - time_now).to_i, 1)
  end

  #Test2
  def test_get_etc_by_other_client_two_same_processor_two_qa
    setup_for_etc_test_by_diff_client
    @job1 = Job.create!(:batch=> @batch_for_other_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12, :qa => @qa,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated', :job_status => 'Processing')
    @job2 = Job.create!(:batch => @batch_for_other_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated', :job_status => 'Processing')
    @batch_for_other_client.reload
    time_now = Time.now
    @batch_for_other_client.expected_completion_time = @batch_for_other_client.expected_time
    @batch_for_other_client.save
    expected_time = @batch_for_other_client.expected_completion_time

    assert_in_delta(10.hours, (expected_time - time_now).to_i, 1)
  end

  #Test3
  def test_get_etc_by_other_client_two_diff_processor_zero_qa
    setup_for_etc_test_by_diff_client
    @job1 = Job.create!(:batch=> @batch_for_other_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @job2 = Job.create!(:batch => @batch_for_other_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor2, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @batch_for_other_client.reload
    time_now = Time.now
    @batch_for_other_client.expected_completion_time = @batch_for_other_client.expected_time
    @batch_for_other_client.save
    expected_time = @batch_for_other_client.expected_completion_time
    assert_in_delta(3.hours, (expected_time - time_now).to_i,1)
  end

  #Test5
  def test_get_etc_by_triad_client_two_same_processor_zero_qa
    setup_for_etc_test_by_diff_client
    @job1 = Job.create!(:batch=> @batch_for_triad_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @job2 = Job.create!(:batch => @batch_for_triad_client, :tiff_number => 12345,
      :check_number => 121312,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @batch_for_triad_client.reload
    time_now = Time.now
    @batch_for_other_client.expected_completion_time = @batch_for_other_client.expected_time
    @batch_for_other_client.save
    expected_time = @batch_for_triad_client.expected_completion_time
    assert_in_delta(6.hours, (expected_time - time_now).to_i, 1)
  end

  #Test6
  def test_get_etc_by_triad_client_two_same_processor_two_qa
    setup_for_etc_test_by_diff_client
    @job1 = Job.create!(:batch=> @batch_for_triad_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12, :qa => @qa,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @job2 = Job.create!(:batch => @batch_for_triad_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @batch_for_triad_client.reload
    time_now = Time.now
    @batch_for_other_client.expected_completion_time = @batch_for_other_client.expected_time
    @batch_for_other_client.save
    expected_time = @batch_for_triad_client.expected_completion_time
    assert_in_delta(12.hours, (expected_time - time_now).to_i, 1)
  end

  #Test7
  def test_get_etc_by_triad_client_two_diff_processor_zero_qa
    setup_for_etc_test_by_diff_client
    @job1 = Job.create!(:batch=> @batch_for_triad_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor1, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @job2 = Job.create!(:batch => @batch_for_triad_client, :tiff_number => 1234,
      :check_number => 12131,:count => 12,
      :estimated_eob => 60, :processor => @processor2, :processor_status => 'Processor Allocated',:job_status => 'Processing')
    @batch_for_triad_client.reload
    time_now = Time.now
    @batch_for_other_client.expected_completion_time = @batch_for_other_client.expected_time
    @batch_for_other_client.save
    expected_time = @batch_for_triad_client.expected_completion_time
    assert_in_delta(6.hours, (expected_time - time_now).to_i, 1)
  end

  def test_statuses_for_batch
		batch = batches(:batch4)
		assert_equal 'New', batch.status
		batch.status = BatchStatus['Processing'].to_s
		batch.update
		assert_equal 'Processing' , batch.status
		batch.status = BatchStatus['new'].to_s
		batch.update
		#batch.status becomes ''(empty string) when new undefined value for status is used.
		assert_equal '', batch.status
  end

  #Test calculating contracter time for hlsc
  def test_contracted_time
    batch = batches(:batch1)
    assert_in_delta(20.hours, (batch.contract_time("HLSC")- Time.now).to_i, 2)
  end

  #Test calculating contracter time
  def test_contracted_time
    batch = batches(:batch1)
    assert_in_delta(12.hours, (batch.contract_time("Supervisor")- Time.now).to_i, 2)
  end

  #Test estimated_eobs method
  def test_estimated_eobs
    batch = Batch.create!(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    Job.create(:batch=>batch, :tiff_number=>1233, :check_number=>1213134, :count=>12, :estimated_eob => 12)
    Job.create(:batch=>batch, :tiff_number=>1234, :check_number=>1213135, :count=>12, :estimated_eob => 12)
    assert_equal(12+12,batch.estimated_eobs)
  end

  #Test complete_check_count method
  def test_complete_check_count
    batch = Batch.create!(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    Job.create(:batch=>batch, :tiff_number=>1223, :check_number=>1213131, :count=>12, :estimated_eob => 12, :job_status => "Processing")
    Job.create(:batch=>batch, :tiff_number=>1224, :check_number=>1213134, :count=>12, :estimated_eob => 12, :job_status => "Complete")
    assert_equal(1,batch.complete_check_count)
    batch = Batch.create!(:id => 81,
      :batchid => 82,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    assert_equal(0,batch.complete_check_count)
  end

  #Test total_check_count method
  def test_total_check_count
    batch = Batch.create!(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    Job.create(:batch=>batch, :tiff_number=>1223, :check_number=>1213131, :count=>12, :estimated_eob => 12, :job_status => "Processing")
    Job.create(:batch=>batch, :tiff_number=>1224, :check_number=>1213134, :count=>12, :estimated_eob => 12, :job_status => "Complete")
    assert_equal(2,batch.total_check_count)
    batch = Batch.create!(:id => 81,
      :batchid => 82,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    assert_equal(0,batch.total_check_count)
  end

  #Test completed_batches method
  def test_completed_batches
    assert_equal(5, (Batch.completed_batches).length)
  end

  #Test completed_batches_payment method
  def test_completed_batches_payment
    assert_equal(3, (Batch.completed_batches_payment).length)
  end

  #Test uncompleted_batches method
  def test_uncompleted_batches
    assert_equal(Batch.find(:all, :conditions => "status != 'Complete' and status != 'HLSC Verified'").length,
      Batch.uncompleted_batches.length)
  end

  #Test uncompleted_batches_payment method
  def test_uncompleted_batches_payment
    assert_equal(4, (Batch.uncompleted_batches_payment).length)
  end

  #Test least_eobs method
  def test_least_eobs
    batch = Batch.create!(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    Job.create(:batch=>batch, :tiff_number=>1223, :check_number=>1213131, :count=>12, :estimated_eob => 12, :job_status => "Processing")
    Job.create(:batch=>batch, :tiff_number=>1224, :check_number=>1213134, :count=>22, :estimated_eob => 12, :job_status => "Complete")
    assert_equal(12, batch.least_eobs)
  end

  #Test facility_for_filter method
  def test_facility_for_filter
    batch = batches(:batch1)
    assert_equal("Apria - Carolinas",batch.facility_for_filter)
  end

  #Test client_for_filter method
  def test_client_for_filter
    batch = batches(:batch1)
    assert_equal("Apria",batch.client_for_filter)
  end
  
  def test_estimated_eobs
    batch = Batch.create!(:id => 80,
      :batchid => 8,
      :date => "#{Time.now}",
      :eob => 30,
      :facility_id => 1,
      :arrival_time => "#{Time.now}",
      :target_time  => "#{Time.now}",
      :status       => "New")
    Job.create(:batch=>batch, :tiff_number=>1223, :check_number=>1213131, :count=>12, :estimated_eob => 12, :job_status => "Processing")
    Job.create(:batch=>batch, :tiff_number=>1224, :check_number=>1213134, :count=>22, :estimated_eob => 12, :job_status => "Complete")
    assert_equal(24, batch.estimated_eobs)
  end    

end
