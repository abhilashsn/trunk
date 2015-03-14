#Represents a Text document
class OutputText::Document
  attr_reader :checks
  def initialize(checks)
    @checks = checks
  end

  def generate
    text_content = ""
    text_content << transactions
  end

  # Wrapper for each check in this Indexed Image
  def transactions
    text_string = ""
      checks.each_with_index do |check, index|
        check_klass = OutputText.class_for("Check", check.batch.facility)
        puts "Applying class #{check_klass}" if index == 0
        check = check_klass.new(check, index)
        text_string = check.generate
      end
    end
    return text_string
  end


