require 'test_helper'

class WebServiceLogsControllerTest < ActionController::TestCase
  setup do
    @web_service_log = web_service_logs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:web_service_logs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create web_service_log" do
    assert_difference('WebServiceLog.count') do
      post :create, web_service_log: @web_service_log.attributes
    end

    assert_redirected_to web_service_log_path(assigns(:web_service_log))
  end

  test "should show web_service_log" do
    get :show, id: @web_service_log.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @web_service_log.to_param
    assert_response :success
  end

  test "should update web_service_log" do
    put :update, id: @web_service_log.to_param, web_service_log: @web_service_log.attributes
    assert_redirected_to web_service_log_path(assigns(:web_service_log))
  end

  test "should destroy web_service_log" do
    assert_difference('WebServiceLog.count', -1) do
      delete :destroy, id: @web_service_log.to_param
    end

    assert_redirected_to web_service_logs_path
  end
end
