# This script is for marking claim file arrival and claim loading
# two seperate calls of the same script is needed with option as mark_arrival or load, the first is for marking the arrival
# the second call is triggered when the zip has been extracted and the calim xml file
# is place in the appropriate directory at which point and entry is made into the
# delayed jobs column to actually load the file
require File.expand_path(File.dirname(__FILE__)) + "/batchloading/common.rb"
options = {}
require File.expand_path(File.dirname(__FILE__)) + "/../lib/utils/rr_logger"

arguements = ARGV.join(' ')
optparse = OptionParser.new do|opts|
             opts.banner = "Usage: import_claim [options]" 
             
             opts.on( '-f', '--file  FILE', 'Claim File Name' ) do |file|
               options[:file] = file
             end
              
             opts.on( '-l', '--sitecode  SITECODE', 'Facility Sitecode' ) do |site_code|
               options[:site_code] = site_code
             end

             opts.on( '-s', '--size  SIZE', 'size' ) do |size|
               options[:size] = size
             end

             opts.on( '-t', '--time TIME', 'File Arrival Time' ) do |time|
               options[:time] = time 
             end

             opts.on( '-c', '--file_count FILE_COUNT', 'File count' ) do |file_count|
               options[:file_count] = file_count
             end

             opts.on( '-p', '--file_path FILE_PATH', 'File Location' ) do |file_path|
               options[:file_path] = file_path
             end

             opts.on( '-o', '--option OPTION' , 'Option Mark or Load') do |option|
               options[:option] = option    
             end

             opts.on( '-h', '--help', 'Display this screen' ) do
               puts opts
               exit
             end
           end.parse!

unless options[:file] && options[:site_code] &&options[:time] && options[:size] && options[:file_count] && options[:file_path] && options[:option]
  
  puts "file, site_code, size, time, size and file_count and file_path are mandatory"
  puts "also pass the option as \"mark_arrival\" to mark file arrival or \"load\" to make an entry in the delayed job"
  puts "Run 'ruby script/import_claim.rb -h' for help "
  
else
  
  begin
    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/helper"    
    log = setup_logger
    log.debug("===================================================================")
    log.debug("COMMAND >>> ruby script/import_claim.rb #{arguements}")

    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/db"
    make_connection              

    result = querydb("select id from facilities where sitecode='#{options[:site_code]}'")
    facility_id = result.fetch_row.to_a.join
    raise "Facility cannot be found with the given sitecode #{options[:site_code]}" if facility_id.empty?    

    options[:time] =  time_str_convert(options[:time])
    arrival_date = Date.parse(options[:time])
    
    if options[:option] == 'mark_arrival'
      querydb("INSERT INTO inbound_file_informations(name,size,arrival_time,arrival_date,file_type,status,count,facility_id,file_path,secondary_status) VALUES ('#{options[:file]}','#{options[:size]}','#{options[:time]}','#{arrival_date}','claim', 'ARRIVED', '#{options[:file_count]}', '#{facility_id}', '#{options[:file_path]}', 'ONTIME')")
    elsif options[:option] == 'load'
      result = querydb("SELECT * FROM inbound_file_informations where facility_id = '#{facility_id}' AND 
                         arrival_time = '#{options[:time]}' AND name = '#{options[:file]}' ORDER BY  id DESC LIMIT 1")
      
      inbound_id = nil
      if result.num_rows == 1
        inbound_id = result.fetch_hash["id"]
      end
      raise "Cannot uniquely find an inbound_file_information record to load claim file" if inbound_id.nil?
      querydb("INSERT INTO delayed_jobs(handler,run_at,queue) VALUES('--- !ruby/object:ClaimLoader\ninbound_info_id: #{inbound_id}\n', 0, 'claim_loading')")
    end    
  rescue Exception => e
    log.error("ERROR >>> #{e.message}")
    p "Exception :" + e.message
  end  
end
