require File.dirname(__FILE__)+'/../test_helper'



class CheckGroupFileTest <  ActiveSupport::TestCase
  fixtures :facilities, :users, :clients
  
  def setup
    @check_group = CheckGroupFile.new(facilities(:facility_24))
    
  end
  
  def test_create_zip_file_from_output
    @check_group.create_zip_file_from_output("#{File.dirname(__FILE__)}/../expected",".zip","sample.835")
    assert(File.exists?("#{File.dirname(__FILE__)}/../expected/sample.zip"))
  end
 
end