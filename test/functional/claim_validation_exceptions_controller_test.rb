require 'test_helper'

class ClaimValidationExceptionsControllerTest < ActionController::TestCase
  setup do
    @claim_validation_exception = claim_validation_exceptions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:claim_validation_exceptions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create claim_validation_exception" do
    assert_difference('ClaimValidationException.count') do
      post :create, claim_validation_exception: @claim_validation_exception.attributes
    end

    assert_redirected_to claim_validation_exception_path(assigns(:claim_validation_exception))
  end

  test "should show claim_validation_exception" do
    get :show, id: @claim_validation_exception.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @claim_validation_exception.to_param
    assert_response :success
  end

  test "should update claim_validation_exception" do
    put :update, id: @claim_validation_exception.to_param, claim_validation_exception: @claim_validation_exception.attributes
    assert_redirected_to claim_validation_exception_path(assigns(:claim_validation_exception))
  end

  test "should destroy claim_validation_exception" do
    assert_difference('ClaimValidationException.count', -1) do
      delete :destroy, id: @claim_validation_exception.to_param
    end

    assert_redirected_to claim_validation_exceptions_path
  end
end
