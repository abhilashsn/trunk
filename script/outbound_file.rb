# This script is for marking upload file status
require File.expand_path(File.dirname(__FILE__)) + "/batchloading/common.rb"

options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import_batch_file.rb [options]"
  
  opts.on( '-m', '--md5 md5sum', 'md5sum of the file' ) do |md5sum|
    options[:md5sum] = md5sum
  end
  
  opts.on( '-t', '--time TIME', 'Upload Start time or Upload End time' ) do |time|
    options[:time] = time 
  end
  
  opts.on( '-o', '--option OPTION' , 'Option UPLOADING or UPLOADED') do |option|
    options[:option] = option    
  end

end.parse!
begin
  unless options[:md5sum] && options[:time] && (options[:option] == 'UPLOADING' || options[:option] == 'UPLOADED')
    puts "md5sum time and the option (UPLOADING or UPLOADED) is required"  
  else
    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/db"
    make_connection
    require File.expand_path(File.dirname(__FILE__)) + "/outbound/helper.rb"

    time =  time_str_convert(options[:time])
    md5sum = options[:md5sum]

    oal = get_oal md5sum

    unless oal.empty?
      oal_mark_uploading(md5sum,time) if options[:option] == 'UPLOADING'
      oal_mark_uploaded(md5sum,time) if options[:option] == 'UPLOADED'    
    else
      raise "Cannot find a file by the given checksum"
    end
  end
rescue Exception => e
  puts "Exception " + e.message  
end


