require 'fileutils'
require 'csv'

class CSVTransformer 
  # This method triggers the loading process by invoking the process_claim and process_claim_items methods.
    
  def transform(file)
   begin
    temp = 0
    @total_claim_count = 0
    @total_svcline_count = 0
    @loaded_claim_count = 0
    @loaded_svcline_count = 0   
    @file = ""
    @claim_information = ""
     
    CSV.foreach(file, :headers => $CNF['header']) { |row|
      row = row.to_s.split('|') # specific code for MedQuest, MDQ
      if !row.empty? #used to avoid the empty space 
         @file = file
         ClaimInformation.transaction do
          #avoid duplication of claim information, checking based on patient account number
          if row[$CNF['claim']['patient_account_number']] != temp
            @claim_information = ClaimInformation.new
            temp = row[$CNF['claim']['patient_account_number']]                         
            @claim_information = process_claim(row)
            @total_claim_count +=1 
            @total_svcline_count +=1
          else 
            @total_svcline_count +=1
          end
            @claim_information.claim_service_informations << process_claim_service_information(row)
            @claim_information.save!
         end 
      end
    }
  rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
   end  
 end
  
 def claim_file_information_start(load_start_time,size,file_837_name,zip_file_name,file_arrival_time)
    begin 
        facility_id = Facility.find_by_name($CNF['facility_name']).id
        @claim_file_information = ClaimFileInformation.new
        @claim_file_information.size = size
        @claim_file_information.zip_file_name = zip_file_name
        @claim_file_information.arrival_time = file_arrival_time
        @claim_file_information.name = file_837_name
        @claim_file_information.load_start_time = load_start_time
        @claim_file_information.facility_id = facility_id
        @claim_file_information.save!        
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
   end
  end
  
  def claim_file_information_end(load_end_time)    
    # status =""
    # if ((@total_claim_count + @total_svcline_count)-(@loaded_claim_count + @loaded_svcline_count)).eql?(0)
    #  status = "sucess"
    # else
    #  status = "failure"
    # end
    puts "Load End Time : #{load_end_time}"
    puts "Total Claim Count : #{@total_claim_count}"
    puts "Loaded claim Count : #{@loaded_claim_count}"
    puts "Total Service Line : #{@total_svcline_count}"
    puts "Loaded Service Line : #{@loaded_svcline_count}"
    # puts "Status : #{status}"
    
    @claim_file_information.update_attributes(:total_claim_count => @total_claim_count,:loaded_claim_count => @loaded_claim_count,:total_svcline_count => @total_svcline_count,
        :loaded_svcline_count => @loaded_svcline_count,:load_end_time => load_end_time)
    @claim_file_information.save!

  end
    
  # This method processes the claims.
  def process_claim(row)
     begin
        @loaded_claim_count +=1
#        @claim_information.claim_file_information_id = @claim_file_information.id
        @claim_information.facility_id = @claim_file_information.facility_id
       
        if $CNF['patient_details'].eql?(true)
          patient_field_separator($CNF['patient_details_seprator'],$CNF['patient_details_pos'],row[$CNF['patient_details_pos']])
        else
         @claim_information.patient_first_name = row[$CNF['patient_first_name']]
         @claim_information.patient_last_name = row[$CNF['patient_last_name']]
         @claim_information.patient_middle_initial = row[$CNF['patient_middle_initial']]    
       end
        $CNF["claim"].each do |key,value|
            @claim_information[key] = row[value]             
        end
        return @claim_information
    rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
   end
 end
 
 # This method processes the claim service informations.
  def process_claim_service_information(row)    
   begin     
     clm_items = ClaimServiceInformation.new
      @loaded_svcline_count += 1
       $CNF["claim_service"].each do |key,value|
        clm_items[key] = row[value]
      end
    
      return clm_items   
   rescue => err
      puts err.message
      LogManager.log_ror_exception(err,"message")
   end    
  end
  
  def patient_field_separator(sym,pos,row)
     rst = row[pos].split(sym)     
     @claim_information.patient_first_name = rst[$CNF['patient_first_name']]
     @claim_information.patient_last_name = rst[$CNF['patient_last_name']]
     @claim_information.patient_middle_initial = rst[$CNF['patient_middle_initial']]
 end
 
  def get_claim_status(s_time,e_time,file)
    claim_status = Hash.new
    claim_status['load start time'] = s_time
    claim_status['load end time'] = e_time
    claim_status['total_claim_count'] =  @total_claim_count
    claim_status['loaded_claim_count'] = @loaded_claim_count
    claim_status['total_svcline_count'] = @total_svcline_count
    claim_status['loaded_svcline_count'] = @loaded_svcline_count
    claim_status['file_name'] = file    
    
    return claim_status
  end
 
end



