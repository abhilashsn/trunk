module OtherOutput 
 class Config
    attr_reader :file_name, :format, :header_fields, :grouping, :report_type, :zip_file_name, :is_proper
    
    def initialize hash
      @config_hash = hash || {}
      process_config
    end

    def get_label_for header
      if @header_fields.collect(&:first).include?(header)
        @header_fields.map{|f|f[1]}[@header_fields.collect(&:first).index(header)]
      else
        nil
      end
    end
    
    private
    
    def process_config
      get_db_fields
      get_other_configs      
    end

    def get_db_fields
      @header_fields = []
      @config_hash["header"].keys.sort{|a,b| a.to_i <=> b.to_i}.each do |key|
        @header_fields << [@config_hash["header"][key], @config_hash["header_label"][key]] if @config_hash["header"][key].present?
      end if @config_hash["header"]
    end

    def get_other_configs
      @file_name = @config_hash["file_name_format"] || "unspecified"
      @format = @config_hash["format"] || "unspecified"
      @zip_file_name = @config_hash["zip_name_format"] || "unspecified"
      @grouping = @config_hash["group by"] || "batch"
      @report_type = @config_hash["report_type"] || "unspecified"
    end
    
  end  
end
