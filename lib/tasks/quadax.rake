 namespace :quadax do
    desc "Creating QUADAX facilities"
    
    #Creates the facility without populating the details column
    task :pathology_medical_services => :environment do
      partner = Partner.find_by_name("REVENUE MED")
      if partner.nil? or partner.blank?
        partner = Partner.create(:name => "REVENUE MED")
      end
      quadax  = Client.find_by_name("QUADAX")
      if quadax.nil? or quadax.blank?
        partner_id = Partner.find(:first, :conditions => ["name=?", "REVENUE MED"]).id
        quadax = Client.create(:name=>"QUADAX", :tat=>48, :contracted_tat=>20, :partner_id => partner_id)
      end      
      pathology_medical_services = Facility.find_by_name("PATHOLOGY MEDICAL SERVICES")
#      1851455646 = Professional NPI, 1538270772 = Technical NPI
      if((!quadax.nil? and !quadax.blank?) and (pathology_medical_services.nil? or pathology_medical_services.blank?) )
        Facility.create( :name => "PATHOLOGY MEDICAL SERVICES", :sitecode => "PM",  :client => quadax,
        :facility_tin => "470549869", :facility_npi => "1851455646", :image_type => "1", :address_one => "5440 S ST",
        :address_two => "SUITE 200",
        :zip_code => "68506", :city => "LINCOLN", :state => "NE", :tat => 0, :lockbox_number => "0")
      end
      #~ This rake task populates the details column
      #~ The facility name is passed as the argument.
      pathology_medical_services = 'PATHOLOGY MEDICAL SERVICES'
      system("rake quadax:populate_details['"+pathology_medical_services+"']")
    end
  
     
    #~ The task  'populate_details' Populates the details column of all QUADAX facilities
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
        facility.save
      end
    end 
  
end
