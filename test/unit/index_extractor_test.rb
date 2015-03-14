require File.dirname(__FILE__)+'/../test_helper'
#require 'test_helper'
class InputBatch::IndexExtractorTest < ActiveSupport::TestCase
  fixtures :facilities, :clients
  def setup
    facility = facilities(:facility7)
    @transformer = IndexExtractor.new(facility[:name],"#{Rails.root}/test/expected")
    @transformer.unzip_loc = "#{Rails.root}/test/expected"
  end
  
  def test_file_rename_stanford_university_medical_center
    @transformer.file_rename_stanford_university_medical_center
    images = Dir.glob("#{Rails.root}/test/expected/images/*.tif")
    basename = File.basename(images[0])
    File.rename("#{Rails.root}/test/expected/images/images1.tif","#{Rails.root}/test/expected/images/1.tif")
    File.rename("#{Rails.root}/test/expected/corr/corr1.tif","#{Rails.root}/test/expected/corr/1.tif")
    assert_equal("images1.tif",basename)
  end
  
    #this test needs to be fixed by the developer and checked in
  def ntest_file_move_stanford_university_medical_center
    directory = YAML::load(File.open("#{Rails.root}/lib/yml/directory_location.yml"))
    @transformer.file_move_stanford_university_medical_center(directory,"test")
    images = Dir.glob("#{directory['SX']}/test/images/*.tif")
    basename = File.basename(images[0])
    assert_equal("1.tif",basename)
  end
  
end