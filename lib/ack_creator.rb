#
# This module is used to create acknowledgment file after loading either batch file or 837 file
#
# Rajesh R @ Ruby Software

ACK_PATH = "#{Rails.root}/AckFiles"
CNF_PATH = "#{Rails.root}/lib/yml"

module AckCreator
  def AckCreator.create_ack_file (file_type, md5_hash, file_name)

    begin
      data_load_time = Time.now.in_time_zone("America/New_York")

      time_for_file_content = data_load_time.strftime("%Y-%m-%d %H:%M:%S %z")
      time_for_file_name = data_load_time.strftime("%Y%m%d%H%M%S")
        
      ack_file_name = time_for_file_name + "_" + file_name.gsub('.', '_') + ".ack"

      sub_folder_name = "#{ACK_PATH}/#{file_type}"
      FileUtils.mkdir_p sub_folder_name

      ack_file = File.new("#{sub_folder_name}/#{ack_file_name}", "w")
      ack_file.puts(file_name)
      ack_file.puts(time_for_file_content)
      ack_file.puts(md5_hash)
      puts "ACK File Generated"
    end
  end

  def AckCreator.create_ack_file_for_rmkfi(file_name,file_arrived_time)
    begin
      time_zone = YAML::load(File.open("#{CNF_PATH}/time_zone.yml"))
      file_arrived_time_array = file_arrived_time.split(" ")
      if file_arrived_time_array.size == 3
        begin
          Time.zone = "#{time_zone[file_arrived_time_array[2].to_s]}"
        rescue
          Time.zone = "#{time_zone['EST']}"
        end
        file_arrived_time = file_arrived_time.chomp("#{file_arrived_time_array[2]}")
      else
        Time.zone = "#{time_zone['EST']}"
      end
      file_arrived_time_est =  Time.zone.parse("#{file_arrived_time}")
      Time.zone = "GMT"
      file_arrived_time_in_gmt = Time.zone.parse("#{file_arrived_time_est}")
      ack_file_name = file_name.chomp(".zip").chomp(".ZIP")+".ack"
      ack_file_folder = "#{ACK_PATH}/revenue_management_solutions_llc"
      FileUtils.mkdir_p ack_file_folder
      sub_folder_name = "#{ack_file_folder}/batch"
      FileUtils.mkdir_p sub_folder_name
      ack_file = File.new("#{sub_folder_name}/#{ack_file_name}", "w")
      ack_file.puts('<?xml version="1.0" encoding="UTF-8"?>')
      ack_file.puts("<Batch ReceivedTime=\"#{file_arrived_time_in_gmt.to_s.chomp(" +0000")}\"/>")
      puts "ACK File Generated"
    end
  end
  
  def AckCreator.create_ack_file_for_eras (file_type, md5_hash, file_name, sftp_location, status)

    begin
      data_load_time = Time.now.in_time_zone("America/New_York")

      time_for_file_content = data_load_time.strftime("%Y-%m-%d %H:%M:%S %z")
      time_for_file_name = data_load_time.strftime("%Y%m%d%H%M%S")
        
      ack_file_name = time_for_file_name + "_" + file_name.gsub('.', '_') + ".ack"

      sub_folder_name = "#{ACK_PATH}/#{file_type}"
      FileUtils.mkdir_p sub_folder_name

      ack_file = File.new("#{sub_folder_name}/#{ack_file_name}", "w")
      ack_file.puts(file_name)
      ack_file.puts(time_for_file_content)
      ack_file.puts(md5_hash)
      ack_file.puts(sftp_location)
      ack_file.puts(status)
      puts "ACK File Generated"
    end
  end

end
