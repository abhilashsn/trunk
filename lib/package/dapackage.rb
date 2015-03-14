module Dapackage
  class DaPackage
    def initialize
       @archive_directory = Rails.root.to_s + "/Archive/#{Time.now.strftime("%Y%m%d")}/DAPackage"
       @dapack_directory = Rails.root.to_s + "/Archive/#{Time.now.strftime("%Y%m%d")}/DAPack"
       system "mkdir -p #{@archive_directory} #{@dapack_directory}"
    end

    def generate
      #get_claim_files
      group_claim_and_create_da_package
    end
    
    #this query will update the missing facility_id in the claim_file_information attributes
    def update_facility_id_for_missing_table
      sql=<<-ESQL
      update  claim_file_informations cfi, claim_informations ci 
      set cfi.facility_id = ci.facility_id
      where ci.claim_file_information_id = cfi.id and cfi.facility_id is null
      ESQL
      ClaimFileInformation.connection.execute(sql)
    end

    def group_claim_and_create_da_package
      update_facility_id_for_missing_table
      ids = ClaimFileInformation.select("facility_id").where("sent_to_ap = 0 AND bill_print_date is not null").all.map{|j| j.facility_id}.uniq.compact
      ids.each do |id|
        facility = Facility.find(id)
        claim_files = ClaimFileInformation.where("facility_id = ? AND sent_to_ap = ? AND bill_print_date is not null", id, 0).includes(:inbound_file_information)
        claim_files_grouped = claim_files.group_by{|j| j.bill_print_date}
        j=0

        claim_files_grouped.each do |key,values|          
          create_da_package facility, key, values
          j=j+1
        end
      end      
    end


    def create_da_package facility, bill_print_date, claim_files
      Dir.chdir("#{@dapack_directory}")
      puts `pwd`
      puts `ls`
      system "rm -rf *"
      date = Time.now.strftime('%Y%m%d')
      time = Time.now.strftime('%H%M%S')
      bill_date = bill_print_date.strftime("%y%m%d")
      #seq_number = OutputActivityLog.where("file_format='DA'").count % 1679616
      #seq_number = seq_number.to_s(36)
      #seq_number = OutputActivityLog.where("file_format='DA' AND start_time LIKE %#{Date.today}%").count % 99
      seq_number = (OutputActivityLog.where("file_format='DA' AND date_format(start_time, '%Y-%m-%d')='#{Date.today}'").count % 99) + 1
      seq_number = seq_number.to_s
      #seq_number = seq_number.to_s(36)
      unless claim_files.empty?
       csv_file_name = create_file_name(bill_date,date, time, seq_number,facility.sitecode)
       output_activity_info = OutputActivityLog.create(:start_time => Time.now, :estimated_end_time => estimated_completion_time)

       CSV.open("#{@dapack_directory}/#{csv_file_name}.csv", "w") do |csv|
         csv << ["File name","File size","File type","Site Number","Effective Date","Claim File Type"]
         claim_files.each do |file|
            site_number = facility.sitecode
            file_name = file.name.split(".xml").first
            file_location = file.inbound_file_information.file_path rescue "Exception"
            FileUtils.cp("#{file_location}/#{file_name}","#{@dapack_directory}")
            ext = File.extname(file_name)
            system("zip -m #{file_name.gsub(ext, ext+".ZIP")} #{file_name}")
            file_size = File.size?("#{@dapack_directory}/#{file_name.gsub(ext, ext+".ZIP")}")
            csv << ["#{file_name.gsub(ext, ext+".ZIP")}",file_size,"MPI",site_number,file.bill_print_date.strftime("%Y-%m-%d"), file.claim_file_type]
            file.sent_to_ap = true 
            file.output_activity_log_id = output_activity_info.id
            file.save!
         end
       end
        
       zip_file_name = "#{csv_file_name}.ZIP"
       output_activity_info.update_attributes(:file_name => zip_file_name, :file_format => "DA", :end_time => Time.now)
       system "zip -D \"#{@archive_directory}/#{create_file_name(bill_date,date, time, seq_number, facility.sitecode)}\" *"
       system "rm -rf *"
       puts "The files are moved for the DA packaging...."        
     else
       puts "No files are in Queue for the DA packaging....."
     end
    end


    def estimated_completion_time
      Time.now + 100
    end

    def create_file_name(bill_date,date, time, seq_number,site_code)
      "DA_MPI_RM_#{bill_date}#{seq_number.rjust(2,"0")}#{site_code}_#{date}_#{time}"      
    end

  end
end
