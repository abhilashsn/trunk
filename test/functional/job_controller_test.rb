require File.dirname(__FILE__) + '/../test_helper'
require 'admin/job_controller'

# Re-raise errors caught by the controller.
class Admin::JobController; def rescue_action(e) raise e end; end

class Admin::JobControllerTest < ActionController::TestCase
  fixtures :jobs, :users, :facilities, :batches, :micr_line_informations,
    :check_informations, :client_images_to_jobs, :roles, :roles_users
  
  def setup
    @controller = Admin::JobController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new 
    
    @request.env['HTTP_REFERER'] = 'http://localhost:3001/sessions/new'

  end

  def ntest_create_job_for_single_page_image
    my_get = get :create_job, 
      {:job => Hash["id","1234","batch_id","56","split_parent_job_id","9874","check_number","33333"],
      :check_information => Hash["check_number","33333","check_amount","100"],
      :micr_line_information => Hash["payer_account_number","7676","aba_routing_number","8787"]}, {}
    @controller.expects(:save_job_with_single_page_image)
    @controller.expects(:redirect_to_prev_page)
    my_get = @controller.create_job
    assert_redirected_to 'http://localhost:3001/sessions/new'
  end
  
  def ntest_create_job_for_multiple_page_image
    my_get = get :create_job, 
      {:job => Hash["id","1234","batch_id","56","split_parent_job_id","9874","check_number","33333"],
      :check_information => Hash["check_number","33333","check_amount","100"],
      :micr_line_information => Hash["payer_account_number","7676","aba_routing_number","8787"]}, {}
    @controller.expects(:save_job_with_single_page_image)
    @controller.expects(:redirect_to_prev_page)
    my_get = @controller.create_job
    assert_redirected_to 'http://localhost:3001/sessions/new'
  end

  def ntest_create
    login_as(:gs)
    @request.session[:batch] = batches(:batch2).id
    post :create, :job => {:check_number => 111, :tiff_number => 222, :estimated_eob => 10}
    assert_redirected_to :action => 'list'
    assert_equal(flash[:notice], 'Job was successfully created.')
  end
  
  def test_for_manual_split_job_for_multipage
    job_ids = [jobs(:job1).id]
    get :manual_split_job, {:jobs => job_ids, :job_split_count => 2}
    @controller.manual_split_job
    assert_equal(5, @controller.instance_variable_get("@total_no_of_images"))
    assert_equal(2, @controller.instance_variable_get("@no_of_jobs_with_exact_no_of_images"))
    assert_equal(1, @controller.instance_variable_get("@no_of_jobs_with_not_exact_no_of_images"))
    assert_equal(["--","quentin", "RTY", "DEF", "LMN", "PQR", "UVW", "ABC", "ZYX", "UIO"], @controller.instance_variable_get("@processors"))
    assert_equal(["--","QA1"], @controller.instance_variable_get("@qas"))
  end
  
  def test_for_manual_split_job_for_singlepage
    job_ids = [jobs(:job3).id]
    get :manual_split_job, {:jobs => job_ids, :job_split_count => 2}
    @controller.manual_split_job
    assert_equal(3, @controller.instance_variable_get("@total_no_of_images"))
    assert_equal(1, @controller.instance_variable_get("@no_of_jobs_with_exact_no_of_images"))
    assert_equal(1, @controller.instance_variable_get("@no_of_jobs_with_not_exact_no_of_images"))
    assert_equal(["--","quentin", "RTY", "DEF", "LMN", "PQR", "UVW", "ABC", "ZYX", "UIO"], @controller.instance_variable_get("@processors"))
    assert_equal(["--","QA1"], @controller.instance_variable_get("@qas"))
  end

  def test_eob_count_value
    job_id = jobs(:job_88).id
    get :edit_micr, {:id => job_id, :eob_count => 5}
    @controller.edit_micr
    assert_equal("5", @controller.instance_variable_get("@eob_count"))
  end
  
  def test_update_micr_with_update_micr_record_condition
    job_id = jobs(:job_89).id
    @controller.expects(:prepare).returns(micr_line_informations(:micr_info_157))
    @controller.expects(:hyphen_absent?).returns(false)
    @controller.expects(:valid_corr_check_number?).returns(false)
    get :update_micr, {:micr_line_information => true, 
      :micr_line_information_aba_routing_number => "223556789",
      :micr_line_information_payer_account_number => "223",
      :id => job_id}
    @controller.instance_variable_set("@micr_line_info", micr_line_informations(:micr_info_157))
    @controller.update_micr
    assert_equal(157, @controller.instance_variable_get("@micr_line_info").id)
  end
  
  def test_update_micr_with_change_micr_reference_condition
    job_id = jobs(:job_91).id
    @controller.expects(:prepare).returns(micr_line_informations(:micr_info_159))
    @controller.expects(:hyphen_absent?).returns(true)
    @controller.expects(:valid_corr_check_number?).returns(false)
    get :update_micr, {:micr_line_information => true, 
      :micr_line_information_aba_routing_number => "222222222",
      :micr_line_information_payer_account_number => "555",
      :id => job_id}
    @controller.instance_variable_set("@micr_line_info", micr_line_informations(:micr_info_159))
    @controller.update_micr
    assert_equal("222222222", @controller.instance_variable_get("@micr_line_info").aba_routing_number)
    assert_equal("555", @controller.instance_variable_get("@micr_line_info").payer_account_number)
  end
  
  
 private
  
 def test_remove_file_extension
    filename_with_extension = @controller.remove_file_extension("d4113800.001.tif")
    filename_without_extension = @controller.remove_file_extension("d4113800.001")
    assert_equal("d4113800.001", filename_with_extension)
    assert_equal("d4113800.001", filename_without_extension)
  end
  
  def test_construct_job_hash
     jobs = [jobs(:job1)]
     job_hash = Hash.new
     jobs.each {|job|
        job.parent_job_id.blank? ? parent_id = job.id : parent_id = job.parent_job_id
        job_hash["#{parent_id}_#{job.id}"] = job
    }       
    
  end
    
end
