require File.expand_path(File.dirname(__FILE__)) + "/batchloading/common.rb"
require File.expand_path(File.dirname(__FILE__)) + "/../lib/utils/rr_logger"
options = {}
arguements = ARGV.join(' ')
optparse = OptionParser.new do|opts|
             opts.banner = "Usage: ocred [options]" 
             
             opts.on( '-f', '--file  FILE', 'XML file ' ) do |file|
               options[:file] = file
             end
              
             opts.on( '-p', '--path PATH', 'Path of the xml' ) do |path|
               options[:path] = path
             end

             opts.on( '-t', '--time TIME', 'File Arrival Time' ) do |time|
               options[:time] = time 
             end

             opts.on( '-h', '--help', 'Display this screen' ) do
               puts opts
               exit
             end
  
           end.parse!

unless options[:file] && options[:path] &&options[:time]  
  puts "file, path and time are required "
  puts "Run \'ruby script/ocred.rb -h\' for help "  
else  
  begin
    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/db"
    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/helper"
    require File.expand_path(File.dirname(__FILE__)) + "/../app/models/job_status"

    log = setup_logger
    log.debug("===================================================================")
    log.debug("COMMAND >>> ruby script/ocred.rb #{arguements}")    
    make_connection
    filename = File.basename(options[:file])
    arrival_date = time_str_convert(options[:time])
    absfilepath = options[:path] + "/" +  options[:file]
    if filename =~ /(\d+)\..*/
      job_id = $1
      result = querydb("SELECT job_status FROM jobs where id = '#{job_id}'")
      if result.num_rows == 1
        status = result.fetch_hash["job_status"]
        if status == JobStatus::NEW
          querydb("UPDATE jobs SET job_status ='#{JobStatus::OCR}', ocr_status = '#{JobStatus::OCR_ARRIVED}',
                   ocr_arrival_time = '#{arrival_date}', is_ocr = '1'  WHERE id = '#{job_id}'")
          querydb("INSERT INTO delayed_jobs(handler,run_at,queue) VALUES('--- !ruby/object:OcredDataLoader\nocr_xml: #{absfilepath}\n', 0, 'ocr_loading')")
        else
          querydb("UPDATE jobs SET  ocr_status = '#{JobStatus::OCR_LATE}', ocr_arrival_time = '#{arrival_date}' ,
                   is_ocr = '1'  WHERE id = '#{job_id}'")
        end
      else
        raise "connot find job with id #{job_id}"
      end      
    else      
      raise "cannot identify job_id form the file name."      
    end            
  rescue Exception => e
    #log.error("ERROR >>> #{e.message}")
    p "Exception :" + e.message
  end
  
end
