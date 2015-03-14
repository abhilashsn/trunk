# Script to set start time of file posting to FTP in output_activity_logs given file name and time.

require "logger"
require "time"
require "mysql2"
require File.expand_path(File.dirname(__FILE__)) + "/../lib/write_log"
require File.expand_path(File.dirname(__FILE__)) + "/batchloading/db"
make_connection

@options = {}
arguements = ARGV.join(' ')
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: ruby script/file_posting_start_time.rb [options], File Name and Time are mandatory"

  opts.on( '-f', '--file FILE NAME', 'File Name' ) do |file|
    @options[:file_name] = file
  end

  opts.on( '-t', '--time TIME', "File Posting Start Time 'YYYY-MM-DD HH:MM:SS'" ) do |time|
    @options[:start_time] = time
  end

  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end.parse!

directory_name = "log/#{Date.today.strftime("%Y%m%d")}/scripts"
log_file_name = "file_posting"
@log = WriteLog.write(directory_name, log_file_name)

error_message = "Please use option -h for help"
if @options[:file_name].nil? || @options[:start_time].nil?
  puts error_message
  @log.error error_message
else
  begin
    @log.debug "#{@options[:file_name]} : Start Time = '#{@options[:start_time]}'"
    converted_time = Time.strptime("#{@options[:start_time]}", '%Y-%m-%d %H:%M:%S').utc
    time_array = converted_time.to_s.split(' ')
    time_array.delete_at(-1)
    converted_time = time_array.join(" ")
    query = "UPDATE output_activity_logs SET upload_start_time = '#{converted_time}' WHERE file_name = '#{@options[:file_name]}'"
    insert = querydb query
    @log.debug "#{@options[:file_name]} : DB update completed."
  rescue Exception => e
    if(e.message == 'invalid date')
      message = "Invalid Date Format. Expected format is YYYY-MM-DD HH:MM:SS"
      puts message + error_message
      @log.error "#{@options[:file_name]} : #{message}"
    else
      puts e.message + ".    " + error_message
      @log.error "#{@options[:file_name]} : #{e.message}"
    end
  end
end