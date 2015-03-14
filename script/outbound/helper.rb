def get_oal md5sum
  sql = "SELECT * from output_activity_logs where checksum = '#{md5sum}'"
  result = querydb sql
  if result.num_rows > 0
    result_hash = result.fetch_hash
  else
    {}
  end
end

def oal_mark_uploading md5sum, time
  sql = "UPDATE output_activity_logs SET status = 'UPLOADING', upload_start_time = '#{time}' WHERE checksum='#{md5sum}'"
  querydb sql
end

def oal_mark_uploaded md5sum, time
  sql = "UPDATE output_activity_logs SET status = 'UPLOADED', upload_end_time = '#{time}' WHERE checksum='#{md5sum}'"
  querydb sql
end


def time_str_convert str, zonestr=nil, informat=nil, outformat=nil
  informat =  "%Y-%m-%d %H:%M:%S %Z" if informat.nil?
  outformat = "%Y-%m-%d %H:%M:%S" if outformat.nil?
  zonestr = "EST" if zonestr.nil?
  Time.strptime( (str + " #{zonestr}"), informat).utc.strftime(outformat)
end
