# This script is for adding batch loading jobs to delayed_jobs queue
require File.expand_path(File.dirname(__FILE__)) + "/batchloading/common.rb"
@options = {}
require File.expand_path(File.dirname(__FILE__)) + "/../lib/utils/rr_logger"

arguements = ARGV.join(' ')
optparse = OptionParser.new do|opts|
  opts.banner = "Usage: import_batch_file.rb [options]"
 
  opts.on( '-z', '--zip FILE', 'Zip file name' ) do |file|
    @options[:filename] = file
  end
 
  opts.on( '-l', '--location LOCATION', 'Zip file location' ) do|loc|
    @options[:location] = loc
  end

  opts.on( '-t', '--time TIME', 'File arrival time' ) do|time|
    @options[:arrival_time] = time
  end

  opts.on( '-s', '--size [SIZE]', 'Zip file size' ) do|size|
    @options[:size] = size
  end
             
  opts.on( '-f', '--facility [FACILITY]', 'It is a text [PDS/TEST] to indicate loading style. This is ignored in Bank import.' ) do |facility|
    @options[:facility] = facility
  end
  
  opts.on( '-d', '--batchdt BATCH DATE', 'Batch Date in YYYY-MM-DD' ) do |batchdt|
    @options[:batchdt] = batchdt
  end
   
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end.parse!

begin
  require File.expand_path(File.dirname(__FILE__)) + "/batchloading/helper"
  log = setup_logger
  log.debug("===================================================================")
  log.debug("COMMAND >>> ruby script/import_batch_file.rb #{arguements}")
  
  #lock_file.flock(File::LOCK_EX) if lock_file
  unless @options[:filename] && @options[:location] && @options[:arrival_time]
    log.error("ERRROR >>> Missing some Mandatory options in the script")
    puts "filename, location and  arrival_time are mandatory options .. Please provide all these"
    puts "Run 'ruby script/import_batch_file.rb -h' for help "
  else
    
    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/db"
    make_connection
    require File.expand_path(File.dirname(__FILE__)) + "/batchloading/helper"
    require File.expand_path(File.dirname(__FILE__)) + "/indexfile_identifier"
    require File.expand_path(File.dirname(__FILE__)) + "/../lib/lockbox/identification"
    require File.expand_path(File.dirname(__FILE__)) + "/../app/models/inbound_status"
    
    facility = nil
    inbount_id = nil
    facility_id = 'NULL'
    batchdate = Date.today.to_s # to be found
    lockbox_number = nil
    lockbox_name = nil
    
    #converting EST to UTC time
    @options[:arrival_time] =  time_str_convert(@options[:arrival_time])
     @orbo_facility_array = ["ORB TEST FACILITY","ORBOGRAPH","GULF IMAGING ASSOCIATES","THE GEORGE WASH UNIV MFA","SOUTH NASSAU COMMUNITY HOSPITAL"]
    if @options[:facility]
      if @options[:facility].upcase == "PDS"
        lockbox = @options[:filename].split("_").first.scan(/\d+/).first
        result_set = querydb("SELECT facility_id,lockbox_name FROM facility_lockbox_mappings where lockbox_number = '#{lockbox}'")
        result_row = result_set.first #fetch_row
        facility_id = result_row['facility_id'] 
        lockbox_name = result_row['lockbox_name']
        lockbox_number = lockbox
        raise "The facility passed cannot be found in the system " if facility_id.nil?
      elsif @options[:facility].upcase == "TEST"
        lockbox = @options[:filename].split("_").first[3..5]
        result_set = querydb("SELECT facility_id,lockbox_name FROM facility_lockbox_mappings where lockbox_number = '#{lockbox}'")
        result_row = result_set.first #fetch_row
        facility_id = result_row['facility_id'] 
        lockbox_name = result_row['lockbox_name']
        lockbox_number = lockbox
        raise "The facility passed cannot be found in the system " if facility_id.nil?
       elsif @orbo_facility_array.include?(@options[:facility].upcase)
      #elsif (@options[:facility].upcase == "ORB TEST FACILITY" || @options[:facility].upcase == "ORBOGRAPH")
        lockbox = "1"
        result_set = querydb("SELECT facility_id,lockbox_name FROM facility_lockbox_mappings where lockbox_number = '#{lockbox}'")
        result_row = result_set.first #fetch_row
        facility_id = result_row['facility_id']
        lockbox_name = result_row['lockbox_name']
        lockbox_number = lockbox
        raise "The facility passed cannot be found in the system " if facility_id.nil?
     else
        result_set = querydb("SELECT id FROM facilities where name = '#{@options[:facility].upcase}'")
        facility_id = result_set.first['id']
        raise "The facility passed cannot be found in the system .. Please verify the facility name passed is correct" if facility_id.nil?

      end
    else
      lockbox = Lockbox::Identification.new(@options[:filename])
      lockbox.parse
      lockbox_number = lockbox.lockbox || "NULL"
      result_set = querydb("SELECT facility_id, lockbox_name FROM facility_lockbox_mappings where lockbox_number = '#{lockbox_number}'")
      result_row = result_set.first #fetch_row
      facility_id = result_row['facility_id'] 
      lockbox_name = result_row['lockbox_name']
      raise "The facility passed cannot be found in the system " if facility_id.nil?
    end

    facility = get_facility(facility_id)
    client = get_client(facility)
    log.debug("Facility identified: #{facility['name']}")

    if @options[:facility]
      if @options[:facility].upcase == "PDS"
	  batchdate = @options[:batchdt]	
      elsif @options[:facility].upcase == "TEST"
	  batchdate = @options[:batchdt]	
      else
	    index_file_identifier = IndexfileIdentifier.new(facility, client)
	    index_file_pattern = index_file_identifier.find_index_file
	    zip_file = "#{@options[:location]}/#{@options[:filename]}"
	    unzip_loc = File.expand_path(File.dirname(__FILE__)) +"/../tmp/index_files/#{$$}"
	    unless File.exists?(unzip_loc)
	      FileUtils.mkdir_p unzip_loc
	    end
	    system("rm -rf #{unzip_loc}/*")
      
	   # if (@options[:facility].upcase == "ORB TEST FACILITY"  || @options[:facility].upcase == "ORBOGRAPH")
     if @orbo_facility_array.include?(@options[:facility].upcase)
	      system("unzip \"#{zip_file}\" -d \"#{unzip_loc}\"")
	      file_name = @options[:filename].split('.').first.to_s
	      unzip_loc = unzip_loc + "/#{file_name}"
        curr_orbidx = Dir.glob("#{unzip_loc}/*.[O,o][R,r][B,b][O,o][I,i][D,d][X,x]").first
        if curr_orbidx.nil?
          unzip_loc = unzip_loc.split('/')
          unzip_loc.pop
          unzip_loc = unzip_loc.join('/')
          curr_orbidx = Dir.glob("#{unzip_loc}/*.[O,o][R,r][B,b][O,o][I,i][D,d][X,x]").first
        end
		    new_orbidx = "#{unzip_loc}/#{File.basename(curr_orbidx).split('.').first.to_s}.xml"
		    FileUtils.mv(curr_orbidx, new_orbidx)  
		  else
		    system("unzip -C -j #{zip_file} #{index_file_pattern} -d #{unzip_loc}")
      end
	    batchdate = index_file_identifier.parse_index_file unzip_loc
	    log.debug("Batch Date: #{batchdate}")
	    system("rm -rf #{unzip_loc}/*") #remove the index file
      end
   end
    planned_file = find_planned_file batchdate, facility, lockbox_number
    unless planned_file.empty?
      planned_file = update_planned_file  planned_file, @options 
      inbound_id = planned_file["id"]
    else
      extra_file = create_extra_file  batchdate, @options, facility_id , lockbox_number, lockbox_name
      inbound_id = extra_file["id"]
    end       
    raise "Unable to create or find an inbound_file" unless inbound_id
    insert = querydb "INSERT INTO delayed_jobs(handler,run_at,queue) VALUES('--- !ruby/object:BatchLoader\ninbound_info_id: #{inbound_id}\n', 0, 'batch_loading')"
    log.debug("Delayed job inserted at id #{@db.last_id}")
    @db.close
  end

rescue Exception => e
  log.error("ERROR >>> #{e.message}")
  puts e.message
  puts e.backtrace
end



