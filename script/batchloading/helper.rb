def get_facility facility_id
  sql ="SELECT * from facilities where id = '#{facility_id}'"
  result = querydb sql
  if result.count == 1
    result_hash = result.first #fetch_hash
    result_hash["file_arrival_threshold"] ||= 1
    result_hash
  else
    {}
  end  
end

def get_client facility
  sql ="SELECT * from clients where id = '#{facility["client_id"]}'"
  result = querydb sql
  if result.count == 1
    result_hash = result.first # fetch_hash
    result_hash["file_arrival_threshold"] ||= 1
    result_hash
  else
    {}
  end  
end


def find_planned_file batchdate, facility,lockbox_number
  facility_id = facility["id"]
  if lockbox_number.nil?
  sql ="SELECT * FROM inbound_file_informations where facility_id = '#{facility_id}' AND date_format(batchdate,'%Y-%m-%d') = '#{batchdate}' AND name is null AND file_type ='LOCKBOX' AND 
        status = '#{InboundStatus::FILE_PENDING}' AND lockbox_number is NULL ORDER by cut LIMIT 1"
    
  else
  sql ="SELECT * FROM inbound_file_informations where facility_id = '#{facility_id}' AND date_format(batchdate,'%Y-%m-%d') = '#{batchdate}' AND name is null AND file_type ='LOCKBOX' AND 
        status = '#{InboundStatus::FILE_PENDING}' AND lockbox_number = '#{lockbox_number}' ORDER by cut LIMIT 1"
  end

  result = querydb sql
  if result.count == 1
    result_hash = result.first #fetch_hash
    # result_hash["expected_start_time"] = Time.parse(result_hash["expected_start_time"]) rescue nil
    # result_hash["expected_end_time"] = Time.parse(result_hash["expected_end_time"]) rescue nil
    # result_hash["batchdate"] = Date.parse(result_hash["batchdate"]) rescue nil
    result_hash
  else
    {}
  end
end



def update_planned_file planned_file, options
  arrival_timestamp = Time.parse(options[:arrival_time])
  arrival_time = arrival_timestamp.strftime("%Y-%m-%d %H:%M:%S")
  arrival_date = arrival_timestamp.strftime("%Y-%m-%d")
  expected_start_time = planned_file["expected_start_time"]
  expected_end_time = planned_file["expected_end_time"]
  secondary_status = InboundStatus::ARRIVAL_ONTIME
  if arrival_timestamp < expected_start_time
    secondary_status = InboundStatus::ARRIVAL_EARLY
  elsif arrival_timestamp > expected_end_time
    secondary_status = InboundStatus::ARRIVAL_LATE
  end
  sql ="UPDATE inbound_file_informations SET name = '#{options[:filename]}',
    size = '#{options[:size]}',arrival_time = '#{options[:arrival_time]}', arrival_date = '#{options[:arrival_time]}',
    file_path = '#{options[:location]}', status = '#{InboundStatus::FILE_ARRIVED}',
    secondary_status = '#{secondary_status}'
    WHERE
    id = '#{planned_file["id"]}'"
  
  result =  querydb sql

  sql ="SELECT * FROM inbound_file_informations where id = '#{planned_file["id"]}'"

  result =  querydb sql  
  result.first # fetch_hash
end


def create_extra_file batchdate, options, facility_id, lockbox, lockbox_name
  lockbox = 'NULL' if lockbox.nil?
  lockbox_name = 'NULL' if lockbox_name.nil?
  arrival_timestamp = Time.parse(options[:arrival_time])
  arrival_time = arrival_timestamp.strftime("%Y-%m-%d %H:%M:%S")
  arrival_date = arrival_timestamp.strftime("%Y-%m-%d")  
  arrival_date = Time.parse(arrival_date + " 00:00:00").utc.strftime("%Y-%m-%d %H:%M:%S")
  
  sql = "SELECT cut from inbound_file_informations where batchdate='#{batchdate}' AND file_type ='LOCKBOX'  AND facility_id = '#{facility_id}' AND cut is not NULL  ORDER BY id DESC limit 1"
  
  result = querydb sql
  cut = "A"
  unless result.count == 0
    cut = result.first["cut"].next
  end
  
  sql = "INSERT into inbound_file_informations (name, size, file_path,batchdate, cut, facility_id, arrival_time, arrival_date, status, secondary_status, file_type, lockbox_number, lockbox_name, expected_arrival_date) 
        values('#{options[:filename]}','#{options[:size]}', '#{options[:location]}','#{batchdate}','#{cut}','#{facility_id}','#{arrival_time}',
               '#{arrival_date}', '#{InboundStatus::FILE_ARRIVED}', '#{InboundStatus::FILE_EXTRA}', 'LOCKBOX', '#{lockbox}', '#{lockbox_name}', '#{arrival_date}' )"
  
  result = querydb sql

#  {"id"=>@db.insert_id}  
  {"id"=>@db.last_id}  


end 

def time_str_convert str, zonestr=nil, informat=nil, outformat=nil
  informat =  "%Y-%m-%d %H:%M:%S" if informat.nil?
  outformat = "%Y-%m-%d %H:%M:%S" if outformat.nil?
#  zonestr = "EST" if zonestr.nil?
  Time.strptime( (str + " #{zonestr}"), informat).utc.strftime(outformat)
#  Time.strptime( (str + " #{zonestr}"), informat).strftime(outformat)
end

def setup_logger
  dname = "log/#{Date.today.strftime("%Y%m%d")}/scripts"
  FileUtils.mkdir_p(dname) unless File.directory?(dname)
  log_file = File.open("#{dname}/standalone.log",'a')
  log = Logger.new(log_file)
  log.level = Logger::DEBUG
  return log
end
