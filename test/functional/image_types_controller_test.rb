require File.dirname(__FILE__)+'/../test_helper'

class ImageTypesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:image_types)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_image_type
    assert_difference('ImageType.count') do
      post :create, :image_type => { }
    end

    assert_redirected_to image_type_path(assigns(:image_type))
  end

  def test_should_show_image_type
    get :show, :id => image_types(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => image_types(:one).id
    assert_response :success
  end

  def test_should_update_image_type
    put :update, :id => image_types(:one).id, :image_type => { }
    assert_redirected_to image_type_path(assigns(:image_type))
  end

  def test_should_destroy_image_type
    assert_difference('ImageType.count', -1) do
      delete :destroy, :id => image_types(:one).id
    end

    assert_redirected_to image_types_path
  end
end
