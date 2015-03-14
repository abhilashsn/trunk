require 'claims/xml_transformer'
require 'claims/csv_transformer'
require 'claims/txt_transformer'

class Transformer

  # This method is used to select the class based on file type  
  def self.factory choice
    { "XML" => XMLTransformer, "CSV" => CSVTransformer, "TXT" => TXTTransformer }[choice].new 
  end  
  
  def self.transform conf
    begin 
      
      # Not used because CNF is Global
      # cnf = YAML::load(File.open(conf))
      
      trf = factory($CNF['parser_type'])
      puts "..Transformer in use - #{trf.class}"

      loc = $CNF['file_location'] << locate_files($CNF['parser_type'])
      puts "..Locating data file - #{loc}"
      
      fls = Dir.glob(loc)
      puts "ERROR: Unable to locate data file in #{loc}" if fls.size == 0
      fls.each do |file|
        puts "..Transforming file : #{file}"
        trf.transform(file, $CNF)
      end
    rescue => err
      puts err.message
    end  
  end
  
  private
  
  def self.locate_files ch
    case ch
      when "XML"
        return "/*.xml"
      when "CSV"
        return "/*.csv"
      when "TXT"
        return "/*.dat"
    end      
  end
  
end
