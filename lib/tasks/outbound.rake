namespace :outbound_info do
  desc "rake task for recording outboundfile info"
  task :record => :environment do |t, args|
    begin
      if ENV["posted_at"].blank? || ENV["file"].blank?
        puts "\n..................ERROR....................................."
        puts "Usage:  oubound_info:record posted_at=\"2012-01-24 14:56:14\" file=\"home/user/filename.zip\""
        puts ".................please try again......................................\n"
      else
        if File.exists?(ENV["file"])
          file_name = File.basename(ENV["file"])
          file_size = File.size(ENV["file"])
          tm = ENV["posted_at"]
          oubf = OutboundFileInformation.new({:name=>file_name, :size=>file_size, :status =>"UPLOADING", :sent_at => tm})
          oubf.valid?
          oubf.save
        else
          puts "\n..................ERROR....................................."
          puts "The file #{ENV["file"]} cannot be found...."
          puts ".................please try again......................................\n"
        end
      end
    rescue Exception => e
      puts "Exception ..............." + e.to_s
    end
  end  

  task :uploaded => :environment do |t, args|
    begin
      if ENV["upload_end_time"].blank? || ENV["file"].blank?
        puts "\n..................ERROR....................................."
        puts "Usage:  oubound_info:uploaded upload_end_time=\"2012-01-24 14:56:14\" file=\"home/user/filename.zip\""
        puts ".................please try again......................................\n"
      else
        file_name = File.basename(ENV["file"])
        tm = ENV["upload_end_time"]
        oubf = OutboundFileInformation.where("name = '#{file_name}' AND status = 'UPLOADING' ").first
        if oubf.present?
          oubf.status = "UPLOADED"
          oubf.upload_end_time = tm
          oubf.save
        end        
      end
    rescue Exception => e
      puts "Exception ..............." + e.to_s
    end
  end  

end


