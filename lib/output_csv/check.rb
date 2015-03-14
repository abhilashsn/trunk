# Base Class for accepting check object and index value
class OutputCsv::Check
  attr_reader :check, :index
  def initialize(check, index)
    @check = check
    @index = index
  end

  # Generate method for CSV creation
  def generate
    csv_string = nil
    if index == 0
      csv_string = csv_header
    else
      csv_string = csv_content(check)
    end
    return csv_string unless csv_string.blank?
  end

end

