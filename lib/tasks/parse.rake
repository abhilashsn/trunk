namespace :ocr do
  require "nokogiri"
  require 'utils/rr_logger'
  require 'ocr/ocr_xml_parser'
  task :parse_xml => :environment do
    
    parser = OcrXmlParser::OcrParser.new()
    
    parser.parse

  end

  task :parse_ocr_xml, [:file_name] => [:environment] do |t, args|
    parser = OcrXmlParser::OcrParser.new("#{args[:file_name]}")
    parser.parse_ocr_xml
  end
end
