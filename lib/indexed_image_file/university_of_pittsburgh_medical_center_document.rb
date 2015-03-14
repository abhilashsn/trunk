#Represents an Indexed Image document
class IndexedImageFile::UniversityOfPittsburghMedicalCenterDocument
  attr_reader :checks
  def initialize(checks)
    @checks = checks
  end

  # Generate method for indexed image file creation
  def generate
    index_image_string = ""
    index_image_string << transactions
    index_image_string unless index_image_string.blank?
  end

  # Wrapper for each check in this Indexed Image
  def transactions
    index_image_string = ""
    index = 0
    checks.each do |check|
      index += 1
      check_klass = IndexedImageFile.class_for("Check", check.batch.facility)
      check_obj = check_klass.new(check, index)
      index_image_string += check_obj.generate
    end
    index_image_string unless index_image_string.blank?
  end

end

