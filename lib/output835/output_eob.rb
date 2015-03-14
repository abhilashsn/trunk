################################################################################
# Description : This class is responsible for generating configured eob level
#               segments in 835 output.
# Created     : 28-04-11 by Sunil Antony @ Revenuemed
################################################################################

class Output835::OutputEob < Output835::Eob

  def initialize eob, facility, payer, index, element_seperator
    super                                                                       #calling initialize method of super class 

    @reason_codes = eob.service_payment_eobs.collect do |service|
      service.reason_codes_for_service_line(facility, payer)
    end.flatten.compact.uniq.join(';')
    if @facility_config.details['nm1qc_segment'] &&  @facility_config.details['nm1qc_segment']['9'].include?('ID')
      option = @facility_config.details['nm1qc_segment']['9'][1..-2].downcase.gsub(' ', '_')
      eval("@id, @quali = eob.#{option}_and_qualifier")
    end
    code, qualifier = service_prov_identification
    if facility.sitecode.strip == "00895"
      insurance_eob_claim  = eob.claim_information
      claim_period_start_date = insurance_eob_claim.blank? ? nil : insurance_eob_claim.claim_statement_period_start_date
      @service_date =  claim_period_start_date.blank? ? nil : claim_period_start_date.strftime("%Y%m%d")
    else
      @service_date = claim_level_eob? ? eob.claim_from_date.strftime("%Y%m%d") : least_service_date
    end
    #instance variables for each segments, Here we are setting unconfigured part
    # of a segment. 
    
    @dtm232 =  {0 => 'DTM', 1=> '232'} unless @service_date.blank?
    @dtm233 = claim_end_date
    @clp = {0 => 'CLP', 1 => patient_account_number, 3 =>
        eob.amount('total_submitted_charge_for_claim').to_s.to_dollar, 4 => eob.amount('total_amount_paid_for_claim').to_s.to_dollar,
      5 => (claim_type_weight == 22 ? "" : eob.patient_responsibility_amount.to_s.to_dollar.to_blank), 10 => '' }
    @nm1qc = {0 => 'NM1', 1 => 'QC', 2 => '1', 5 => eob.patient_middle_initial, 6 => ''}
    @nm1il = {0 => 'NM1', 1 => 'IL', 2 => '1', 3 => eob.subscriber_last_name.to_s,
      4 => eob.subscriber_first_name.to_s, 5 => eob.subscriber_middle_initial.to_s,
      6 => '', 7 => eob.subscriber_suffix.to_s}
    @nm182 = {0 => 'NM1', 1 => '82', 6 => '', 8 => 'PC' }
    @nm1pr = {0 => 'NM1', 4 => '', 5 => '', 6 => '', 7 => ''}
    @refg3 = payer_reason_codes_for_nyu
    @refck = {0 => 'REF'}
    @reff8 = {0 => 'REF', 1 => 'F8'}
    @cas = {0 => 'CAS', 3 => eob.amount('claim_interest').to_s.to_dollar} unless (eob.amount('claim_interest').to_f.zero?)
    @amtau = {0 => 'AMT', 1 => 'AU'}
    @ref1l = {0 => 'REF', 1 => '1L'}


    
    create_config_hash
    if @facility_config.details['refig_segment'] && !@config_hash[@facility_config.details['refig_segment']['2']].to_f.zero?
      @refig = {0 =>'REF', 1 => 'IG'}
    end

    if @facility_config.details['amti_segment'] && !@config_hash[@facility_config.details['amti_segment']['2']].to_f.zero?
      @amti = {0 => 'AMT', 1 => 'I'}
    end
  end

    
  def create_config_hash
    provider_npi = (@claim && !@claim.provider_npi.blank?) ? @claim.provider_npi :
      facility.facility_npi
    provider_tin = (@claim && !@claim.provider_ein.blank?) ? @claim.provider_ein :
      facility.facility_tin

    # configuration hash for UI to datapoint mapping.
    # keys represent UI selected value which is saved in the database and values
    # represent corresponding datapoint.    
    @config_hash = {  "[Blank]" => '', 
      "[Provider First Name]" => eob.rendering_provider_first_name.to_s.upcase,
      "[Provider Last Name]" => prov_last_name_or_org,
      "[Provider Middle Initial]" => eob.rendering_provider_middle_initial,
      "[Patient First Name]" => eob.patient_first_name.to_s.strip.upcase,
      "[Patient Last Name]" => eob.patient_last_name.to_s.strip.upcase,
      "[Patient Middle Initial]" => eob.patient_middle_initial.to_s.strip,
      "[Provider TIN]" => provider_tin,
      "[Provider NPI]" => provider_npi,
      "[Lockbox Number + Trace Number]" => facility.lockbox_number.to_s + '-' + eob.trace_number(facility, @job.batch).to_s,
      "[Service From Date]" => @service_date,
      "[Service To Date]" => eob.claim_to_date.blank? ? '' : eob.claim_to_date.strftime("%Y%m%d"),
      "[Service To Date(mandatory)]" => eob.claim_to_date.blank? ? '' : eob.claim_to_date.strftime("%Y%m%d") ,
      "[Facility Type Code]" => facility_type_code.blank? ? '13' : facility_type_code,
      "[Claim Frequency Indicator]" => claim_freq_indicator.blank? ? '1' : claim_freq_indicator,
      "[HN]" => @quali.blank? ? '' : 'HN',
      "[MI]" => @quali.blank? ? '' : 'MI',
      "[HN or 34]" => eob.identification_code_qual.to_s,
      "[Payer Name]" => payer ? payer.name.to_s.strip.upcase : '',
      "[Patient Suffix]" => eob.patient_suffix,
      "[Provider Suffix]" =>  eob.rendering_provider_suffix,
      "[Reference Identification Qualifier]" => (eob.patient_account_number.to_s.strip[0..2] == "SAL") ? 'G3' : '',
      "[Check Number]" => @check.check_number,
      "[Plan Type]" => plan_type,
      "[Patient ID]" => @id.to_s,
      "[Patient Account Number]" => patient_account_number,
      "[Member ID]" => @id.to_s,
      "[Facility Name]" => facility.name.to_s.strip.upcase,
      "[Payer Reason Codes]" => @reason_codes,
      "[Monetary Amount(Interest)]" => eob.amount('claim_interest').to_s.to_dollar,
      "[DRG Code]" => eob.drg_code.to_s,
      "[Corrected Priority Payer Name]" => '', #SUNIL: Need clarification
      "[Corrected Priority Payer Identifier]" => '', #SUNIL: Need clarification
      "[Rendering Provider Identifier]" => eob.rendering_provider_identification_number.to_s, #SUNIL: may be changed
      "[Debit/Credit Indicator]" => eob.amount('claim_interest')  > 0 ? 'C' : 'D',
      "[Claim Level Allowed Amount]" => eob.sum('service_allowable').to_s.to_dollar,
      "[Image Page Name]" => eob.image_file_name.to_s,
      "[IPlan Code]" => eob.plan_type.blank? ? '99999' : eob.plan_type.to_s,  #SUNIL: may be changed
      "[Policy Number]" => eob.insurance_policy_number.to_s,
      "[Claim Status Code]" => eob.output_claim_type_weight(@client, @facility, @facility_config).to_s ,
      "[Claim Number]" => claim_number,
      "[Insurance Policy Number]" => eob.insurance_policy_number.to_s
    }
    
    @config_hash_keys = @config_hash.keys
  end
  
  # method names and corresponding segment. This hash is used for dynamic method
  # definition. Method name should match corresponding segments method in base 
  # class. This method name matching logic is for handling both bank and non-bank
  # outputs. Segment name should match corrresponding segment name from databse. 
  methods = [{:method => "service_prov_name", :segment => :nm182_segment},
    {:method => "statement_from_date", :segment => :dtm232_segment},
    {:method => "claim_from_date", :segment => :dtm232_segment},
    {:method => "claim_to_date", :segment => :dtm233_segment},
    {:method => "claim_payment_information", :segment => :clp_segment},
    {:method => "patient_name", :segment => :nm1qc_segment},
    {:method => "reference_identification_bac", :segment => :refg3_segment},
    {:method => "reference_identification_qualifier_bac", :segment => :ref1l_segment},
    {:method => "reference_id_bac", :segment => :refck_segment},
    {:method => "claim_interest_information_bac", :segment => :cas_segment},
    {:method => "insured_name", :segment => :nm1il_segment},
    {:method => "image_page_name_bac", :segment => :reff8_segment},
    {:method => "claim_supplemental_info", :segment => :amti_segment},
    {:method => "service_prov_identifier_bac", :segment => :nm1pr_segment},
    {:method => "claim_level_allowed_amount_bac", :segment => :amtau_segment},
    {:method => "other_claim_related_id", :segment => :refig_segment}
  ]

  # Dynamically defining methods for corresponding configured seqments
  methods.each do |method_params|
    define_method "#{method_params[:method]}" do |*args|
      if !(@facility_config.details[:configurable_segments].has_key?method_params[:segment].to_s.split("_").first)           # if the segment is not configured call correponding method from super class
        super()
      elsif !@facility_config.details[:configurable_segments][method_params[:segment].to_s.split("_").first]     # need not print this segment in 835
        nil
      else
        eval("if @#{method_params[:segment].to_s.split('_').first}
             parse_output_configurations(method_params[:segment])
            end")
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
    segment_hash = @facility_config.details[segment].convert_keys
    segment_array = make_segment_array(segment_hash, segment)
    segment_array = segment_array.collect do |elem|
      actual, default = elem.split('@')                 #handling default values which is seperated by '@'
      if default && @config_hash[actual].blank?
        default
      elsif @config_hash_keys.include? actual
        @config_hash[actual]
      else
        elem
      end 
    end
    Output835.remove_blank(segment_array).join('*')
  end
  
  #-----------------------------------------------------------------------------
  # Description : This method generates segment string from the output configuration
  #               hash.                   
  # Input       : configuration hash, segment to be parsed
  # Output      : segment string
  #-----------------------------------------------------------------------------    
  def make_segment_array(segment_hash, segment)
    merged_hash = nil
    segment_var = segment.to_s.split('_').first
    eval("merged_hash =  segment_hash.merge(@#{segment_var})")
    segment_array = merged_hash.segmentize.to_string
  end

  def least_service_date
    least_date = service_eobs.collect{|service| service.date_of_service_from}.sort.first
    least_date.strftime("%Y%m%d") if !least_date.blank?
  end

  def claim_end_date
    if @facility_config.details['dtm233_segment'] && @facility_config.details['dtm233_segment']['2'] ==  '[Service To Date(mandatory)]'
      eob.claim_to_date.blank? ? nil : {0 => 'DTM', 1 => '233'}
    else
      (eob.claim_to_date.blank? || (eob.claim_to_date.eql?eob.claim_from_date)) ? nil : {0 => 'DTM', 1 => '233'}
    end
  end

  #  def plan_type
  #    payer_name =  payer.name.strip.upcase
  #    if (payer_name.include? "CHAMPUS") || (payer_name.include?"TRICARE")
  #      "CH"
  #    elsif payer_name.include? "BLUE CROSS BLUE SHIELD"
  #      "i5"
  #    elsif payer_name.include? "MEDICAID"
  #      "MC"
  #    else
  #      "HM"
  #    end
  #  end

  def payer_reason_codes_for_nyu
    (facility.sitecode.to_s.strip == '00549' && eob.patient_account_number.to_s[0..2] == 'SAL') ? {0 => 'REF'} : nil
  end

  def standard_industry_code_segments
    if @facility_config.details[:configurable_segments]['lqhe']
      Output835.standard_industry_code_segments(eob, client, facility, payer, @element_seperator)
    end
  end
  
end
