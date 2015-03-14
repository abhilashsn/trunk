namespace :web_services_mock_data do  
  desc "Mock micr to create a dummy micr/payer record for testing"
  task :mock_micr_payer => :environment do
    batch = Batch.find_by_batchid("123_MOCK")
    unless batch
      batch = Batch.last.clone
      batch.batchid = "123_MOCK"
      batch.save
      batch.jobs << Job.last.clone
    end
    
    if batch && batch.jobs.present? 
      c = CheckInformation.last.clone
      c.job_id = batch.jobs.last.id
      c.payer = mock_payer_and_micr      
      c.save        
    else
      puts "cannot continue unable to mock batch!"
    end    
  end
end

def mock_payer_and_micr
  p = Payer.last.clone
  count = Payer.calculate(:count, :all, :conditions => ["payid  = ?",'123_MOCK'])
  p.payid = ENV["payid"] || "123_MOCK"
  p.payer = ENV["payer"] || "123_MOCK_#{count}"
  p.status = "CLASSIFIED"
  
  if p.save
    m = MicrLineInformation.last.clone
    m.payer = p
    m.status = "NEW"
    a = ENV["aba_routing_number"] || rand(10000000000)      
    b = ENV["payer_account_number"] || rand(10000000000)      

    unless MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(a,b)
      
    else
      begin
        a , b = rand(10000000000), rand(10000000000)      
      end while  MicrLineInformation.find_by_aba_routing_number_and_payer_account_number(a,b)
    end

    m.aba_routing_number = a
    m.payer_account_number = b
    if m.save
      #puts "saveddddddddddd"
    else
      puts m.errors.full_messages.join("\n")
    end
  end    
  p
end
