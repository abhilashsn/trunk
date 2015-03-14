module OtherOutput
  require "HREOB/EDCHrEob.rb"
  class Automator
    def initialize batch_id, batch_ids
      @ra_package_configs = YAML.load(File.read("#{Rails.root}/lib/yml/config_ra_package_dirs.yml"))
      @batch_id = batch_id
      @batch_ids = batch_ids
      @a37_batch_ids = Array.new
      @process = false
      batch = Batch.find(@batch_id) rescue nil      
      if batch && !@batch_ids.blank?
        @process = true
        @facility = batch.facility
        @configs = FacilityOutputConfig.other_outputs @facility.id            
      end
    end
    
    def process
      return if !@process
      output_conf_types = @configs.collect(&:other_output_type)
      Rails.logger.info("trying to generate " + output_conf_types.join(", "))
      a37conf = @configs.select{|j| j.other_output_type == "A37 Report"}.first
      a36conf = @configs.select{|j| j.other_output_type == "A36 Report"}.first
      hreobconf = @configs.select{|j| j.other_output_type == "Human Readable Eob"}.first
    
      if a36conf
        conf = OtherOutput::Config.new(a36conf.operation_log_config)        
        doc = OtherOutput::Document.new(@batch_id, conf)
        grouping = conf.grouping
        @a36_batch_ids = doc.accumulated_batch_ids
        if grouping == "batch"
          @a36_batch_ids = @batch_ids.clone
          @batch_ids.each do |id|
            generator = OtherOutput::Generator.new(id)
            generator.generate_specific conf
          end
        else
          generator = OtherOutput::Generator.new(@batch_id)          
          generator.generate_specific conf
        end
      end

      if a37conf
        conf = OtherOutput::Config.new(a37conf.operation_log_config)        
        doc = OtherOutput::Document.new(@batch_id, conf)
        grouping = conf.grouping
        @a37_batch_ids = doc.accumulated_batch_ids        
        if grouping == "batch"
          @a37_batch_ids = @batch_ids.clone
          @batch_ids.each do |id|
            generator = OtherOutput::Generator.new(id)
            generator.generate_specific conf
          end
        else
          generator = OtherOutput::Generator.new(@batch_id)
          generator.generate_specific conf
        end        
      end

      if hreobconf
        Rails.logger.debug ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        Rails.logger.debug @batch_ids.inspect
        Rails.logger.debug @a37_batch_ids.inspect
        Rails.logger.debug ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        ((@batch_ids + @a37_batch_ids).uniq).each do |id|

          generate_human_readable_eob id
          xml_gen = XmlGenerator.new(id)
          if xml_gen.generate
            puts "XMLs are successfully generated and can be found in <rails_root>/private/data/XMLs"
            ra = Package::Rapackage.new(Batch.find(id))
            ra.generate(@ra_package_configs)
          else
            puts "There was an error in XML generation. Refer <rails_root>/log/xml_log/XmlGeneration.log"
          end
        end
      end
      
    end

    
    private
    def generate_human_readable_eob batch_id
      Rails.logger.debug ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>------------------))))))" + batch_id.to_s
      facility_name = @facility && @facility.name ? @facility.name : "unknown"
      directory = "private/datanew/other_outputs/#{facility_name}/txt/human_readable/#{Date.today.to_s}/#{batch_id}"
      FileUtils.mkdir_p(Rails.root.to_s + "/"  + directory)
      hreob = EDCHrEob.new(directory)
      hreob.generate_edc_hr_eob(batch_id)
    end

    
  end
end
