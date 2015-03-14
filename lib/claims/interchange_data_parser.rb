require "nokogiri"
include Nokogiri

##################################################################################################################################
#   Description: This class is used to get the interchange date and time when a claim file is about to be loaded to database.
#                SAX based parsing is used to fetch <ISA09> and <ISA10> tag values
#   This class contains following methods.
#   * initialize: Class initializing method.
#   * start_element: Parses the starting tag for ISA09 and ISA10 tags and set flags to true.
#   * end_element: Parses the ending tag for ISA09 and ISA10 tags and set flags to false.
#   * characters: Sets the instance variable values.
#   * get_isa09_isa10_values: This method returns the instance variable values for interchange date and time
#
#   Created   : 2012-09-28 by Rajesh R @ Revenuemed
#
##################################################################################################################################

class InterchangeDataParser < XML::SAX::Document
  attr_reader :isa_09_value, :isa_10_value

  def initialize
    @isa_09_value = ""
    @isa_10_value = ""
    @is_isa_09 = false
    @is_isa_10 = false
    @st_se_check = 0
  end

  def start_element(element, attributes)
    case element
    when 'ISA09'
      @is_isa_09 = true
    when 'ISA10'
      @is_isa_10 = true
    when 'ST'
      @st_se_check += 1
    when 'SE'
      @st_se_check -= 1
    end

  end

  def end_element(element)
    case element
    when 'ISA09'
      @is_isa_09 = false
    when 'ISA10'
      @is_isa_10 = false
    end
  end

  def characters(string)
    @isa_09_value = string if @is_isa_09
    @isa_10_value = string if @is_isa_10
  end

  def get_isa09_isa10_values
    isa_09_10_value = @isa_09_value + "_" + @isa_10_value
    return isa_09_10_value
  end

  def get_st_se_correctness
    @st_se_check == 0 ? true : false
  end

end
