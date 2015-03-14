class WriteLog < Logger

  def self.write(directory_name, file_name)
    FileUtils.mkdir_p(directory_name) unless File.directory?(directory_name)
    log_file = File.open("#{directory_name}/#{file_name}.log",'a')
    log = Logger.new(log_file)
    log.level = Logger::DEBUG
    log
  end
  
end
