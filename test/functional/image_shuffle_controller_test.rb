require File.dirname(__FILE__)+'/../test_helper'
require 'image_shuffle_controller'
class ImageShuffleControllerTest < ActionController::TestCase
  fixtures :batches, :jobs, :check_informations, :client_images_to_jobs,
           :images_for_jobs
  def setup
    @controller = ImageShuffleController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new  
    @request.env["HTTP_REFERER"] = 'http://localhost:3001/image_shuffle/index'
  end
  
  def ntest_update_image_shuffle
    check1 = check_informations(:one).check_number
    check2 = check_informations(:check9).check_number
    shuffling_start_from_image_name = images_for_jobs(:img_for_jb9).filename
    shuffling_stop_to_image_name = images_for_jobs(:two).filename
    #from fixtures
    jobid_of_shuffled_from_image = client_images_to_jobs(:cl_img_for_jb10).job_id
    jobid_of_shuffled_to_image = client_images_to_jobs(:two).job_id  
    assert_equal(1, jobid_of_shuffled_from_image) 
    assert_equal(1, jobid_of_shuffled_to_image) 
    get :update_image_shuffle, {:check_number => check2, 
                                :image_from => shuffling_start_from_image_name,
                                :image_to => shuffling_stop_to_image_name}
   
    @controller.update_image_shuffle 
    #from test database
    jobid_of_shuffled_from_image = ClientImagesToJob.find(10).job_id
    jobid_of_shuffled_to_image = ClientImagesToJob.find(1).job_id                            
    assert_equal(2, jobid_of_shuffled_from_image) 
    assert_equal(2, jobid_of_shuffled_to_image) 
  end
end
