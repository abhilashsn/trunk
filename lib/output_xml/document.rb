require 'erb'

##################################################################################################################################
#   Description: Represents an XML document. This class is the place where template specific to a facility is loaded and
#                processed and gets the result as xml file
#   This class contains following methods.
#   * initialize: Class initializing method.
#   * load_module: Method for dynamic module loading.
#   * generate: Generating output xml string based on input ERB template.
#   * bind: Method for binding XML string to template.
#   * template: Method to pick the template path based on facility/client name
#
#   Created   : 2010-06-18 by Rajesh R @ Revenuemed
#
##################################################################################################################################

class OutputXml::Document
  attr_reader :check, :facility, :organization_name

  #----------------------------------------------------
  # Description  : Initializes the class.
  # Input        : Set of check objects, Configuration parameters (optional).
  # Output       : None.
  #----------------------------------------------------
  def initialize(checks, config = {})
    begin
      @checks = checks
      @batch = checks.first.batch
      @facility = @batch.facility
      @client = @facility.client.name.upcase
      # Dynamic loading of template variable translation class based on the facility/client name
      # Loading the module file name
      if @client == "ORBOGRAPH" || @client == "ORB TEST FACILITY"
        @batch_type, @module_name = get_batch_type(config)
        translation_module_file_name = File.dirname(__FILE__) + "/templates/" + facility.name.downcase.gsub(' ','_') + "_#{@batch_type}_template_variable_translations.rb"
        # If facility specific dynamic template variable translations class fails, client specific template creation is attempted in the rescue block of
        # load_module method. Once the template is loaded, the corresponding facility/client name is returned from the method
        @organization_name = load_module(translation_module_file_name)
        p "Name of Facility/Client for which template is available - " + organization_name.to_s
        # Dynamically extending the module
        translation_module_name = "OutputXml::" + organization_name.downcase.gsub(' ','_').camelize + "#{@module_name.camelize}TemplateVariableTranslations"
        extend(Object.instance_eval {translation_module_name.constantize})
      else
        translation_module_file_name = File.dirname(__FILE__) + "/templates/" + facility.name.downcase.gsub(' ','_') + "_template_variable_translations.rb"
   
        # If facility specific dynamic template variable translations class fails, client specific template creation is attempted in the rescue block of
        # load_module method. Once the template is loaded, the corresponding facility/client name is returned from the method
        @organization_name = load_module(translation_module_file_name)
        p "Name of Facility/Client for which template is available - " + organization_name.to_s
        # Dynamically extending the module
        translation_module_name = "OutputXml::" + organization_name.downcase.gsub(' ','_').camelize + "TemplateVariableTranslations"
        extend(Object.instance_eval {translation_module_name.constantize})
      end
   
    rescue Exception => e
      puts "XML BASE CLASS INITIALIZATION ERROR => "
      puts e
      OutputXml.log.error "#{Time.now}: Error during XML creation"
      OutputXml.log.info "Batch Id - " + checks.first.batch.id.to_s
      OutputXml.log.info e
      OutputXml.log.info e.backtrace.join("\n")
      OutputXml.log.info "\n"
      puts "Detailed description of the error can be found at - /output_logs/XMLGeneration.log"
    end
  end

  def get_batch_type(config)
    batch_type, module_name = "ins", "ins"
    if config[:check_type] == 'ORBO_CORR'
      batch_type = "corr"
      module_name = "corr"
    elsif config[:check_type] == 'ORBO_INS'
      batch_type = "ins_old_version"
      module_name = "ins"
    end
    return batch_type, module_name
  end
  
  #----------------------------------------------------
  # Description  : Method for dynamic module loading.If dynamic loading fails for module name created with
  #                facility name, the module name is created with client name
  # Input        : Module file name along with full path.
  # Output       : Organization name.
  #----------------------------------------------------
  def load_module(module_file_name)
    begin
      # If dynamic loading fails for module name created with facility name, it moves to the rescue block
      p "Trying to load module name created based on facility name"
      load module_file_name rescue nil
      facility.name
    rescue Exception => e
      # If dynamic loading fails for module name created with facility name, the module name is created with client name
      if @client == "ORBOGRAPH" or @client == "ORB TEST FACILITY"
        translation_module_file_name = File.dirname(__FILE__) + "/templates/" + facility.client.name.downcase.gsub(' ','_') + "_#{@module_name}_template_variable_translations.rb"
      else
        translation_module_file_name = File.dirname(__FILE__) + "/templates/" + facility.client.name.downcase.gsub(' ','_') + "_template_variable_translations.rb"
      end
     
      p "Trying to load module name created based on client name"
      load translation_module_file_name
      facility.client.name
    end
  end

  #----------------------------------------------------
  # Description  : Generating output xml string based on input ERB template.
  # Input        : None.
  # Output       : ERB object.
  #----------------------------------------------------
  def generate
    begin
      xml_string = ''
      ERB.new(template,0).result(bind { xml_string })
    rescue Exception => e
      puts "XML CONTENT CREATION ERROR => "
      puts e
      OutputXml.log.error "#{Time.now}: Error during XML creation"
      OutputXml.log.info "Batch Id - " + @checks.first.batch.id.to_s
      OutputXml.log.info e
      OutputXml.log.info e.backtrace.join("\n")
      OutputXml.log.info "\n"
      puts "Detailed description of the error can be found at - /output_logs/XMLGeneration.log"
    end
  end

  #----------------------------------------------------
  # Description  : Method for binding XML string to template.
  # Input        : None.
  # Output       : None.
  #----------------------------------------------------
  def bind
    binding
  end

  #----------------------------------------------------
  # Description  : Method to pick the template path based on facility/client name.
  # Input        : None.
  # Output       : None.
  #----------------------------------------------------
  def template
    if @client =="ORBOGRAPH" || @client == "ORB TEST FACILITY"
      IO.read(File.dirname(__FILE__) + '/templates/' + organization_name.downcase.gsub(' ','_') + '_'+@batch_type+'_template.xml.erb')
    else
      IO.read(File.dirname(__FILE__) + '/templates/' + organization_name.downcase.gsub(' ','_') + '_template.xml.erb')
    end
  end

  def trim(string, size)
    if string.strip.length > size
      string.strip.slice(0,size)
    else
      string.strip.ljust(size)
    end
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("balance_record_type asc, image_page_no, end_time asc")
  end

end