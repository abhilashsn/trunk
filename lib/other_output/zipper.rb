class OtherOutput::Zipper
  attr_accessor :output_file_location, :input_file_location, :filename
  def initialize zip_name, files
    @zip_name = "\"" + Rails.root.to_s + "/" + zip_name + "\""
    @files = files.map{|f|  "\"" + Rails.root.to_s + "/" + f + "\""}.join(" ")
    puts @zip_name
    puts @files
  end

  def archive    
    system "zip -mqj #{@zip_name} #{@files}"
  end
end
