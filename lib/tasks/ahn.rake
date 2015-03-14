 namespace :ahn do
    desc "Creating AHN facilities"
    #~ Creating AHN facility
    
    task :ahn => :environment do                                   #Creates the facility without populating the details column
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end   
      ahn_c = Client.find_by_name("AHN")
      if ahn_c.nil? or ahn_c.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        ahn_c = Client.create(:name => "AHN", :tat => 42, :partner_id => partner_id)
      end      
      ahn_f = Facility.find_by_name("AHN")
      if((!ahn_c.nil? and !ahn_c.blank?) and ( ahn_f.nil? or ahn_f.blank? ) )
        Facility.create( :name => "AHN", :sitecode => "G51Y062K",  :client => ahn_c,
          :facility_tin => "352108729", :facility_npi => "1568566743", :image_type => "1", :address_one => "PO BOX 660557",
          :zip_code => "462660001", :city => "INDIANA POLIS", :state => "IN", :tat => 0, :lockbox_number => "0" )
      end
        
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      ahn = "AHN"
      system("rake ahn:populate_details['"+ahn+"']")
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
  
