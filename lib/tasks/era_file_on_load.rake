namespace :era_file_load do

  desc "The task to create the plans for the FM dashboard usage.."
  task :input_eras, [:file_name, :file_size, :file_md5_hash, :file_arrival_time, :sftp_location, :client, :identifier_hash] => [:environment]  do |t, args|
    unless args.file_name || args.file_size || args.file_md5_hash || args.file_arrival_time || args.sftp_location || args.client || args.identifier_hash
      raise "The file name,file size,file_md5_hash,file_arrival_time,sftp location and identifier_hash are mandatory as parameters....An example rake call is given below..\n 'rake era_file_load:input_eras file_name='J70G0604.X67', file_size='6181', file_md5_hash='1e398b3fc1ad81f6da0ec1b611f6b7cc', file_arrival_time='03-07-2013 17:33:28', sftp_location='VM5', client='Benefit Recovery', identifier_hash='f816f9582348a415119d89d2fbfa055b' "
    else
      begin
        client = Client.find_by_name(args.client)
        inbound_file_information = InboundFileInformation.new(:name => args.file_name,:size =>args.file_size,:arrival_time =>Time.strptime(args.file_arrival_time, "%m-%d-%Y %H:%M:%S"),:arrival_date => Date.strptime(args.file_arrival_time, "%m-%d-%Y"),:status =>"ARRIVED",:file_type => "ERA", :client_id => client.id)
        inbound_file_information.save
        era_check=Era.first(:conditions =>{:file_md5_hash =>args.file_md5_hash})
        era=Era.new(:file_md5_hash => args.file_md5_hash, :sftp_location => args.sftp_location, :identifier_hash => args.identifier_hash, :inbound_file_information_id => inbound_file_information.id, :name => args.file_name, :size => args.file_size, :arrival_time => Time.strptime(args.file_arrival_time, "%m-%d-%Y %H:%M:%S"), :arrival_date => Date.strptime(args.file_arrival_time, "%m-%d-%Y"))
        unless era_check.blank?
          era.is_duplicate = true
          era.parent_era_id = era_check.id
          inbound_file_information.update_attributes(:status => "INCOMPLETE")
        end
        today_eras_length = Era.count(:conditions => ["created_at > ?",Time.now.beginning_of_day])
        era.batchid = "#{inbound_file_information.name.split('.')[0]}_#{inbound_file_information.arrival_time.strftime("%m%d%Y%H%M%S")}_#{today_eras_length + 1}"
        era.save

        AckCreator.create_ack_file_for_eras(inbound_file_information.file_type, era.file_md5_hash, inbound_file_information.name, era.sftp_location, inbound_file_information.status)
       
      rescue Exception => e
        puts "The ERA file cannot be loaded as there are some data related issues..."
        puts "The system error which occured is '#{e.message}'"
        Rails.logger.debug "The error occured while creating the ERA today, #{Date.today} was.. \n #{e}"
      end
    end
  end

end
