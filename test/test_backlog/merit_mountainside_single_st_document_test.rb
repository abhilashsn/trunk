require File.dirname(__FILE__)+'/../test_helper'
require File.dirname(__FILE__)+'/../../lib/output835/document'
require File.dirname(__FILE__)+'/../../lib/output835/single_st_document'
require File.dirname(__FILE__)+'/../../lib/output835/merit_mountainside_single_st_document'
require File.dirname(__FILE__)+'/../../lib/output835'

class Output835::MeritMountainsideSingleStDocumentTest < ActiveSupport::TestCase
  fixtures :check_informations, :jobs, :batches
  include Output835
  
  def setup
    @check_informations = check_informations(:checkinfomation1, :check_information3)
    @checks = Document.new(@check_informations, {false, '*', "~", "\n"})
    
  end
  
  def test_group_date
    @group_date = @checks.group_date
    assert_equal(@group_date, "20101129")
  end
  
end
