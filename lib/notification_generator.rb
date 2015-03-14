# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This module is used to create notification file after generating all type of output files
# 8th May 2013
# Rajesh R @ Ruby Software
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

NOTIFICATION_PATH = "#{Rails.root}/notification/output"

module NotificationGenerator

  # This method accepts a Hash as input which contains all parameter values required 
  # to be written to notification file
  def NotificationGenerator.create_notification_file (ack_latest_count, notification_params = {})
    begin
      unless notification_params.blank?
        notification_file_name = notification_params[0][:client_name] + "+" + 
          notification_params[0][:facility_name] + "+" + ack_latest_count.to_s + ".csv.ack"
        sub_folder_name = "#{NOTIFICATION_PATH}"
        FileUtils.mkdir_p sub_folder_name
        #header column order "FilePath,FileName,FileFormat,BatchIDs,BatchNames,OutputStartTime,OutputEndTime,Client,Facility \n"
        File.open("#{sub_folder_name}/#{notification_file_name}", 'w+') do |file|
          notification_params.each do |record|
            file_path = record[:file_path]
            file_path = file_path + "/" unless file_path[-1,1] == "/"
            file_name = record[:file_name]
            file_format = record[:file_format]
            batch_id = record[:batch_id]
            batch_name = record[:batch_name]
            output_start_time = record[:output_start_time]
            output_end_time = record[:output_end_time]
            client_name = record[:client_name]
            facility_name = record[:facility_name]

            file << "#{file_path},#{file_name},#{file_format},#{batch_id},#{batch_name},#{output_start_time},#{output_end_time},#{client_name},#{facility_name}\n"
          end
        end  
      end
    rescue => e
      puts "Notification File Creation Failed."
      puts e
    else
      puts "Notification File Generated."
    end
  end
  
end
