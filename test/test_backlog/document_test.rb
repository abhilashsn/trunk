require File.dirname(__FILE__) + '/../test_helper'

class DocumentTest < Test::Unit::TestCase
  fixtures :documents

  # Replace this with your real tests.
  
  def test_save_record
    initial_count = Document.count
    new_doc = Document.new(:id => 3, :filename => 'load_file.txt', :content => 'File Loading...', :file_type => 'Errors')
    assert_equal(true, new_doc.save)
  end
  
  def test_count
    initial_count = Document.count
    new_doc = Document.new(:id => 4, :filename => 'load_again_file.txt', :content => 'again loading...', :file_type => 'Text')
    new_doc.save
    assert_equal(initial_count + 1, Document.count)
  end
  
  def test_change_category
    doc1 = Document.find(1)
    doc1.file_type = "ScreenShots"
    doc1.update
    assert_equal("ScreenShots", doc1.file_type)
  end
  
  def test_full_path
    doc1 = Document.find(2)
    doc_filename = doc1.filename
    assert_equal("/tmp/" + doc_filename, doc1.full_path)
  end
  
  def test_unique_filename
    newdoc = Document.new(:id => 5, :filename => "abc.txt", :content => 'testing unique filename...', :file_type => 'Others')
    assert_equal(newdoc.save, false)
    assert_invalid(newdoc, :filename)
  end
  
  def test_find_without_content
    dwc = Document.find :first
    dwoc = Document.find_without_content :first
    assert_equal(dwc.id, dwoc.id)
    assert_equal(dwc.filename, dwoc.filename)
    assert_nothing_raised(Exception) { dwc.content }
    assert_raise(NoMethodError) { dwoc.content }
  end
  
end
