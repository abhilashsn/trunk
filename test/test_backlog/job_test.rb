require File.dirname(__FILE__) + '/../test_helper'

class JobTest < Test::Unit::TestCase
  fixtures :jobs, :batches
  
  # List of tests
  # 1. Empty job create 
  # 2. Create with invalid data
  #   - Check with nil check number
  # 3. Check job count when we created and distroy
  # 4.Check the range of Estimated EOB
  
  #Blank job
  def test_blank_job
    job=Job.new
    assert_equal(false,job.save)
  end
  
  # Requires check no.
  def test_creation_without_check
    new_job = Job.new(:job_status => "New", :batch => Batch.find(1))
    assert !new_job.valid?
    assert_equal(false, new_job.save)
  end
    
    # Does not require TIFF no.
  def test_creation_without_tiff
    new_job = Job.new(:check_number => 12345, :job_status => "New", :batch => Batch.find(1), :estimated_eob => 12)
    assert new_job.valid?
    assert_equal(new_job.save,true)
  end
  
  #Job count
  def test_job_count
    first_count=Job.count
    new_job = Job.create(:id=>20,:check_number => 12345, :job_status => "New", :batch => Batch.find(1), :estimated_eob => 12)
    second_count=Job.count
    assert_not_equal(first_count,second_count)
    Job.destroy(1)
    assert_equal(first_count,Job.count)
  end
  
  #Job with estimated eob less then 1
  def test_estimated_eob
    first_count=Job.count
    new_job = Job.create(:id=>20,:check_number => 12345, :job_status => "New", :batch => Batch.find(1), :estimated_eob => 0)
    second_count=Job.count
    assert_equal(first_count,second_count)
  end 
  
  def test_processor_complete_shift
    j = Job.new
    assert_equal('Undefined', j.processor_complete_shift)
    
    j.processor_status = "Processor Complete"
  
    j.processor_flag_time = Time.local(2007, 10, 30, 5, 30)
    assert_equal("Afternoon", j.processor_complete_shift)
    
    j.processor_flag_time = j.processor_flag_time + 8.hours 
    assert_equal("Evening", j.processor_complete_shift)    
    
    j.processor_flag_time = j.processor_flag_time + 8.hours 
    assert_equal("Morning", j.processor_complete_shift)
  end
   
end
