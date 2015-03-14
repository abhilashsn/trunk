require 'csv'
#Represents an Indexed Image CSV document
class OutputCsv::Document
  attr_reader :checks
  def initialize(checks)
    @checks = checks
  end

  def generate
    csv_content = ""
    csv_content << transactions
  end

  # Wrapper for each check in this Indexed Image
  def transactions
    csv_string = ""
    checks.each_with_index do |check, index|
      csv = ""
      check_klass = OutputCsv.class_for("Check", check.batch.facility)
      puts "Applying class #{check_klass}" if index == 0
      check_obj = check_klass.new(check, index)
      csv = check_obj.generate
      csv_string = csv_string + csv
      # For the first iteration, inorder to execute both header creation and first row writing, generate method is called once more
      if index == 0
        check_obj = check_klass.new(check, 1)
        csv = check_obj.generate
        csv_string = csv_string + csv
      end
    end
    return csv_string
  end
end
