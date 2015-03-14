require 'test_helper'

class MpiStatisticsReportsControllerTest < ActionController::TestCase
  setup do
    @mpi_statistics_report = mpi_statistics_reports(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mpi_statistics_reports)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mpi_statistics_report" do
    assert_difference('MpiStatisticsReport.count') do
      post :create, mpi_statistics_report: @mpi_statistics_report.attributes
    end

    assert_redirected_to mpi_statistics_report_path(assigns(:mpi_statistics_report))
  end

  test "should show mpi_statistics_report" do
    get :show, id: @mpi_statistics_report.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mpi_statistics_report.to_param
    assert_response :success
  end

  test "should update mpi_statistics_report" do
    put :update, id: @mpi_statistics_report.to_param, mpi_statistics_report: @mpi_statistics_report.attributes
    assert_redirected_to mpi_statistics_report_path(assigns(:mpi_statistics_report))
  end

  test "should destroy mpi_statistics_report" do
    assert_difference('MpiStatisticsReport.count', -1) do
      delete :destroy, id: @mpi_statistics_report.to_param
    end

    assert_redirected_to mpi_statistics_reports_path
  end
end
