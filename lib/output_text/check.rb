class OutputText::Check
  attr_reader :check, :index
  def initialize(check, index)
    @check = check
    @index = index
  end

  def generate
    text_string = ""
    if index == 0
      text_string = text_header
    end
    text_string = text_content(check)
    return text_string unless text_string.blank?
  end

end