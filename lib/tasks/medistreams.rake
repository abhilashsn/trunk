 namespace :medistreams do
    desc "Creating Medistreams facilities"
    #~ Creating Medistreams facility
    
    task :kinematic => :environment do                                   #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end   
      medistreams = Client.find_by_name("Medistreams")
      if medistreams.nil? or medistreams.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        medistreams = Client.create(:name=>"Medistreams", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end      
      kinematic = Facility.find_by_name("KINEMATIC CONCEPTS PHYSICAL THERAPY AND SPORTS REHAB")
      if((!medistreams.nil? and !medistreams.blank?) and ( kinematic.nil? or kinematic.blank? ) )
        Facility.create( :name => "KINEMATIC CONCEPTS PHYSICAL THERAPY AND SPORTS REHAB", :sitecode => "CSI_KIN",  :client => medistreams, 
        :facility_tin => "330997613", :facility_npi => "1285764936", :image_type => "1", :address_one => "12918 BANDERA RD", 
        :zip_code => "780234002", :city => "HELOTES", :state => "TX", :tat => 0, :lockbox_number => "0" )
      end
        
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      kinematic = "KINEMATIC CONCEPTS PHYSICAL THERAPY AND SPORTS REHAB"
      system("rake medistreams:populate_details['"+kinematic+"']")
    end
    
    task :nbs => :environment do                                   #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end   
      medistreams = Client.find_by_name("Medistreams")
      if medistreams.nil? or medistreams.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        medistreams = Client.create(:name=>"Medistreams", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end      
      nbs = Facility.find_by_name("New Braunfels Sports and Spine Physical Therapy")
      if((!medistreams.nil? and !medistreams.blank?) and ( nbs.nil? or nbs.blank? ) )
        Facility.create( :name => "New Braunfels Sports and Spine Physical Therapy", :sitecode => "CSI-NBS", :client => medistreams,
        :image_type => "1", :facility_tin => "208648765", :facility_npi => "1891817714", :address_one => "1528 E COMMON ST", 
        :zip_code => "781303337", :city => "NEW BRAUNFELS", :state => "TX" , :tat => 0, :lockbox_number => "0" )
      end
        
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      nbs = "New Braunfels Sports and Spine Physical Therapy"
      system("rake medistreams:populate_details['"+nbs+"']")
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
        facility.details[:reference_code] = true
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
        facility.save
      end
    end
    
  end
  
