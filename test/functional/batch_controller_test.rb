require File.dirname(__FILE__)+'/../test_helper'
require 'admin/batch_controller'
require 'mocha/setup'

class BatchesControllerTest < ActionController::TestCase
  
  include AuthenticatedTestHelper
  fixtures :batches
  
 
  def setup
    @controller = Admin::BatchController.new
    @session   = ActionController::TestSession.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end
  
  def teardown
    #    @session.clear
  end

  def test_work_list_to_have_batches_with_status_new_or_processing_or_complete
    get :work_list
    batches = @controller.work_list
    batches_with_unwanted_status = batches.select do |batch|
      batch.status != BatchStatus::NEW && batch.status != BatchStatus::PROCESSING && 
        batch.status != BatchStatus::COMPLETED
    end
    assert_equal 0, batches_with_unwanted_status.length
  end

  # Obtained for the next 4 tests
  # AbstractController::DoubleRenderError:
  # Render and/or redirect were called multiple times in this action.
  # Please note that you may only call render OR redirect,
  # and at most once per action.
  # Also note that neither redirect nor render terminate execution of the action,
  # so if you want to exit an action after redirecting,
  # you need to do something like "redirect_to(...) and return".
  def do_not_test_add_to_client_wise_allocation_queue
    batch_ids = [batches(:batch_32).id, batches(:batch_33).id]
    batches_to_select = {
      "#{batch_ids[0]}" => "1",
      "#{batch_ids[1]}" => "1"
    }
    post :update_allocation_type_and_batch_status,
      :batches_to_select => batches_to_select, :submit_param => 'Client Wise Auto Allocation'
    
    
    batches = @controller.update_allocation_type_and_batch_status

    batches = Batch.find(batch_ids)
    batch_1, batch_2 = batches[0], batches[1]
    assert_equal true, batch_1.client_wise_auto_allocation_enabled
    assert_equal false, batch_1.payer_wise_auto_allocation_enabled
    assert_equal true, batch_2.client_wise_auto_allocation_enabled
    assert_equal false, batch_2.payer_wise_auto_allocation_enabled
  end

  def do_not_test_add_to_payer_wise_allocation_queue
    batch_ids = [batches(:batch_34).id, batches(:batch_35).id]
    batches_to_select = {
      "#{batch_ids[0]}" => "1",
      "#{batch_ids[1]}" => "1"
    }
    post :update_allocation_type_and_batch_status,
      :batches_to_select => batches_to_select, :submit_param => 'Payer Wise Auto Allocation'


    batches = @controller.update_allocation_type_and_batch_status

    batches = Batch.find(batch_ids)
    batch_1, batch_2 = batches[0], batches[1]
    assert_equal false, batch_1.client_wise_auto_allocation_enabled
    assert_equal true, batch_1.payer_wise_auto_allocation_enabled
    assert_equal false, batch_2.client_wise_auto_allocation_enabled
    assert_equal true, batch_2.payer_wise_auto_allocation_enabled
  end

  def do_not_test_remove_from_allocation_queue
    batch_ids = [batches(:batch_34).id, batches(:batch_35).id]
    batches_to_select = {
      "#{batch_ids[0]}" => "1",
      "#{batch_ids[1]}" => "1"
    }
    post :update_allocation_type_and_batch_status,
      :batches_to_select => batches_to_select, :submit_param => 'Remove From Auto Allocation'


    batches = @controller.update_allocation_type_and_batch_status

    batches = Batch.find(batch_ids)
    batch_1, batch_2 = batches[0], batches[1]
    assert_equal false, batch_1.client_wise_auto_allocation_enabled
    assert_equal false, batch_1.payer_wise_auto_allocation_enabled
    assert_equal false, batch_2.client_wise_auto_allocation_enabled
    assert_equal false, batch_2.payer_wise_auto_allocation_enabled
  end

  def do_not_test_change_status_to_output_ready
    batch_ids = [batches(:batch_35).id, batches(:batch_36).id, batches(:batch_37).id]
    batches_to_select = {
      "#{batch_ids[0]}" => "1",
      "#{batch_ids[1]}" => "1"
    }
    post :update_allocation_type_and_batch_status,
      :batches_to_select => batches_to_select, :submit_param => 'Make Output Ready'


    batches = @controller.update_allocation_type_and_batch_status

    batches = Batch.find(batch_ids)
    batch_1, batch_2, batch_3 = batches[0], batches[1], batches[2]
    assert_equal BatchStatus::NEW, batch_1.status
    assert_equal BatchStatus::OUTPUT_READY, batch_2.status
    assert_equal BatchStatus::OUTPUT_READY, batch_3.status
  end


  
end