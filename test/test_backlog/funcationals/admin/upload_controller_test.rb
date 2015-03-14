require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/upload_controller'

# Re-raise errors caught by the controller.
class Admin::UploadController; def rescue_action(e) raise e end; end

class Admin::UploadControllerTest < Test::Unit::TestCase
  fixtures :facilities
  
  def setup
    @controller = Admin::UploadController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_create_batch
    batch_upload = uploaded_file("#{File.expand_path(Rails.root)}/test/fixtures/batch_import.csv")
    count = Batch.count
    post :create, {:upload => {'file' => batch_upload}, :type => 'batch'}, {:user => 15}
    new_count = Batch.count
    last_batch = Batch.find(:all).last
    assert_equal(last_batch.arrival_time, Time.parse("9/19/2007 21:45"))
    assert_equal(count + 1, new_count)
    assert_redirected_to :controller => '/admin/upload', :action => 'upload', :batch => nil, :type => 'batch'
  end
  
  # get us an object that represents an uploaded file
  def uploaded_file(path, content_type="application/octet-stream", filename=nil)
    filename ||= File.basename(path)
    t = Tempfile.new(filename)
    FileUtils.copy_file(path, t.path)
    (class << t; self; end;).class_eval do
      alias local_path path
      define_method(:original_filename) { filename }
      define_method(:content_type) { content_type }
    end
    return t
  end
  
end
