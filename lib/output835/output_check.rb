################################################################################
# Description : This class is responsible for generating configured check level
#               segments in 835 output.
#               Please run rake output:import_segments to configure all the segments
# Created     : 28-04-11 by Sunil Antony @ Revenuemed
################################################################################

class Output835::OutputCheck < Output835::Check
  
  def initialize (check, facility, index, element_seperator, check_eob_hash = nil)
    super  #calling initialize method of super class
  end
  
  def init_check_info(check)
    super
    @se01 = []
    @payee = find_payee
    
    #instance variables for each segments, Here we are setting unconfigured part
    # of a segment.
    @bpr = {0 => 'BPR', 1 => (correspondence_check? ? 'H' : 'I'), 2 => @check_amount.to_s.to_dollar,
      3 => 'C', 4 => payment_indicator, 5 => '' }
    @st = {0 => 'ST', 1 => '835'}
    @trn = {0 => 'TRN', 1 => '1'}
    @dtm405 = {0 => 'DTM', 1 => '405'}
    @n1pr = {0 => 'N1', 1 => 'PR'}
    @n3pr = {0 => 'N3'}
    @n4pr = {0 => 'N4', 4 => '', 5 => '', 6 => ''} #SUNIL: remove single data instance variables
    @per = {0 => 'PER'}
    @n1pe = {0 => 'N1', 1 => 'PE'}
    @n3pe = {0 => 'N3'}
    @n4pe = {0 => 'N4', 4 => '', 5 => '', 6 => ''}
    @refpq = {0 => 'REF', 1 => 'PQ'}
    @se = {0 => 'SE', 1 => @se01}
    @ts3 = {0 => 'TS3', 3 => "#{Date.today.year()}1231", 4 => @eobs.length.to_s,
      5 => total_submitted_charges.to_s.to_dollar, 6 => '', 7 => '', 8 => ''}
    @n1bb = {0 => 'N1', 1 => 'BB', 2 => 'HEALTHLOGIC CORP', 3 => 'ZZ'}
    @refpb = {0 => 'REF', 1 => 'PB'}
    @ref2u = {0 => 'REF'}
    @refsi = {0 => 'REF'}
    @reftj = {0 => 'REF'}
    @refosi = {0 => 'REF'}
    @refev = {0 => 'REF', 1 => 'EV'}
    @refeo = {0 => 'REF', 1 => 'EO'}
        
    create_default_payers
    @default_payer_address = payer.default_payer_address(facility, check)
    create_config_hash
  end
  
  def create_config_hash
    micr = check.micr_line_information
    check_image = check.image_file_name.to_s
    @batch = check.batch
    pre_defined_payerid = @eob_type == 'Patient' ? facility.patient_payerid :
      facility.commercial_payerid
    provider_tin = (@claim && !@claim.tin.blank?)? @claim.tin : facility.facility_tin
    provider_npi = (@claim && !@claim.npi.blank?)? @claim.npi : facility.facility_npi
    seq_num = (@index+1).to_s
    payer_tin = (payer && payer.payer_tin) ? '1' + payer.payer_tin : '1' + facility.facility_tin
    payerid =  payer.payer_identifier(micr)
    hlsc_payerid = payer && payerid ? (payerid.to_s.strip[0] == 'U' ? 'U9999' : payerid) : 'U9999'
    st03 = (@claim && !@claim.npi.blank? || !@payee.npi.blank?) ? 'XX' :'FI'
       
    # configuration hash for UI to datapoint mapping.
    # keys represent UI selected value which is saved in the database and values
    # represent corresponding datapoint.
    @config_hash = { "[Blank]" => '', 
      "[Client TIN]" => facility.facility_tin.to_s.strip, 
      "[Account Number]" => account_number,
      "[Pre Defined PayerID]" => pre_defined_payerid,
      "[Check Date]" => (check.correspondence? ? '' : check.check_date.strftime("%Y%m%d")),
      "[Trace Number]" => @eobs.first.trace_number(facility, @batch).to_s,
      "[Batch Date]" => @batch.date.strftime("%Y%m%d"),
      "[Sequence Number]" => seq_num.justify(4, '0'),
      "[Sequence Number(9 characters)]" => seq_num.justify(9, '0'),
      "[Batch ID]" => @batch.batchid,
      "[Check Number]" => check.check_number,
      "[Payer TIN]" => payer ? payer.payer_tin : '',
      "[Lockbox Number]" => facility.lockbox_number,
      "[0 + Lockbox Number]" => facility.lockbox_number.justify(7, '0'),
      "[0 + HLSC Payer ID]" => hlsc_payerid.justify(10, '0'),
      "[HLSC Payer ID]" => hlsc_payerid,
      "[Client Specific Payer ID]" => client_specific_payerid(payerid).to_s.justify(10, '0'),
      "[Deposit Date]" => @batch.date.strftime("%Y%m%d"),
      "[Processing Date]" => Time.now().strftime('%Y%m%d'),
      "[Provider TIN]" => provider_tin,
      "[Provider Number]" => (provider_tin.blank? ? facility.facility_tin : provider_tin),
      "[Provider NPI]" => provider_npi,
      "[DDA Number]" => (get_micr_condition ? account_number : ''),
      "[Client DDA Number]" => facility.client_dda_number.to_s,
      "[Batch ID + Sequence]" => @batch.batchid.justify(6) + @@batch_based_index.to_s.justify(3, '0'),
      "[Check Num + Batch Date + Batch Time + Filename]" => [check.check_number,
        @batch.date.strftime("%Y%m%d"), @batch.arrival_time.strftime("%H%M"),
        @batch.file_name].join('-'),
      "[1 + Payer TIN]" => payer_tin,
      "[Legacy Provider Number]" => provider_tin,
      "[Image Name]" => check.job.images_for_jobs.first.filename.split('.')[-2][-3..-1],
      "[FI or XX]" => st03,
      "[ID Number Qualifier]" => (get_micr_condition ? id_number_qualifier : ''),
      "[ABA Routing Number]" => (get_micr_condition ? routing_number : ''), 
      "[Account Number Qualifier]" => (get_micr_condition ? account_num_indicator : ''),
      "[Payer Address]" => output_payer("address_one"),
      "[Payer City]" => output_payer("city"),
      "[Payer State]" => output_payer("state"),
      "[Payer ZipCode]" => output_payer("zip_code"),
      "[Provider Address]" => @payee.address_one.to_s.strip.upcase,
      "[Provider City]" => @payee.city.to_s.strip.upcase,
      "[Provider State]" => @payee.state.to_s.strip.upcase,
      "[Provider ZipCode]" => @payee.zip_code.to_s.strip.upcase,
      "[Custom Logic]" => payee_identification_code,  # This is NYU specific logic
      "[Payer Name]" =>  payer.name.blank? ? 'UNKNOWN PAYER' : payer.name.strip.upcase[0..28],
      "[Payer Name(No Space)]" => payer.name.blank? ? 'UNKNOWNPAYER' : payer.name.strip.upcase.delete(" ")[0..28],
      "[Mapped Payer Name]" => payer.name.to_s[0..28],
      "[Provider NPI or TIN]" => provider_npi.blank? ? provider_tin : provider_npi,
      "[Provider Name]" =>  @payee.name.to_s.strip.upcase,
      "[Facility Type Code]" => @eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : "",
      "[Image ID]" => @eobs.first.image_file_name.to_s,
      "[Check Image ID]" => check_image,
      "[Custom Logic Payer Identification]" => check.correspondence? ? 'NONE' : payer.name.to_s[0..28],
      "[Transaction ID]" => check.job.transaction_number,
      "[Identification Code]" => eob_type == 'Patient' ? 'PT' : 'IN',
      "[3-Tif]" => check_image.length >= 7 ? check_image[-7..-1] : check_image,
      "[Total Payment]" => check.total_payment_amount.to_s.to_dollar,
      "[Health Plan ID]" => "", #SUNIL: requirement is not clear
      "[Medicaid Provider Number]" => "", #SUNIL: requirement is not clear
      "[OSI ID]" => facility.lockbox_number.to_s, 
      "[Lockbox Number]_[Batch ID]" => "#{facility.lockbox_number}_#{@batch.batchid}",
      "[Submitter Identification Number]" => submitter_identification_number,
      "[Ref 2u Payerid]" => payerid.to_s

    }
    
    @config_hash_keys = @config_hash.keys
  end
  
  # method names and corresponding segment. This hash is used for dynamic method
  # definition. Method name should match corresponding segments method in base 
  # class. This method name matching logic is for handling both bank and non-bank
  # outputs. Segment name should match corrresponding segment name from databse.
  methods = [{:method => "financial_info", :segment => :bpr_segment}, 
    {:method => "transaction_set_header", :segment =>  :st_segment},
    {:method => "reassociation_trace",:segment =>  :trn_segment}, 
    {:method => "date_time_reference",:segment =>  :dtm405_segment},
    {:method => "payer_identification", :segment => :n1pr_segment},
    {:method => "payee_identification", :segment => :n1pe_segment},
    {:method => "payee_additional_identification_1_bac", :segment => :refpq_segment},
    {:method => "transaction_set_trailer", :segment => :se_segment},
    {:method => "provider_summary_info_bac", :segment => :ts3_segment},
    {:method => "name_bac", :segment => :n1bb_segment},
    {:method => "image_name_bac", :segment => :refpb_segment},
    {:method => "payer_additional_identification_bac", :segment => :ref2u_segment},
    {:method => "payee_additional_identification", :segment => :reftj_segment},
    {:method => "reciever_id", :segment => :refev_segment},
    {:method => "submitter_identification_bac", :segment => :refsi_segment},
    {:method => "payee_additional_identification_2_bac", :segment => :refosi_segment},
    {:method => "reference_identification_bac", :segment => :refeo_segment},
    {:method => "payer_technical_contact", :segment => :per_segment}
  ]
  
  # Dynamically defining methods for corresponding configured seqments
  methods.each do |method_params|
    define_method "#{method_params[:method]}" do |*args|
      if !(@facility_config.details[:configurable_segments].has_key?method_params[:segment].to_s.split("_").first)              # if the segment is not configured call correponding method from super class
        super()
      elsif !@facility_config.details[:configurable_segments][method_params[:segment].to_s.split("_").first]     # need not print this segment in 835
        nil
      else
        parse_output_configurations(method_params[:segment]) 
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is responsible for parsing output configurations and
  #               generating equivalent segment string.                   
  # Input       : segment to be parsed
  # Output      : parsed segment string
  #-----------------------------------------------------------------------------    
  def parse_output_configurations(segment)
    if !@facility_config.details[segment].blank?
      segment_hash = @facility_config.details[segment].convert_keys
    end
    segment_array = make_segment_array(segment_hash, segment)
    if !segment_array.blank?
      segment_array = segment_array.collect do |elem|
        actual, default = elem.split('@')                                          #handling default values which is seperated by '@'
        if default && @config_hash[actual].blank?
          default
        elsif @config_hash_keys.include? actual
          @config_hash[actual]
        else
          elem
        end
      end
      segment_array = remove_empty_modifiers segment_array if segment == :n1pe_segment
      Output835.remove_blank(segment_array).join('*')
    end
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method generates segment string from the output configuration
  #               hash.                   
  # Input       : configuration hash, segment to be parsed
  # Output      : segment string
  #-----------------------------------------------------------------------------    
  def make_segment_array(segment_hash, segment)
    if !segment_hash.blank?
      merged_hash = nil
      segment_var = segment.to_s.split('_').first
      eval("merged_hash =  segment_hash.merge(@#{segment_var})")
      segment_array = merged_hash.segmentize.to_string
    end
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method returns payee (from claim or facility)
  # Input       : None
  # Output      : Payee
  #-----------------------------------------------------------------------------    
  def find_payee
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? ||
            payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility                                                       
      end
    end
    payee
  end
  
  #-----------------------------------------------------------------------------
  # Description : Over riding mathod 'total_submitted_charges' in base class
  # Input       : None
  # Output      : Float
  #-----------------------------------------------------------------------------    
  def total_submitted_charges
    sum = 0
    @eobs.each do |eob|
      sum += eob.amount('total_submitted_charge_for_claim')
    end
    sum
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is used to handle specific default payer logic for
  #               WMH client
  # Input       : None
  # Output      : Payer
  #-----------------------------------------------------------------------------    
  def default_wmh_payer
    default_pay = nil
    @wmh_default_payers.each do |pay|
      if payer.name.to_s.strip.upcase.include? pay.name
        default_pay = pay 
      end
    end
    default_pay || @default_payer 
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method is used to initialize WMH default payers.
  # Input       : None
  # Output      : Payer
  #-----------------------------------------------------------------------------    
  def create_default_payers
    wmh_payers = ["MOLINA|100 WEST BIG BEAVER, SUITE 600|TROY|MI|48084",
      "MCARE|2301 COMMONWEALTH BOULEVARD|ANN ARBOR|MI|48105",
      "TOTAL HEALTH CARE|3011 W.GRAND BLVD SUITE 1600|DETROIT|MI|48202"]
    @default_payer = Payer.new(:address_one => "P.O. BOX 9999" , :city => 'ATLANTA',
      :state => 'GA', :zip_code => '12345')
    @wmh_default_payers = []
    wmh_payers.each do |pay|
      payer_array = pay.split('|')
      @wmh_default_payers <<  Payer.new(:name => payer_array[0], :address_one =>
          payer_array[1] , :city => payer_array[2], :state => payer_array[3],
        :zip_code => payer_array[4])
    end  
  end

 
  #-----------------------------------------------------------------------------
  # Description : Over riding method 'address' in base class
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def address party
    if party.class == Payer
      @facility_config.details[:configurable_segments]["n3pr"]  ? parse_output_configurations(:n3pr_segment) : nil
    else
      @facility_config.details[:configurable_segments]["n3pe"] ? parse_output_configurations(:n3pe_segment) : nil
    end
  end
  
  #-----------------------------------------------------------------------------
  # Description : Over riding method 'geographic_location' in base class
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def geographic_location party
    if party.class == Payer
      @facility_config.details[:configurable_segments]["n4pr"] ? parse_output_configurations(:n4pr_segment) : nil
    else
      @facility_config.details[:configurable_segments]["n4pe"] ? parse_output_configurations(:n4pe_segment) : nil
    end
  end

  #-----------------------------------------------------------------------------
  # Description : NYU client use a custom logic to print the N104 based on the
  #               remit grouping
  # Input       : None
  # Output      : String
  #-----------------------------------------------------------------------------

  def payee_identification_code
    npi = "1801992631"
    patient_account_numbers = @check.insurance_payment_eobs.collect(&:patient_account_number)
    if !(@check.batch.correspondence)
      patient_account_numbers.each do|account_number|
        if (account_number[0,3].upcase == "SAL")
          case @check.get_payer.payer.upcase
          when "UHC"
            npi = "0000087726"
          when "HIP"
            npi = "0000055247"
          when "UHC"
            npi = "0000087726"
          when "AET"
            npi = "0000060054"
          when "ALL"
            npi = "0000099999"
          end
        end
      end
    end
    return npi
  end

  # Provides the address attribute of a payer which are address_one, city, state, zip_code
  # If an address field is blank, default address needs to be provided
  # Input :
  # attribute : One of the address fields [address_one, city, state, zip_code]
  # Output :
  # The valid address field in relation to the input
  def output_payer attribute
    begin
      if facility.sitecode =~ /^0*00877$/
        default_attribute = default_wmh_payer.send(attribute)
      end
      if default_attribute.blank? && !@default_payer_address.blank?
        default_attribute = @default_payer_address[attribute.to_sym]
      end
      obtained_attribute = default_attribute || payer.send(attribute)
      obtained_attribute.to_s.strip.upcase
    rescue
      ''
    end
  end

  #-----------------------------------------------------------------------------
  # Description : This method is used as a gateway for calling actual claim loop
  #               logic. If BY_Bill type is selected, we need to group the EOBs
  #               within one ST/SE based on Bill type. So the EOBs corresponds to
  #               Bill type 1 will go in LX*1, Bill type 2 will go in LX*2 etc.
  #               If 3-sequention number is selected, we need to print each EOB
  #               within one ST/SE using an incremental value in the LX.
  # Input       : None
  # Output      : None
  #-----------------------------------------------------------------------------
  def claim_loop
    segments = []
    lx_selection = @facility_config.details[:lx_segment]["1"] rescue "1"
    if lx_selection == "[By Bill Type]"
      eob_group = @eobs.group_by{|eob| eob.bill_type}
      eob_group.each_with_index do |group, index|
        segments << write_claim_payment_information({:eobs => group[1], :count_condition => 'single', :justification => 1, :index => index +1})
      end
    elsif lx_selection == '[3-Sequential Number]'
      segments = write_claim_payment_information({:eobs => @eobs, :count_condition => 'multiple', :justification => 3})
    else
      segments = write_claim_payment_information({:eobs => @eobs, :count_condition => 'single', :justification =>  1, :value => lx_selection })
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end

  #-----------------------------------------------------------------------------
  # Description : Actual claim looplogic Based on eob grouping
  # Input       : Eob object array, no :of occurrence of LX segment, jsutification
  #               of LX01 segment, value in case of static .
  # Output      : None
  #-----------------------------------------------------------------------------
  def write_claim_payment_information(params)
    segments = []
    Output835.log.info "\n\nCheck has #{@eobs.length} eobs"
    params[:eobs].each_with_index do |eob, index|
      if params[:count_condition] == 'single' && index == 0
        lx01 = params[:index] ? params[:index] : index + 1
        segments << transaction_set_line_number(lx01, params[:justification], params[:value])
      elsif params[:count_condition] == 'multiple'
        segments << transaction_set_line_number(index + 1, params[:justification])
      end
      segments << provider_summary_info_bac if index == 0
      segments << transaction_statistics([eob])
      eob_klass = Output835.class_for("Eob", facility)
      eob_obj = eob_klass.new(eob, facility, payer, index, @element_seperator) if eob
      Output835.log.info "Applying class #{eob_klass}" if index == 0
      segments += eob_obj.generate
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end


  #-----------------------------------------------------------------------------
  # Description : Printing LX segment
  # Input       : LX01 value, justification of LX01, value in case of static.
  # Output      : LX segment string
  #-----------------------------------------------------------------------------
  def transaction_set_line_number(index, justification, value = nil)
    elements = []
    elements << 'LX'
    elements << (value ? value.to_s : index.to_s.rjust(justification, '0'))
    elements.join(@element_seperator)
  end

  def submitter_identification_number
    eob_id = @batch.details ? @batch.details['batch_item_sequence'] : nil
    "#{check.correspondence? ? 'TIX':'TIP'}-#{@batch.date.strftime("%m%d")}#{@batch.cut}#{facility.sitecode.to_s[-3..-1]}.#{eob_id}"
  end

  def provider_adjustment
    plb = super
    if plb && @facility_config.details['plb_segment']
      plb01 = @config_hash[@facility_config.details['plb_segment']['1']].to_s
      plb01 = @facility_config.details['plb_segment']['1'].to_s if plb01.blank?
      plb05 = @facility_config.details['plb_segment']['5'].to_s
      plb = plb.split('*')
      plb[1] = plb01
      plb[5] = 'L6' if (plb05 != '[Patient Account Number]') && plb[5] && (plb[5][0..1] == 'L6')
      plb = plb.join('*')
    end
    plb
  end
  
  def client_specific_payerid(payerid)
    facility_group_code = facility.client.group_code.to_s.strip
    case facility_group_code
    when 'ADC','MDR','LLU'
      payid =  payer && payerid ? ((check.correspondence? && payer.status.upcase != 'MAPPED') ? 'U9999': payerid ) : nil
      payid = payid.justify(10, '0')
    when 'BYH'
      payid = payer && payerid ? (check.correspondence? ? "1999999999" :(payer.status.upcase == 'MAPPED' ? payerid : "00000U9999")): nil
    when 'CNS'
      payid =  payer && payerid ? (check.correspondence? ? "1999999999" : payerid.to_s.justify(10, '0')): nil
    when 'KOD'
      payid = payer && payerid ? (payer.status.upcase == 'MAPPED' ? payerid : "00000U9999" ): nil
    end
    return payid
  end

  def remove_empty_modifiers segment
    segment[4].blank? ? segment[0..2] : segment
  end

end