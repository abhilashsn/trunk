require File.dirname(__FILE__) + '/../test_helper'

class JobTest < ActiveSupport::TestCase
  fixtures :jobs, :check_informations, :micr_line_informations,
    :provider_adjustments, :insurance_payment_eobs, :patient_pay_eobs
  def test_truth
    assert true
  end

  # this test needs to be fixed by the developer and checked in
  def ntest_should_not_be_valid_without_check_number_for_single_tiff_image
    sample_job = jobs(:job1)
    job = Job.new
    job.attributes = sample_job.attributes
    job.check_number = nil
    job.split_parent_job_id = sample_job.id
    job.save
    assert_equal nil, job.errors.on(:check_number)
  end
  
  
  # this test needs to be fixed by the developer and checked in
  def ntest_should_not_be_valid_without_check_number_for_multi_tiff_image
    sample_job = jobs(:job1)
    job = Job.new
    job.attributes = sample_job.attributes
    job.check_number = nil
    job.estimated_eob = 23
    job.pages_from = 1
    job.pages_to = 2
    job.split_parent_job_id = sample_job.id
    job.save
    assert_equal nil,job.errors.on(:check_number)
  end

  def test_should_be_valid_with_check_on_tiff_image
    parent_job = Job.first
    job = Job.new
    job.attributes = parent_job.attributes
    job.check_number = 1000
    job.estimated_eob = 23
    job.split_parent_job_id = parent_job.id
    job.save
    assert job.valid?, job.errors.full_messages.to_s
  end

  def test_should_be_valid_with_check_on_tiff_image
    parent_job = Job.first
    job = Job.new
    job.attributes = parent_job.attributes
    job.check_number = nil
    job.estimated_eob = 23
    job.pages_from = 1
    job.pages_to = 2
    job.split_parent_job_id = parent_job.id
    job.save
    assert job.valid?, job.errors.full_messages.to_s
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as display_check_number.             |
  # Input  : A job without parent_job_id.                                        |
  # Output : check_number from table check_informations.                       |
  # +--------------------------------------------------------------------------+
  def test_display_check_number_for_parent_job
    parent_job = Job.find(222)
    assert_equal('000000',parent_job.display_check_number)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method, named as display_check_number.             |
  # Input  : A Job with parent_job_id.                                         |
  # Output : check_number from table jobs.                                     |
  # +--------------------------------------------------------------------------+
  def test_display_check_number_for_child_job
    child_job = Job.find(225)
    assert_equal('000000_1',child_job.display_check_number)
  end

  def test_estimated_no_of_eobs_for_patpay
    job = jobs(:job_24)
    total_number_of_images = 3
    micr = nil
    check_number = '1234'
    expected_estimation = 1
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end

  def test_estimated_no_of_eobs_when_total_no_of_image_is_zero
    job = jobs(:job_24)
    total_number_of_images = 0
    micr = nil
    check_number = '123456'
    expected_estimation = 1
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end

  def test_estimated_no_of_eobs_when_total_no_of_image_is_nil
    job = jobs(:job_24)
    total_number_of_images = nil
    micr = nil
    check_number = '123456'
    expected_estimation = 1
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end


  def test_estimated_no_of_eobs_when_associated_payer_has_eobs_per_image_value
    job = jobs(:job_24)
    total_number_of_images = 30
    micr = micr_line_informations(:micr_info_3)
    check_number = '123456'
    expected_estimation = 150
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end

  def test_estimated_no_of_eobs_for_an_excluded_job
    job = jobs(:job_25)
    total_number_of_images = 5
    micr = micr_line_informations(:micr_info_3)
    check_number = '123456'
    expected_estimation = 0
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end

  def test_estimated_no_of_eobs_when_there_is_no_payer_associated
    job = jobs(:job_25)
    total_number_of_images = 5
    micr = micr_line_informations(:micr_info_4)
    check_number = '123456'
    expected_estimation = 0
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end

  def test_estimated_no_of_eobs_when_there_is_no_micr_associated
    job = jobs(:job_24)
    total_number_of_images = 5
    micr = nil
    check_number = '123456'
    expected_estimation = 3
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end

  def test_estimated_no_of_eobs_for_correspondence_check
    job = jobs(:job_24)
    total_number_of_images = 5
    micr = nil
    check_number = '0'
    expected_estimation = 1
    obtained_estimation = job.estimated_no_of_eobs(total_number_of_images, micr, check_number)
    assert_equal expected_estimation, obtained_estimation
  end
  
  def test_get_provider_adjustment_amount
    job = jobs(:job_27)
    total_provider_adjustment_amount = job.get_provider_adjustment_amount
    assert_equal(total_provider_adjustment_amount, 250.00)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'get_ids_of_all_child_jobs',                |
  # This is for getting the list of id of all child jobs, belonging to the same|
  # parent as that of the current job. If the job has no parent_job ,          |
  # then it will return an array contains id of current_job.                   |
  # Input: Job has parent_job.                                                 |
  # Output: An array of ids of all child jobs, belonging to the same parent.   |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_get_ids_of_all_child_jobs_for_split_jobs
    job = jobs(:job_225)
    assert_equal([], job.get_ids_of_all_child_jobs)
  end

  # +--------------------------------------------------------------------------+
  # This is for testing the method,'get_ids_of_all_child_jobs',                |
  # This is for getting the list of id of all child jobs, belonging to the same|
  # parent as that of the current job. If the job has no parent_job ,          |
  #  then it will return an array contains id of current_job.                  |
  # Input: Job has no parent_job.                                              |
  # Output: An array contains id of the current job.                           |
  # Author  : Ramya Periyangat                                                 |
  # +--------------------------------------------------------------------------+
  def test_get_ids_of_all_child_jobs_for_normal_job
    job = jobs(:job_222)
    assert_equal([225,229], job.get_ids_of_all_child_jobs)
  end

  def test_get_count_of_blank_eobs_containing_image_numbers_that_of_job
    eobs = []
    job = jobs(:job_312)
    eob_count = job.get_count_of_eobs_containing_image_numbers_that_of_job(eobs)
    assert_equal 0, eob_count
  end

  def test_get_count_of_no_eobs_containing_image_numbers_that_of_job
    eobs = nil
    job = jobs(:job_312)
    eob_count = job.get_count_of_eobs_containing_image_numbers_that_of_job(eobs)
    assert_equal 0, eob_count
  end

  def test_get_count_of_blank_eobs_containing_image_numbers_that_of_job
    eobs = [insurance_payment_eobs(:eob_56), insurance_payment_eobs(:eob_57),
      insurance_payment_eobs(:eob_58)]
    job = jobs(:job_28)
    eob_count = job.get_count_of_eobs_containing_image_numbers_that_of_job(eobs)
    assert_equal 2, eob_count
  end

  def test_eob_count_for_sub_job_with_spanning_eobs
    job = jobs(:job_31)
    eob_count = job.eob_count
    assert_equal 3, eob_count
  end

  def test_eob_count_for_sub_job_with_insurance_eobs
    job = jobs(:job_60)
    eob_count = job.eob_count
    assert_equal 1, eob_count
  end

  def test_eob_count_for_sub_job_with_patpay_eobs
    job = jobs(:job_58)
    eob_count = job.eob_count
    assert_equal 2, eob_count
  end

  def test_eob_count_for_parent_job
    job = jobs(:job_59)
    eob_count = job.eob_count
    assert_equal 0, eob_count
  end

  def test_eob_count_for_normal_job_with_insurance_eobs
    job = jobs(:job_28)
    eob_count = job.eob_count
    assert_equal 2, eob_count
  end

  def test_eob_count_for_normal_job_with_patpay_eobs
    job = jobs(:job_62)
    eob_count = job.eob_count
    assert_equal 1, eob_count
  end

  def test_is_a_parent_job
    parent_job = jobs(:job_61)
    assert_equal true, parent_job.is_a_parent?
  end

  def test_is_not_a_parent_job
    normal_job = jobs(:job_62)
    assert_equal false, normal_job.is_a_parent?

    sub_job = jobs(:job_60)
    assert_equal false, sub_job.is_a_parent?
  end
  
  def test_get_ids_of_all_jobs_for_normal_job
    normal_job = jobs(:job_223)
    assert_equal([223], normal_job.get_ids_of_all_jobs)
  end

  def test_get_ids_of_all_jobs_for_parent_job
    parent_job = jobs(:job_222)
    assert_equal([222,225,229], parent_job.get_ids_of_all_jobs)
  end

  def test_get_ids_of_all_jobs_for_child_job
    child_job = jobs(:job_225)
    assert_equal([222,225,229], child_job.get_ids_of_all_jobs)
  end
end
