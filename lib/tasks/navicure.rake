 namespace :navicure do
    desc "Creating Navicure facilities"
    
    task :oklahoma => :environment do            #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat => 48, :contracted_tat => 20, :partner_id => partner_id)
      end      
      oklahoma = Facility.find_by_name("OKLAHOMA CARDIOVASCULAR ASSOC")
      if((!navicure.nil? and !navicure.blank?) and (oklahoma.nil? or oklahoma.blank?) )
        Facility.create( :name => "OKLAHOMA CARDIOVASCULAR ASSOC", :sitecode => "2TR6089Q",  :client => navicure,
        :facility_tin => "731515340", :facility_npi => "1437130069", :image_type => "1", :address_one => "PO BOX 268842", 
        :zip_code => "73126", :city => "OKLAHOMA CITY", :state => "OK", :tat => 0, :lockbox_number => "0" )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      oklahoma = 'OKLAHOMA CARDIOVASCULAR ASSOC'
      system("rake navicure:populate_details['"+oklahoma+"']")
    end
  
    task :clinix => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      clinix = Facility.find_by_name("CLINIX HEALTH SERVICES OF CO INC")   
      if((!navicure.nil? and !navicure.blank?) and (clinix.nil? or clinix.blank?) )
        Facility.create( :name => "CLINIX HEALTH SERVICES OF CO INC", :sitecode => "S7580852",  :client => navicure,
          :facility_tin => "841531327", :facility_npi => "1912011073", :image_type => "1", :address_one => "7030 S YOSEMITE STREET", 
          :zip_code => "80112", :city => "CENTENNIAL", :state => "CO", :tat => 0, :lockbox_number => "0"  )
      end    
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      clinix = 'CLINIX HEALTH SERVICES OF CO INC'
      system("rake navicure:populate_details['"+clinix+"']")
    end
    
    task :southcoast => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      southcoast = Facility.find_by_name("SOUTH COAST")
      if((!navicure.nil? and !navicure.blank?) and (southcoast.nil? or southcoast.blank?) )
        Facility.create( :name => "SOUTH COAST", :sitecode => "w1PQ082g",  :client => navicure,
          :facility_tin => "582194871", :facility_npi => "1467451922", :image_type => "1", :address_one => "PO Box 15909", 
          :zip_code => "314162609" , :city => "Savannah", :state => "GA", :tat => 0, :lockbox_number => "0" )
      end    
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      southcoast = 'SOUTH COAST'
      system("rake navicure:populate_details['"+southcoast+"']")
    end

    task :shepherd => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end
      shepherd = Facility.find_by_name("SHEPHERD VSP")
      if((!navicure.nil? and !navicure.blank?) and (shepherd.nil? or shepherd.blank?) )
        Facility.create( :name => "SHEPHERD VSP", :sitecode => "1cQC056g",  :client => navicure,
          :facility_tin => "880107297", :facility_npi => "1487604054", :image_type => "0", :address_one => "3575 PECOS MCLEOD",
          :zip_code => "89160", :city => "LAS VEGAS", :state => "NV", :tat => 0, :lockbox_number => "0"  )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      shepherd = 'SHEPHERD VSP'
      system("rake navicure:populate_details['"+shepherd+"']")
    end
    
    task :horizon_eye => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      horizon_eye = Facility.find_by_name("HORIZON EYE")   
      if((!navicure.nil? and !navicure.blank?) and (horizon_eye.nil? or horizon_eye.blank?) )
        Facility.create( :name => "HORIZON EYE", :sitecode => "G51Y062K",  :client => navicure, 
        :facility_tin => "562052180", :facility_npi => "1235192113", :image_type => "1", :address_one => "135 S SHARON AMITY CHARLOTTE NC 28211", 
        :zip_code => "28211", :city => "CHARLOTTE", :state => "NC", :tat => 0, :lockbox_number => "0"  )
      end    
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      horizon_eye = 'HORIZON EYE'
      system("rake navicure:populate_details['"+horizon_eye+"']")
    end
    
    task :savannah_primary => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      savannah_primary = Facility.find_by_name("SAVANNAH PRIMARY CARE")   
      if((!navicure.nil? and !navicure.blank?) and (savannah_primary.nil? or savannah_primary.blank?) )
        Facility.create( :name => "SAVANNAH PRIMARY CARE", :sitecode => "wZR8083H",  :client => navicure,
        :facility_tin => "020695029", :facility_npi => "1588663058", :image_type => "1", :address_one => "1326 EISENHOWER DR STE D", 
        :zip_code => "31406", :city => "SAVANNAH", :state => "GA", :tat => 0, :lockbox_number => "0"  )
      end    
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      savannah_primary = 'SAVANNAH PRIMARY CARE'
      system("rake navicure:populate_details['"+savannah_primary+"']")
    end 

    task :savannah_surgical => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      savannah_surgical = Facility.find_by_name("SAVANNAH SURGICAL ONCOLOGY")   
      if((!navicure.nil? and !navicure.blank?) and (savannah_surgical.nil? or savannah_surgical.blank?) )
        Facility.create( :name => "SAVANNAH SURGICAL ONCOLOGY", :sitecode => "wZR9083H", :client => navicure,
        :facility_tin => "581599993", :facility_npi => "1275532756", :image_type => "1", :address_one => "7001 HODGSON MEMORIAL DR STE 1", 
        :zip_code => "31406", :city => "Savannah", :state => "GA", :tat => 0, :lockbox_number => "0"  )
      end    
      
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      savannah_surgical = 'SAVANNAH SURGICAL ONCOLOGY'
      system("rake navicure:populate_details['"+savannah_surgical+"']")
    end
    
    task :orthopaedic => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      orthopaedic = Facility.find_by_name("ORTHOPAEDIC FOOT AND ANKLE CTR")   
      if((!navicure.nil? and !navicure.blank?) and (orthopaedic.nil? or orthopaedic.blank?) )
        Facility.create( :name => "ORTHOPAEDIC FOOT AND ANKLE CTR", :sitecode => "wbRB083H", :client => navicure,
        :facility_tin => "521672232", :facility_npi => "1952396764", :image_type => "1", :address_one => "6715 FORREST PARK DR", 
        :zip_code => "31406", :city => "Savannah", :state => "GA", :tat => 0, :lockbox_number => "0"  )
      end    
      
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      orthopaedic = 'ORTHOPAEDIC FOOT AND ANKLE CTR'
      system("rake navicure:populate_details['"+orthopaedic+"']")
    end 

    task :georgia_ear => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      georgia_ear = Facility.find_by_name("GEORGIA EAR ASSOCIATES")   
      if((!navicure.nil? and !navicure.blank?) and (georgia_ear.nil? or georgia_ear.blank?) )
        Facility.create( :name => "GEORGIA EAR ASSOCIATES", :sitecode => "bCNY071Y",  :client => navicure,
        :facility_tin => "200232725", :facility_npi => "1316084122", :image_type => "1", :address_one => "PO Box 3720  SAVANNAH GA 31414", 
        :zip_code => "31406", :city => "SAVANNAH", :state => "GA", :tat => 0, :lockbox_number => "0"  )
      end    
      
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      georgia_ear = 'GEORGIA EAR ASSOCIATES'
      system("rake navicure:populate_details['"+georgia_ear+"']")
    end
    
    task :chatham => :environment do                          #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end    
      chatham = Facility.find_by_name("CHATHAM HOSPITALISTS")   
      if((!navicure.nil? and !navicure.blank?) and (chatham.nil? or chatham.blank?) )
        Facility.create( :name => "CHATHAM HOSPITALISTS", :sitecode => "n55Q078S",  :client => navicure,
        :facility_tin => "020695029", :facility_npi => "1588663058", :image_type => "1", :address_one => "5354 REYNOLDS STREET STE 434", 
        :zip_code => "31406", :city => "SAVANNAH", :state => "GA", :tat => 0, :lockbox_number => "0"  )
      end    
      
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      chatham = 'CHATHAM HOSPITALISTS'
      system("rake navicure:populate_details['"+chatham+"']")
    end
    
    task :urology_pediatric => :environment do            #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end
      urology_pediatric = Facility.find_by_name("UROLOGY SPEC PEDIATRIC")
      if((!navicure.nil? and !navicure.blank?) and (urology_pediatric.nil? or urology_pediatric.blank?) )
        Facility.create( :name => "UROLOGY SPEC PEDIATRIC", :sitecode => "LBCH063W",  :client => navicure,
        :facility_tin => "205142895", :facility_npi => "1730142753", :image_type => "1", :address_one => "5701 W CHARLESTON BLVD STE 201",
        :zip_code => "89146", :city => "LAS VEGAS", :state => "NV", :tat => 0, :lockbox_number => "0" )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      urology_pediatric = 'UROLOGY SPEC PEDIATRIC'
      system("rake navicure:populate_details['"+urology_pediatric+"']")
    end     

    task :urology_california => :environment do            #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end
      urology_california = Facility.find_by_name("UROLOGY ASSOC OF CENTRAL CALIFORNIA")
      if((!navicure.nil? and !navicure.blank?) and (urology_california.nil? or urology_california.blank?) )
        Facility.create( :name => "UROLOGY ASSOC OF CENTRAL CALIFORNIA", :sitecode => "2dKR087Y",  :client => navicure,
        :facility_tin => "770361443", :facility_npi => "1194720722", :image_type => "1", :address_one => "7014 N WHITNEY STREET FRESNO",
        :zip_code => "93720", :city => "California", :state => "CA", :tat => 0, :lockbox_number => "0" )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      urology_california = 'UROLOGY ASSOC OF CENTRAL CALIFORNIA'
      system("rake navicure:populate_details['"+urology_california+"']")
    end
    
    task :urology_nevada => :environment do            #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end
      urology_nevada = Facility.find_by_name("UROLOGY SPEC OF NV")
      if((!navicure.nil? and !navicure.blank?) and (urology_nevada.nil? or urology_nevada.blank?) )
        Facility.create( :name => "UROLOGY SPEC OF NV", :sitecode => "LBCH063W",  :client => navicure,
        :facility_tin => "880310956", :facility_npi => "1063458594", :image_type => "1", :address_one => "5701 W CHARLESTON BLVD STE 201",
        :zip_code => "89146", :city => "LAS VEGAS", :state => "NV", :tat => 0, :lockbox_number => "0" )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      urology_nevada = 'UROLOGY SPEC OF NV'
      system("rake navicure:populate_details['"+urology_nevada+"']")
    end    
    
    task :lincoln => :environment do            #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end
      lincoln = Facility.find_by_name("LINCOLN HOSP DISTRICT 3")
      if((!navicure.nil? and !navicure.blank?) and (lincoln.nil? or lincoln.blank?) )
        Facility.create( :name => "LINCOLN HOSP DISTRICT 3", :sitecode => "KQTS0779",  :client => navicure,
        :facility_tin => "910758051", :facility_npi => "1841234598", :image_type => "1", :address_one => "100 3RD ST STE 1",
        :zip_code => "99122", :city => "DAVENPORT", :state => "WA", :tat => 0, :lockbox_number => "0" )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      lincoln = 'LINCOLN HOSP DISTRICT 3'
      system("rake navicure:populate_details['"+lincoln+"']")
    end
    
    task :cmed => :environment do            #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      navicure  = Client.find_by_name("Navicure")
      if navicure.nil? or navicure.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        navicure = Client.create(:name=>"Navicure", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end
      cmed = Facility.find_by_name("CENTER FOR MEDICINE ENDOCRINOLOGY AND DIABETES")
      if((!navicure.nil? and !navicure.blank?) and (cmed.nil? or cmed.blank?) )
        Facility.create( :name => "CENTER FOR MEDICINE ENDOCRINOLOGY AND DIABETES", :sitecode => "TJLK0827",  :client => navicure,
        :facility_tin => "582356591", :facility_npi => "1639289515", :image_type => "1", :address_one => "5667 PEACHTREE DUNWOODY RD STE 150",
        :zip_code => "30319", :city => "Atlanta", :state => "GA", :tat => 0, :lockbox_number => "0" )
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      cmed = 'CENTER FOR MEDICINE ENDOCRINOLOGY AND DIABETES'
      system("rake navicure:populate_details['"+cmed+"']")
    end    
  
    #~ The task  'populate_details' Populates the details column of all MedAssets facilities
    #~ It takes the parameters faclity name from the calling statement.
     
    task :populate_details, [:facility] => [:environment]  do |t, args|
      facility = Facility.find_by_name(args.facility)
      unless facility.nil? and facility.blank?
        facility.details = {}
        facility.details[:hcra] = false
        facility.details[:drg_code] = false
        facility.details[:patient_type] = false
        facility.details[:revenue_code] = false
        facility.details[:payment_code] = false
        facility.details[:claim_type] = true
        facility.details[:reference_code] = false
        facility.details[:service_date_from] = true
        facility.details[:check_date] = true
        facility.details[:payee_name] = true
        facility.details[:cpt_mandatory] = true
        facility.details[:edit_claim_total] = true
        facility.details[:claim_level_dos] = true
        facility.details[:group_code] = false
        facility.details[:late_fee_charge] = false
        facility.details[:rx_code] = false
        facility.details[:deposit_service_date] = false
        facility.details[:expected_payment] = false
        facility.details[:hipaa_code] = true
        if(facility.name == "OKLAHOMA CARDIOVASCULAR ASSOC")
          facility.details[:patient_account_number_hyphen_format] = true
        end        
        facility.save
      end
    end 
  
end
