module OtherOutput
  class RaGenerator
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
      hreobconf = @configs.select{|j| j.other_output_type == "Human Readable Eob"}.first

      if a37conf
        puts "Collecting the Batch ids for the A37s................"
        conf = OtherOutput::Config.new(a37conf.operation_log_config)
        doc = OtherOutput::Document.new(@batch_id, conf)
        grouping = conf.grouping
        @a37_batch_ids = doc.accumulated_batch_ids
        if grouping == "batch"
          @a37_batch_ids = @batch_ids.clone
        end
        puts "The Batch ids for the A37s are #{@a37_batch_ids}"
      end

      Rails.logger.debug ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      Rails.logger.debug @batch_ids.inspect
      Rails.logger.debug @a37_batch_ids.inspect
      Rails.logger.debug ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
      ((@batch_ids + @a37_batch_ids).uniq).each do |id|
        ra = Package::Rapackage.new(Batch.find(id))
        ra.generate(@ra_package_configs)
      end
    end
  end
end