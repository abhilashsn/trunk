namespace :clients do

  desc "Renames SHC Reference Laboratory to Stanford University medical center"
  task :rename_SHC_reference_laboratory => :environment do
    shc_facility = Facility.find_by_name("SHC REFERENCE LABORATORY")
    if shc_facility
      shc_facility.name = "STANFORD UNIVERSITY MEDICAL CENTER" 
      shc_facility.save
    end
  end
  
  desc "Change image type to 1(multipage) for HORIZON LABORATORY LLC"
  task :change_hx_image_type => :environment do
    hx_facility = Facility.find_by_name("HORIZON LABORATORY LLC")
    if hx_facility
      hx_facility.image_type = 1
      hx_facility.save
    end
  end
  
  desc "Change image type to 0(singlepage) for MERIT MOUNTAINSIDE"
  task :change_meirt_mountainside_image_type => :environment do
    merit_facility = Facility.find_by_name("MERIT MOUNTAINSIDE")
    if merit_facility
      merit_facility.image_type = 0
      merit_facility.save
    end
  end
  
  desc "Creates RevRemit clients and facilities for batch loading"
  task :create_clients_and_facilities => :environment do
    partner = Partner.find_by_name("REVENUE MED")
    if partner.blank?
      partner = Partner.create(:name => "REVENUE MED")      
      puts "Partner 'REVENUE MED' is created." if partner
    end 
    
    # add new client name to this array. It will create client for you.
    clients = ["AHN","MedAssets","Medistreams","Quadax","Navicure","Goodman Campbell","INSIGHT IMAGING","RMS"]
    
    clients.each do |client|
      tat = (client == 'MedAssets') ? 42 : 48
      client_var = client.downcase.split(' ').first
      eval("@#{client_var} = Client.find_by_name(client)")
      eval("if @#{client_var}.blank?
           @#{client_var} = Client.create(:name => client, :tat => tat, :contracted_tat => 20,
           :partner_id => partner.id ) 
           puts 'Client #{client} is created'
           end")
    end
    
    # facilities creation for batch loading
    
    @details = {:date_received_by_insurer => false,
      :hipaa_code => false,
      :payee_name => true,
      :carrier_code => false,
      :group_code => false,
      :claim_level_dos => false,
      :check_date => true,
      :transaction_type => false,
      :revenue_code => false,
      :reference_code => false,
      :cpt_mandatory => false,
      :late_fee_charge => false,
      :payment_code => false,
      :service_date_from => true,
      :rx_code => false,
      :interest_in_service_line => false,
      :claim_type => true,
      :claim_level_eob => false,
      :patient_account_number_hyphen_format => false,
      :drg_code => false,
      :payment_type => false,
      :patient_type => false,
      :expected_payment => false,
      :denied => false,
      :payer_specific_reason_code => false,
      :hcra => false
    }
    @validation_params = {:lockbox_number => '0', :sitecode => '0'}    # parameters to satsify validations
    
    params = []
    
    #  default parameters hash
    #  For creating new facility create a hash only with elements differ from this default params hash 
    default_fac_params = { :index_file_format => "CSV", :image_type => 1, :address_one => "Not provided",  
      :city => "Default City", :state => "XX", :zip_code => "99999",:claim_file_parser_type => "Standard",
      :image_file_format => "TIFF",:tat => 0, :lockbox_number => "0" 
    }
       
    params << {:name => "AMERICAN HEALTH NETWORK", :index_file_format => "XML", 
      :client => @ahn, :address_one => "PO BOX 660557", :city => "INDIANAPOLIS",
      :state => "IN", :zip_code => "46266", :facility_npi => "1568566743",
      :facility_tin => "352108729",
    }
    params << {:name => "CHATHAM HOSPITALISTS",:client => @navicure,:address_one => "5354 REYNOLDS STREET STE 434",
      :city => "SAVANNAH", :state => "GA",:sitecode => "n55Q078S",
      :zip_code => "31406",:facility_npi => "1588663058",
      :facility_tin => "020695029"
    }
    
    params << {:name => "SOUTH COAST",:client => @navicure,:address_one => "PO Box 15909",
      :city => "Savannah", :state => "GA",:sitecode => "w1PQ082g",
      :zip_code => "314162609",:facility_npi => "1467451922",
      :facility_tin => "582194871"
    }
      
    params << {:name => "SAVANNAH PRIMARY CARE",:client => @navicure, 
      :address_one => "1326 EISENHOWER DR STE D", :city => "SAVANNAH", :state => "GA",
      :sitecode => "wZR8083H",:zip_code => "31406",:facility_npi => "1588663058",
      :facility_tin => "020695029"
    }
    
    params << {:name => "LINCOLN HOSP DISTRICT 3",:client => @navicure,
      :address_one => "100 3RD ST STE 1", :city => "DAVENPORT", :state => "WA",
      :sitecode => "KQTS0779",:zip_code => "99122",:facility_npi => "1841234598",
      :facility_tin => "910758051"
    }
    
    params << {:name => "ORTHOPAEDIC FOOT AND ANKLE CTR",:client => @navicure,
      :address_one => "6715 FORREST PARK DR", :city => "Savannah", :state => "GA",
      :sitecode => "wbRB083H",:zip_code => "31406",:facility_npi => "1952396764",
      :facility_tin => "521672232"
    }
     
    params << {:name => "SAVANNAH SURGICAL ONCOLOGY",:client => @navicure,
      :address_one => "7001 HODGSON MEMORIAL DR STE 1", :city => "Savannah",
      :state => "GA",:sitecode => "wZR9083H",:zip_code => "31406",
      :facility_npi => "1275532756", :facility_tin => "581599993",
    }
      
    params << {:name => "MERIT MOUNTAINSIDE",:client => @medassets, :image_type => 0,
      :address_one => "1 Bay Ave", :city => "Montclair", :state => "NJ",
      :sitecode => "00891",:zip_code => "070424837",:facility_npi => "1982720249",
      :facility_tin => "208489105"
    }
      
    params << {:name => "Trident Medical Imaging", :index_file_format => "XML",
      :client => @medistreams, :address_one => "PO Box 102963",  
      :city => "Atlanta", :state => "GA", :zip_code => "30368", 
      :facility_npi => "1619662503", :claim_file_parser_type => "Standard",
    }
       
    params << {:name => "STANFORD UNIVERSITY MEDICAL CENTER", :client => @quadax,
      :address_one => "FILE 74456", :address_two => "PO BOX 60000",
      :city => "SAN FRANCISCO", :state => "CA", :zip_code => "94160", 
      :facility_npi => "1174698468", :facility_tin => "061635505",
    }
       
    params << {:name => "ATLANTICAR CLINICAL LAB", :index_file_format => "DAT", 
      :client => @quadax, :address_one => "PO BOX 785616", :city => "PHILADELPHIA",
      :state => "PA", :zip_code => "191785616",
    }
        
    params << {:name => "PATHOLOGY MEDICAL SERVICES", :client => @quadax,
      :address_one => "5440 S ST", :address_two => "SUITE 200",
      :city => "LINCOLN", :state => "NE", :zip_code => "68506", 
      :facility_npi => "1902882913", :facility_tin => "470549869",
    }
        
    params << {:name => "HORIZON LABORATORY LLC", :index_file_format => "ASC",
      :client => @quadax, :address_one => "6906 N Camino", :address_two => "Martin # 140",
      :city => "Tucson", :state => "AZ", :zip_code => "85741",
    }
       
    params << {:name => "PATHOLOGY CONSULTANTS LLC", :client => @quadax,
      :address_one => "PO BOX 74578", :city => "CLEVELAND", :state => "OH", 
      :zip_code => "441940002", :facility_npi => "1831180827",
    }
        
    params << {:name => "AHP OF GEORGIA", :index_file_format => "XML", 
      :client => @medistreams, :address_one => "550 PEACHTREE ST", :address_two => "SUITE 1600",
      :city => "ATLANTA", :state => "GA", :zip_code => "30308", 
      :facility_npi => "1467400481"      
    }
       
    params << {:name => "CAMBRIDGE MEDICAL GROUP", :index_file_format => "XML",
      :client => @medistreams, :address_one => "1357 HEMBREE ROAD", :address_two => "SUITE 200", 
      :city => "ROSWELL", :state => 'GA', :zip_code => "300765726", 
      :facility_npi => "1598839953"
    }
   
    params << {:name => "RICHMOND UNIVERSITY MEDICAL CENTER", :sitecode => "RUMC",
      :client => @medassets,:facility_tin => "743177454", :facility_npi => "1740389154",
      :index_file_format => "DAT",:image_type => "0", :address_one => "PO BOX 786051",
      :zip_code => "19178", :city => "PHILADELPHIA", :state => "PA", :tat => 0,
      :index_file_parser_type=> "Wachovia",
    }
        
    params << {:name => "HORIZON EYE", :sitecode => "G51Y062K", :client => @navicure,
      :facility_tin => "562052180", :facility_npi => "1235192113",
      :index_file_format => "DAT", :address_one => "135 S SHARON AMITY CHARLOTTE NC 28211",
      :zip_code => "28211", :city => "CHARLOTTE", :state => "NC", :index_file_parser_type=> "Wachovia"
    }
    
    params << {:name => "GEORGIA EAR ASSOCIATES", :sitecode => "bCNY071Y",
      :client => @navicure,:facility_tin => "200232725", :facility_npi => "1316084122",
      :address_one => "PO Box 3720  SAVANNAH GA 31414",
      :zip_code => "31406", :city => "SAVANNAH", :state => "GA"
    }
   
    params << {:name => "CLINIX HEALTH SERVICES OF CO INC", :sitecode => "S7580852",
      :client => @navicure,:facility_tin => "841531327", :facility_npi => "1912011073",
      :address_one => "7030 S YOSEMITE STREET", :zip_code => "80112", :city => "CENTENNIAL", 
      :state => "CO"
    }
    
    params << {:name => "AHN", :client => @ahn, :address_one => "PO BOX 660557",
      :city => "INDIANAPOLIS", :state => "IN", :zip_code => "46266",
      :facility_npi => "1568566743", :facility_tin => "352108729",
    }
   
    params << {:name => "VISALIA MEDICAL CLINIC", :client => @navicure,
      :address_one => "5400 W HILLSDALE", :city => "VISALIA",
      :state => 'CA', :zip_code => "93291", :facility_npi => "1780631432",
      :facility_tin => "942203861"
    }
        
    params << {:name => "DAYTON PHYSICIANS", :index_file_format => "DAT",
      :image_type => 0, :client => @navicure, :address_one => "PO BOX 635098", 
      :city => "CINCINNATI", :state => 'OH', :zip_code => "45263", :facility_npi => "1902844947",
      :facility_tin => "203130844"
    }
      
    params << {:name => "GOODMAN CAMPBELL BRAIN AND SPINE", :image_type => 0, 
      :client => @goodman, :address_one => "PO BOX 663611", :city => "INDIANAPOLIS", 
      :state => 'IN', :zip_code => "462663611", :facility_npi => "1275580318",
      :facility_tin => "351278550"
    }
     
    params << {:name => "ADVANCED SURGEONS PC", :client => @navicure,
      :address_one => "860 MONTCLAIR RD STE 600", :city => "BIRMINGHAM", 
      :state => 'AL', :zip_code => "35213", :facility_npi => "1598727711",
      :facility_tin => "630851248"
    }
      
    params << {:name => "THOMAS CHITTENDEN HEALTH CENTER", :client => @navicure,
      :address_one => "586 OAK HILL RD", :city => "WILLISTON", 
      :state => 'VT', :zip_code => "05495", :facility_npi => "1811099229",
      :facility_tin => "043374871"
    }
   
    params << {:name => "SHEPHERD EYE SURGICENTER",:image_type => 0,
      :client => @navicure,:address_one => "3575 PECOS MCLEOD", :city => "LAS VEGAS", 
      :state => 'NV', :zip_code => "89121",:facility_tin => "752829740",
      :facility_npi => "1982677191" 
    }
   
    params << {:name => "SHEPHERD EYE CENTER",:image_type => 0, :client => @navicure,
      :address_one => "3575 PECOS MCLEOD", :city => "LAS VEGAS",
      :state => 'NV', :zip_code => "89160",:facility_tin => "880107297",
      :facility_npi => "1487604054"
    }
      
    params << {:name => "INSIGHT HEALTH CORP", :client => @insight,
      :address_one => "P O Box 404166", :city => "Atlanta", :state => 'GA',
      :zip_code => "303844166", :facility_tin => "521278857", :lockbox_number => "404166"     
    }
     
    params << {:name => "INSIGHT HEALTH CORPORATION", :client => @insight,
      :address_one => "PO BOX 57174", :city => "LOS ANGELES", :state => 'CA', 
      :zip_code => "900747174", :facility_tin => "521278857", :lockbox_number => "057174"             
    }
       
    params << {:name => "MAXUM HEALTH SERVICES CORP", :client => @insight,
      :address_one => "PO BOX 848074", :city => "DALLAS", :state => 'TX', 
      :zip_code => "752848074", :facility_tin => "752135957", :lockbox_number => "848074"           
    }
    params << {:name => "INSIGHT PREMIER HEALTH LLC", :client => @insight,
      :address_one => "PO BOX 414025", :city => "BOSTON", :state => 'MA', 
      :zip_code => "022414025", :facility_tin => "10535132", :lockbox_number => "414025"
    }
     
    params << {:name => "INSIGHT IMAGING EAST BAY", :client => @insight,
      :address_one => "PO BOX 60000", :address_two => "FILE 74486", :city => "SAN FRANCISCO", 
      :state => 'CA', :zip_code => "941600001", :facility_tin => "550836707", :lockbox_number => "074486"
    }
       
    params << {:name => "PEACHTREE PARK PEDS",:client => @navicure,
      :address_one => "3193 HOWELL MILL RD NW", :address_two => "STE 250",
      :city => "ATLANTA", :state => 'GA', :zip_code => "30327", 
      :facility_npi => "1699835660", :facility_tin => "580966853", 
    }
     
    params << {:name => "BLUE RIDGE PEDIATRICS",:client => @navicure,
      :address_one => "401 COMMERCE RD", :address_two => "STE 421",
      :city => "STAUNTON", :state => 'VA', :zip_code => "24401", 
      :facility_npi => "1831115427", :facility_tin => "510415393", 
    }
      
    params << {:name => "MARIN OPHTHALMIC",:client => @navicure,:address_one => "901 E STREET",
      :address_two => "STE 285",:city => "SAN RAFAEL", :state => 'CA', :zip_code => "94901", 
      :facility_npi => "1225016769", :facility_tin => "942778154", 
    }
    
    params << {:name => "HUDES ENDOSCOPY",:index_file_format => "XML",
      :client => @medistreams,:address_one => "4275 JOHNS CREEK PKWY", :address_two => "SUITE B",
      :city => "SUWANEE", :state => "GA", :zip_code => "30308",
      :facility_npi => "1922125285", :sitecode => "GALEN",
    }
    
    params << {:name => "EMORY PHYSICIANS",:index_file_format => "XML",
      :client => @medistreams,:address_one => "PO BOX 102632", :city => "ATLANTA",
      :state => "GA", :zip_code => "30368", :facility_npi => "1396798229",
      :sitecode => "EMORY"
    }
        
    params << {:name => "KETTERING PATHOLOGY ASSOC", :client => @quadax,
      :address_one =>"PO BOX 713084",:city => "COLUMBUS", :state => "OH",
      :zip_code => "43271", :facility_npi => "1639129703"
    }
       
    params << {:name => "ATLANTA AESTHETIC SURGERY CENTER", :client => @navicure,
      :address_one =>"4200 NORTHSIDE PKWY BLDG 8",:city => "ATLANTA",
      :state => "GA", :zip_code => "30327", :facility_npi => "1841459211",
      :facility_tin =>"582415298",
    }
     
    params << {:name => "PEACHTREE SURGICAL AND BARIATRICS", :client => @navicure,
      :address_one =>"4200 NORTHSIDE PKWY BLDG 8",:city => "ATLANTA", :state => "GA",
      :zip_code => "30327", :facility_npi => "1386785780",:facility_tin =>"581798132",
    }
      
    params << {:name => "REAL RESULTS WEIGHT LOSS SOLUTIONS",:client => @navicure,
      :address_one =>"6160 PEACHTREE DUNWOODY RD NE STE A100",:city => "SANDY SPRINGS",
      :state => "GA", :zip_code => "30328", :facility_npi => "1174846232",:facility_tin =>"271585739",
    }
     
    params << {:name => "REVENUE MANAGEMENT SOLUTIONS", :index_file_format => "XML", 
      :client => @rms
    }
      
    params.each do |param|
      facility_params = default_fac_params.merge(param)
      create_facility(facility_params[:name], facility_params, facility_params[:client])
    end
    
  end
  
  
  def create_facility(name, params, client)
    facility = Facility.find_by_name(name)
    if facility.blank?
      facility = Facility.new(@validation_params)
      facility.attributes = params
      facility.tat = client.tat.to_s
      facility.details = @details
      puts "Facility '#{facility.name}' created." if facility.save(:validate => false)
    else
      facility.lockbox_number = params[:lockbox_number] if params[:lockbox_number]
      facility.client = client
      facility.save(:validate => false)
    end
  end

  desc "Import default payers from private/configs/default_payers.csv"
  task :create_facility_specific_payers => :environment do
    csv_file = "#{Rails.root}/private/configs/facility_specific_payers.csv"
    if FileTest.exists?(csv_file)
      @facilities = Facility.find(:all,:conditions=>"name in('SHEPHERD EYE SURGICENTER','SHEPHERD EYE CENTER') ")
      unless @facilities.blank?
        @facilities.each do |facility|
          FacilitiesPayersInformation.delete_all(["facility_id = ?",facility.id])
          @records = CSV.read(csv_file)
          @records.each do |record|
            payid, payer_name = record
            payer = Payer.find_by_payer(payer_name)
            payer_id = payer.id unless payer.blank?
            FacilitiesPayersInformation.create!(:output_payid => payid.chomp, :payer_id => payer_id, :facility_id => facility.id)
          end
        end
        puts "\n\nImport Successful, #{@facilities.length * @records.length} records added."
      else
        puts "\n\nPlease check the facilities table and file #{csv_file}"
      end
    end
  end

end
  