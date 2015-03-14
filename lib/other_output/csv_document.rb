class OtherOutput::CsvDocument < OtherOutput::Document
  def initialize
    @delimiter = ","
    @newline = "\n"
  end

  def header header
    header.map{|j| j[1].present? ? (j[1] == "NOLABEL" ? "" : j[1] ) : j[0]}.compact.join(@delimiter) + @newline
  end
  
  def line headers,  hash
    headers.collect(&:first).map{|key| sanitize(hash[key])}.join(@delimiter) + @newline    
  end

  def footer
    
  end

  def sanitize field
    field = field.to_s
    if field =~ /\,/
      field = "\"" + field + "\""
    end
    field
  end  
end
