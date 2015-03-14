require 'csv'
require 'fileutils'

class ConfigSetting < ActiveRecord::Base
  attr_accessible :client_id, :partner_id, :facility_id, :output_type, :details

  serialize :details
  
  belongs_to :partner
  belongs_to :client
  belongs_to :facility

  class << self
    def upload_config_file(args)
      begin
        @file = args[:file]
        @file_name = @file.original_filename
        create_directory
        write_to_file
        details_hash = ConfigSetting.create_hash
        h = {:client_id => args[:client_id],:partner_id => args[:partner_id],
             :facility_id => args[:facility_id], :output_type => args[:output_type]}
        @config = ConfigSetting.where(h).first
        if @config.blank?
           ConfigSetting.create(h.merge(:details => details_hash))
        else
          @config.details = details_hash
          @config.save
        end
        delete_directory
        true
      rescue => e
        puts e.message
        logger.info "..check for files..................#{e}"
        false
      end
    end

    def write_to_file
      File.open(@path, "wb") { |f| f.write(@file.read) }
    end

    def create_hash
      row_no = 0
      hash = {}
      CSV.foreach(@path) do |row|
        unless row_no == 0
          sub_hash = { :description => row[1], :value => row[2],
                       :rule => row[3], :expected_value => row[4] }
          hash = hash.merge!(row[0].to_sym => sub_hash)
        end
        row_no +=1
      end
      hash
    end

    def create_directory
      directory = "temp_config_settings"
      # create the file path
      @path = File.join(directory, @file_name)
      @dir_name = File.dirname(@path)
      FileUtils.mkdir_p(@dir_name) unless File.directory?(@dir_name)
    end

    def delete_directory
      FileUtils.rm_rf(@dir_name) if File.directory?(@dir_name)
    end
  end
end