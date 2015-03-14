require File.dirname(__FILE__)+'/../test_helper'
require 'admin/user_controller'

class UserControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper
  fixtures :users, :clients, :clients_users, :user_activity_logs, :roles, :roles_users

  def setup
    @controller = Admin::UserController.new
  end

  def test_associate_clients_to_users
    user_id = users(:processor_17).id
    get :associate_clients_to_users, {:id => user_id}
    clients_to_users = @controller.associate_clients_to_users
    assert_equal(17, (@controller.instance_variable_get("@processor")).id)
    assert_equal(2, (@controller.instance_variable_get("@processor_clients")).length)
    assert_equal(2, (@controller.instance_variable_get("@clients_users")).length)
  end
  
  def ntest_update_existing_clients_to_users
    user = users(:processor_19)
    get :create_or_update_clients_to_users, {:processor => user, 
      :option => 'Edit', :clients_to_update => {"19" => "1"},
      :auto_allocate_19 => false}
    clients_to_users = @controller.create_or_update_clients_to_users
    assert_equal(1, clients_to_users)
  end
  
  def test_idle_processors
    get :idle_processors
    idle_users = @controller.idle_processors
    assert_equal(2, idle_users.length)
  end
   
end