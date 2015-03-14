# To change this template, choose Tools | Templates
# and open the template in the editor.
require "nokogiri"
require 'utils/rr_logger'
require "ocr/ocr_data_parser"
module OcrXmlParser
  class OcrParser

    def initialize xml_file= nil
      @status = nil
      @messages = []
      @xml_files =  Dir.glob("#{Rails.root}/OCR_XML/#{xml_file}")
    end



    def parse_ocr_xml
      email_cnf = YAML::load(File.open("#{Rails.root}/config/references.yml"))
      schema_file = File.exist? "OCR_XML/XML_SCHEMA/schema.xsd"
      if schema_file
        xsd = Nokogiri::XML::Schema(File.read("OCR_XML/XML_SCHEMA/schema.xsd"))
        @xml_files.each do |file|
        doc = Nokogiri::XML(File.read(file))
        errors = []
        xsd.validate(doc).each do |error|
          errors << error.message 
        end
        unless errors.empty?
          puts "The File '#{file}' does not comply with the XSD..But still trying to load.. \nThe errors/warnings are emailed to #{email_cnf['email']['wrong_xml_format']['notification']}....."
          RevremitMailer.notify_wrong_xml_format(email_cnf['email']['wrong_xml_format']['notification'], file, errors).deliver
        end
        arg_ocr_data_parser = OcrDataParser.new
        ocr_data_parser = XML::SAX::Parser.new(arg_ocr_data_parser)
        ocr_data_parser.parse_file(file.to_s)
        puts "The File '#{file}' is parsed and the data is loaded into the system..."
        system "mv #{file} #{Rails.root}/OCR_XML_Archive"
        end
      else
        puts "The schema file 'schema.xsd' should be present in the location OCR_XML/XML_SCHEMA to load an OCR XML file.."
      end
    end
 
    

    def insert_meta_data(zone_value,page,dpi,field_name,field_value,account_state,record_pointer,confidence)
      field_name = field_name == 'service_not_covered' ? 'service_no_covered' : field_name
      field_name = field_name == 'service_contract_allowance' ? 'contractual_amount' : field_name
      field_name = field_name == 'service_co_inurance' ? 'service_co_insurance' : field_name
      @total_ocr_read_fields += 1
      field_ocr_output = field_name+"_ocr_output"
      field_data_origin = field_name+"_data_origin"
      field_number_page = field_name+"_page"
      field_number_coordinates = field_name+"_coordinates"
      field_number_state = field_name+"_ocr_state"
      field_number_confidence = field_name+"_confidence"
      confidence_value = find_the_data_origin_of(account_state.to_s,field_value,confidence)
      @total_confident_fields +=1 if confidence_value == 1

      if field_name == 'service_reason_code'
        if !@payer.blank?
          @reason_code = ReasonCode.get_reason_code(field_value, nil, @payer.reason_code_set_name)
          if @reason_code.blank?
            @reason_code = ReasonCode.new(:reason_code=>field_value,:reason_code_set_name_id=>@payer.reason_code_set_name_id,:status=>"NEW")
            @reason_code.save(:validate => false)
          end
          reason_code_id = @reason_code.id
          @reason_code_job = ReasonCodesJob.find(:first,:conditions=>"reason_code_id = #{reason_code_id} and parent_job_id = #{@job_id}")
          if @reason_code_job.blank?
            @reason_code_job = ReasonCodesJob.new()
            @reason_code_job.reason_code_id = reason_code_id
            @reason_code_job.parent_job_id = @job_id
            @reason_code_job.save
          end
          @reason_code_job.details[field_ocr_output.to_sym] = field_value if field_value
          @reason_code_job.details[field_data_origin.to_sym] = confidence_value
          @reason_code_job.details[field_number_page.to_sym] = page
          @reason_code_job.details[field_number_coordinates.to_sym] = find_the_cordinates_of(zone_value,dpi.to_i)
          @reason_code_job.details[field_number_state.to_sym] = account_state.to_s
          @reason_code_job.details[field_number_confidence.to_sym] = confidence.to_i
          @reason_code_job.save
        end
      else
        record_pointer.update_attribute("#{field_name}","#{field_value}")
        record_pointer.details[field_ocr_output.to_sym] = field_value if field_value
        record_pointer.details[field_data_origin.to_sym] = confidence_value
        record_pointer.details[field_number_page.to_sym] = page
        record_pointer.details[field_number_coordinates.to_sym] = find_the_cordinates_of(zone_value,dpi.to_i)
        record_pointer.details[field_number_state.to_sym] = account_state.to_s
        record_pointer.details[field_number_confidence.to_sym] = confidence.to_i
      end
    end

    def insert_meta_data_existing_value(zone_value,page,dpi,field_name,field_value,account_state,record_pointer,confidence)
      if @new_payer and (field_name.include?("pay_address") or field_name == "payer")
        record_pointer.update_attribute("#{field_name}","#{field_value}")
        @total_ocr_read_fields += 1
      end
      field_ocr_output=field_name+"_ocr_output"
      field_data_origin=field_name+"_data_origin"
      field_number_page=field_name+"_page"
      field_number_coordinates=field_name+"_coordinates"
      field_number_state = field_name+"_ocr_state"
      field_number_confidence = field_name+"_confidence"
      record_pointer.details[field_ocr_output.to_sym] = field_value if field_value
      confidence_value =  find_the_data_origin_of(account_state.to_s,field_value,confidence)
      record_pointer.details[field_data_origin.to_sym] = confidence_value
      @total_confident_fields +=1 if confidence_value == 1
      record_pointer.details[field_number_page.to_sym] = page
      record_pointer.details[field_number_coordinates.to_sym] = find_the_cordinates_of(zone_value,dpi.to_i)
      record_pointer.details[field_number_state.to_sym] = account_state.to_s
      record_pointer.details[field_number_confidence.to_sym] = confidence.to_i
    end

    def get_values(patient_tag)
      page = find_image_page(patient_tag)
      data_point = []
      data_point << patient_tag.xpath('.//value').inner_text.strip
      data_point << patient_tag.xpath('.//zone').inner_text
      data_point << patient_tag.attributes["state"].value
      data_point << patient_tag.xpath('.//sources/image').attr('XResolution').value
      data_point << page
      data_point << patient_tag.attributes["confidence"].value
      return data_point
    end

    def get_values_first_row(patient_tag)
      page = find_image_page(patient_tag)
      data_point = []
      data_point << patient_tag.xpath('.//value')[0].inner_text
      data_point << patient_tag.xpath('.//zone')[0].inner_text
      data_point << patient_tag.attributes["state"].value
      data_point << patient_tag.xpath('.//sources/image').attr('XResolution').value
      data_point << page
      data_point << patient_tag.attributes["confidence"].value
      return data_point
    end

    def get_values_of_check(check_tag)
      if !check_tag.blank?
        page = find_image_page(check_tag)
        data_point = []
        data_point << check_tag.xpath('.//value').inner_text
        data_point << check_tag.xpath('.//zone').inner_text
        data_point << check_tag.attr("state").value
        data_point << check_tag.xpath('.//sources/image').attr('XResolution').value
        data_point << page
        data_point << check_tag.attr("confidence").value
        return data_point
      end
    end

    def find_the_data_origin_of(value,text,confidence)
      confidence_value = 79
      flag = text.to_s.include?("?") unless text.nil? #chances of ? with 100% confidence
      if (value == "Ok" and flag == false and confidence.to_i > confidence_value)
        return 1
      elsif (value == "Reject" or (value == "Ok" and flag == true) or (confidence.to_i < confidence_value))
        return 2
      elsif (value == "Empty" and flag == true)
        return 2
      elsif value == "Empty"
        return 3
      end
    end

    def find_the_cordinates_of(zone_values,dpi)
      split_zone_values = zone_values.split(" ")
      zone_array = []
      for zone in split_zone_values
        zone = zone.to_i
        a = (zone / 10) * 0.039370079 * dpi
        zone_array << a
      end
      return zone_array
    end

    def find_image_page(patient_tag)
      image_name_from_xml = patient_tag.xpath('.//sources/image').attr('href').value
      unless image_name_from_xml.blank?
        image_number = image_name_from_xml.split("\\").last.chomp!(".tif").split("_").last.to_i
        @image = @job.images_for_jobs.find(:first,:conditions=>"image_number = #{image_number + 1}")
        unless @image.nil?
          page = @image.image_number
        else
          page = 0
        end
      else
        page = 0
      end
      return page
    end

    def save_image_type(image_tag,type,eob_id)
      @image_type = ImageType.new
      page = find_image_page(image_tag)
      ocr_parser_log.info "page: #{page}"
      ocr_parser_log.info "@image: #{@image}"
      @image_type.image_type = type
      @image_type.images_for_job_id = @image.id
      @image_type.image_page_number = page
      @image_type.insurance_payment_eob_id = eob_id
      @image_type.save(:validate=>false)
    end

    def ocr_parser_log
      RevRemitLogger.new_logger(LogLocation::OCRPARSERLOG)
    end

 
  end
    
end
