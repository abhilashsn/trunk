require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/document_controller'

# Re-raise errors caught by the controller.
class Admin::DocumentController; def rescue_action(e) raise e end; end

class Admin::DocumentControllerTest < Test::Unit::TestCase
  fixtures :documents, :users
  def setup
    @controller = Admin::DocumentController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    assert true
  end

  def login_as(user)
    user = users(user)
    @request.session[:user] = user.id
    return user
  end

  def test_show_list
    login_as(:gs)
    get :show_list, :doc => 'Errors'
    error_docs = Document.find(:all, :conditions => "file_type = 'Errors'")
    assert_equal error_docs.size, assigns(:docs).size
    assert_response :success
  end

  def test_update
    login_as(:gs)
    doc1 = documents(:doc1)
    doc_filetype = 'Text'
    get :update, :id => doc1.id, :doc => {:criteria => doc_filetype}
    assert_redirected_to :action => 'add_view_docs'
    assert_equal 'Text', assigns(:doc).file_type
  end

  def test_show
    login_as(:gs)
    get :show, :id => documents(:doc1).id
    assert_equal Document.find(documents(:doc1).id).content, assigns(:doc).content
  end

  def test_destroy
    login_as(:gs)
    get :destroy, :id => 2
    assert_response :redirect
    assert_redirected_to :action => 'add_view_docs'
  end
end
