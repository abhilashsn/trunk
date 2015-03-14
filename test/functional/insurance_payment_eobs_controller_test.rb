require File.dirname(__FILE__)+'/../test_helper'
require 'insurance_payment_eobs_controller'
require 'mocha/setup'

class InsurancePaymentEobsControllerTest < ActionController::TestCase
  
  include AuthenticatedTestHelper
  fixtures :users, :roles, :roles_users, :clients, :jobs , 
    :check_informations, :batches, :facilities, :insurance_payment_eobs,
    :reason_codes, :reason_codes_jobs
  
 
  def setup
    @controller = InsurancePaymentEobsController.new
    @session   = ActionController::TestSession.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def teardown
    #    @session.clear
  end
  
  def test_get_check_information_check_info_not_blank    
    my_session = {:job_id => jobs(:job13).id}
    assert_not_nil (get :get_check_information, {}, my_session)
  end
  #  
  def test_get_check_information_check_info_blank
    my_session = {:job_id => jobs(:job14).id}
    assert_not_nil (get :get_check_information, {}, my_session)
  end
  #  
  def test_get_eob_type_info_job_session_tab_not_blank
    my_session1 = {:job_id => jobs(:job13).id,:tab => "insurance_pay"}
    my_get = get :eob_type, {}, my_session1
    
    assert_not_nil (my_get)
    assert_equal("Insurance",assigns(:eob_type))
  end
  
  def test_get_eob_type_info_job_session_tab_not_blank
    my_session1 = {:job_id => jobs(:job13).id,:tab => "patient_pay"}
    my_get = get :eob_type, {}, my_session1
    
    assert_not_nil (my_get)
    assert_equal("Patient",assigns(:eob_type))   
    
  end 
  
  def ntest_get_mode_for_qa
    my_session1 = {:job_id => jobs(:job13).id}
    mode = get :get_mode, {}, my_session1
    @controller.expects(:current_user).returns(remittors(:qa_person))
    mode = @controller.get_mode
    assert_equal("edit",mode)
  end
  
  
  def test_get_mode_for_processor
    
    my_session1 = {:job_id => jobs(:job13).id}
    mode = get :get_mode, {}, my_session1
    @controller.expects(:current_user).returns(users(:sunil))
    mode = @controller.get_mode
    assert_equal("new",mode)
  end
  
  def ntest_process_edit
    my_session1 = {:job_id => jobs(:job13).id}
    mode = get :process_edit, {}, my_session1

    insur_eobs = @controller.process_edit
    assert_not_nil (insur_eobs)
  end

  #  def test_mpi_search
  #     my_session1 = {:job_id => jobs(:job13).id,:tab => "insurance_pay"}
  #     my_params1 = {:patient_no=>"000074189747AAA28004"}
  #     mpi_results = get(:mpi_search,my_params1, my_session1,{})
  #     mpi_results = @controller.mpi_search
  #     assert_equal("000074189747AAA28004",mpi_results[0].patient_account_number)
  #
  #  end

  def ntest_mpi_search_not_search_archived_data
    ClaimInformation.expects(:search).returns(claim_informations(:five))
    my_session1 = {:job_id => jobs(:job13).id,:tab => "insurance_pay"}
    my_params1 = {:patient_no=>"123456"}
    mpi_results = get(:mpi_search,my_params1, my_session1,{})
    mpi_results = @controller.mpi_search
    assert_equal([],mpi_results)
  end

  def do_not_test_claimqa
    get :claimqa, {:batch_id => batches(:batch_for_rumc).id, :check_number => 999999,
      :image_number => 1,  :job_id => jobs(:job_56).id, :mode => 'CompletedEOB'}, {:login => users(:sunil).id}
    assert_select "input[id=amount_so_far][value=#{@controller.instance_variable_get("@total_amount") +
    @controller.instance_variable_get("@total_charge") + check_informations(:check8).provider_adjustment_amount}]"
  end
   
  def do_not_test_show_eob_grid
    get :show_eob_grid, {:batch_id => batches(:batch_for_rumc).id, :check_number => 999999,
      :job_id => jobs(:job_56).id}, {:job_id=> jobs(:job_56).id, :login => users(:sunil).id, :batch_id => batches(:batch_for_rumc).id }
    assert_select "input[id=payer_tin_id][value=#{facilities(:facility_rumc).default_insurance_payer_tin}]"
  end
 
  def test_auto_complete_for_test_adjustment_code_with_apostrophe
    adjustment_desc = {
      "adjustment_desc" => "THE MEMBER'S COVERAGE WAS NOT IN EFFECT ON THE DATE THE SERVICE"
    }
    coinsurance_desc = {
      "adjustment_desc" => adjustment_desc
    }
      
    @request.cookies['reasoncode'] = CGI::Cookie.new('reasoncode', 'CO')
      
    get :auto_complete_for_coinsurance_desc_adjustment_desc,
      {:coinsurance_desc => coinsurance_desc},
      {:job_id => jobs(:job1)}, {}
      
    @controller.expects(:render)
      
    assert_nothing_raised(Mysql::Error) do
      @controller.auto_complete_for_coinsurance_desc_adjustment_desc
    end
  end
  
  
  def test_auto_complete_for_test_adjustment_code_without_apostrophe
    adjustment_desc = {
      "adjustment_desc" => "my_description"
    }
    coinsurance_desc = {
      "adjustment_desc" => adjustment_desc
    }
      
    @request.cookies['reasoncode'] = CGI::Cookie.new('reasoncode', 'CO')
      
    get :auto_complete_for_coinsurance_desc_adjustment_desc,
      {:coinsurance_desc => coinsurance_desc},
      {:job_id => jobs(:job1)}, {}
      
    @controller.expects(:render)
      
    assert_nothing_raised(Mysql::Error) do
      @controller.auto_complete_for_coinsurance_desc_adjustment_desc
    end
  end
  
   
  def test_auto_complete_for_test_noncovered_adjustment_code_with_apostrophe
    adjustment_code = {
      "adjustment_code" => "NCO"
    }
    noncovered = {
      "adjustment_code" => adjustment_code
    }
      
    @request.cookies['reasoncode'] = CGI::Cookie.new('reasoncode', 'CO')
      
    get :auto_complete_for_noncovered_adjustment_code,
      {:noncovered => noncovered},
      {:job_id => jobs(:job1)}, {}
      
    @controller.expects(:render)
      
    assert_nothing_raised(Mysql::Error) do
      @controller.auto_complete_for_noncovered_adjustment_code
    end
  end
  
  
  def test_auto_complete_for_test_noncovered_adjustment_code_without_apostrophe
    adjustment_code = {
      "adjustment_code" => "NCO"
    }
    noncovered = {
      "adjustment_code" => adjustment_code
    }
      
    @request.cookies['reasoncode_description'] = CGI::Cookie.new('reasoncode_description', 'CO')
      
    get :auto_complete_for_noncovered_adjustment_code,
      {:noncovered => noncovered},
      {:job_id => jobs(:job1)}, {}
      
    @controller.expects(:render)
      
    assert_nothing_raised(Mysql::Error) do
      @controller.auto_complete_for_noncovered_adjustment_code
    end
  end

  def test_auto_complete_for_unique_code
    get :auto_complete_for_unique_code, 
      {:unique_code => '1'}, {:job_id => '1'}    
    @controller.expects(:render)
    assert_nothing_raised(Mysql::Error) do
      @controller.auto_complete_for_unique_code('1')
    end
  end
 
end
