 namespace :medassets do
    desc "Creating MedAssets facilities"    
    #~ Creating MOUNTAINSIDE facility
   
    task :mountainside => :environment do       #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end      
      medassets  = Client.find_by_name("MedAssets")
      if medassets.nil? or medassets.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        medassets = Client.create(:name => "MedAssets", :tat => 42, :partner_id => partner_id)
      end
      mountain_side = Facility.find_by_name("Merit Mountainside")
      if((!medassets.nil? and !medassets.blank?) and (mountain_side.nil? or mountain_side.blank?) )
        Facility.create(:name => "Merit Mountainside", :sitecode => "00891",  :client => medassets,
         :facility_tin => "208489105", :facility_npi => "1982720249", :image_type => "1", :address_one => "1 Bay Ave", 
         :zip_code => "070424837", :city => "Montclair", :state => "NJ", :tat => 0, :lockbox_number => "0")
      end
      #  Creating a predefined payer "PATIENT PAY" for Merit Mountainside patpay output. 
      patient_pay_id = Payer.find(:first, :conditions => ["payer =? and payid =? and payer_type =?","PATIENT PAY","P9998","PatPay"], :select => "id id")
      if mountain_side && !patient_pay_id
        Payer.create(:payer => "PATIENT PAY", :payid => "P9998", :gateway => "client", :payer_type => "PatPay",
        :pay_address_one => mountain_side.address_one, :pay_address_two => mountain_side.address_two, :payer_zip => mountain_side.zip_code, :payer_state => mountain_side.state, :payer_city => mountain_side.city)
        puts "Created the predefined payer 'PATIENT PAY' for Merit Mountainside patpay output."
      end       
       
       
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      mountain_side = "Merit Mountainside"
      system("rake medassets:populate_details['"+mountain_side+"']")

    end   

    task :rumc => :environment do       #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end      
      medassets  = Client.find_by_name("MedAssets")
      if medassets.nil? or medassets.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        medassets = Client.create(:name => "MedAssets", :tat => 42, :partner_id => partner_id)
      end
      rumc = Facility.find_by_name("Richmond University Medical Center")
      if((!medassets.nil? and !medassets.blank?) and (rumc.nil? or rumc.blank?) )
        Facility.create(:name => "Richmond University Medical Center", :sitecode => "RUMC", :client => medassets,
         :facility_tin => "743177454", :facility_npi => "1740389154", :image_type => "0", :address_one => "PO BOX 786051", 
         :zip_code => "19178", :city => "PHILADELPHIA", :state => "PA", :tat => 0, :lockbox_number => "0")
       end 
       
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      rumc = "Richmond University Medical Center"
      system("rake medassets:populate_details['"+rumc+"']")

    end    
    
   #~ The task  'populate_details' Populates the details column of all MedAssets facilities
   #~ It takes the parameters faclity name from the calling statement.

    task :populate_details, [:facility] => [:environment]  do |t, args|
      facility = Facility.find_by_name(args.facility)
      unless facility.nil? and facility.blank?
        facility.details = {}
        facility.details[:hcra] = true
        facility.details[:drg_code] = true
        facility.details[:patient_type] = true
        facility.details[:revenue_code] = true
        facility.details[:payment_code] = true
        facility.details[:claim_type] = true
        facility.details[:reference_code] = false
        if(facility.name == "Merit Mountainside")
          facility.details[:service_date_from] = true
        else
          facility.details[:service_date_from] = false
        end      
        facility.details[:check_date] = true
        facility.details[:payee_name] = true
        facility.details[:cpt_mandatory] = false
        facility.details[:edit_claim_total] = false
        facility.details[:claim_level_dos] = false
        facility.details[:group_code] = false
        facility.details[:late_fee_charge] = false
        facility.details[:rx_code] = false
        facility.details[:deposit_service_date] = false
        facility.details[:expected_payment] = false
        facility.details[:hipaa_code] = false
        facility.details[:interest_in_service_line] = true
        facility.save
      end
    end
    
  end
  
