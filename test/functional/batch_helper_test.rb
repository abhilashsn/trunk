require File.dirname(__FILE__)+'/../test_helper'
require 'admin/batch_controller'
require 'admin/batch_helper'
require 'mocha/setup'

class BatchHelperTest < ActionController::TestCase
  include AuthenticatedTestHelper
  
  fixtures :batches, :jobs, :facilities, :clients, :check_informations,
    :insurance_payment_eobs, :patient_pay_eobs
  
  def setup
    @controller = Admin::BatchController.new
    @session   = ActionController::TestSession.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    @object = Object.new
    @helper = @object.extend(Admin::BatchHelper)
    
  end

  # The following tests are obtaining the @batches object differently.
  def do_not_test_legend_color_blue_for_work_list
    params = {:to_find => "", :criteria => "", :page => 1}
    get :work_list, params
    @batches = @controller.work_list
    batch = @batches.select{|batch| batch.id == batches(:batch_38).id}
    @helper.instance_variable_set("@batch", batch.first)
    expected_color = 'blue'
    observed_color = @helper.legend_color_for_work_list
    assert_equal expected_color, observed_color
  end

  def do_not_test_legend_color_pale_red_for_work_list
    params = {:to_find => "", :criteria => "", :page => 2}
    get :work_list, params
    @batches = @controller.work_list
    batch = @batches.select{|batch| batch.id == batches(:batch_32).id}
    @helper.instance_variable_set("@batch", batch.first)
    expected_color = 'palered'
    observed_color = @helper.legend_color_for_work_list
    assert_equal expected_color, observed_color
  end

  def do_not_test_legend_color_light_blue_for_work_list
    params = {:to_find => "", :criteria => "", :page => 1}
    get :work_list, params
    @batches = @controller.work_list
    batch = @batches.select{|batch| batch.id == batches(:batch_39).id}
    @helper.instance_variable_set("@batch", batch.first)
    expected_color = 'lightblue'
    observed_color = @helper.legend_color_for_work_list
    assert_equal expected_color, observed_color
  end

  def do_not_test_legend_color_red_for_work_list
    params = {:to_find => "", :criteria => "", :page => 3}
    get :work_list, params
    @batches = @controller.work_list
    batch = @batches.select{|batch| batch.id == batches(:batch_37).id}
    @helper.instance_variable_set("@batch", batch.first)
    expected_color = 'red'
    observed_color = @helper.legend_color_for_work_list
    assert_equal expected_color, observed_color
  end
  
end