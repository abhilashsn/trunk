 namespace :anodyne do
    desc "Creating Anodyne facilities"
    #~ Creating Anodyne facility
    
    task :ims => :environment do                                   #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end   
      anodyne = Client.find_by_name("Anodyne")
      if anodyne.nil? or anodyne.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        anodyne = Client.create!(:name=>"Anodyne",:tat=>42,:contracted_tat=>48, :partner_id => partner_id)
      end      
      ims = Facility.find_by_name("INTERNAL MEDICINE SPECIALISTS")
      if((!anodyne.nil? and !anodyne.blank?) and ( ims.nil? or ims.blank? ) )
        Facility.create(:name => "INTERNAL MEDICINE SPECIALISTS", :sitecode => "ims", :client => anodyne,
          :facility_tin => "570724794", :facility_npi => "1801822523", :image_type => "0", :address_one => "PO BOX 37905", 
        :zip_code => "282377805", :city => "Charlotte", :state => "NC", :tat => 0, :lockbox_number => "0")
      end
        
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      ims = "INTERNAL MEDICINE SPECIALISTS"
      system("rake anodyne:populate_details['"+ims+"']")
    end
    
    task :hss => :environment do                                   #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end   
      anodyne = Client.find_by_name("Anodyne")
      if anodyne.nil? or anodyne.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        anodyne = Client.create!(:name=>"Anodyne",:tat=>42,:contracted_tat=>48, :partner_id => partner_id)
      end      
      hss = Facility.find_by_name("HSS RADIOLOGISTS")
      if((!anodyne.nil? and !anodyne.blank?) and ( hss.nil? or hss.blank? ) )
        Facility.create(:name => "HSS RADIOLOGISTS", :sitecode => "hss11", :client => anodyne,
          :facility_tin => "131624135", :facility_npi => "1134139116", :image_type => "1", :tat => 0, :lockbox_number => "0")
      end
        
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      hss = "HSS RADIOLOGISTS"
      system("rake anodyne:populate_details['"+hss+"']")
    end
    
    task :pema => :environment do                                   #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end   
      anodyne = Client.find_by_name("Anodyne")
      if anodyne.nil? or anodyne.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        anodyne = Client.create!(:name=>"Anodyne",:tat=>42,:contracted_tat=>48, :partner_id => partner_id)
      end      
      pema = Facility.find_by_name("PEMA")
      if((!anodyne.nil? and !anodyne.blank?) and ( pema.nil? or pema.blank? ) )
        Facility.create!(:name => "PEMA", :sitecode => "pe11", :client => anodyne, 
        :facility_tin => "570724794", :facility_npi => "1801822523", :image_type => "0", :address_one => "PO BOX 37905", 
        :zip_code => "282377805", :city => "Charlotte", :state => "NC", :tat => 0, :lockbox_number => "0")
      end
        
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      pema = "PEMA"
      system("rake anodyne:populate_details['"+pema+"']")
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
        facility.details[:cpt_mandatory] = false
        facility.details[:edit_claim_total] = false
        facility.details[:claim_level_dos] = false
        facility.details[:group_code] = false
        facility.details[:late_fee_charge] = false
        facility.details[:rx_code] = false
        facility.details[:deposit_service_date] = false
        facility.details[:expected_payment] = false
        facility.details[:hipaa_code] = false
        facility.save
      end
    end
    
  end
  
