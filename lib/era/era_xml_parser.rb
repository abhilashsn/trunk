require 'nokogiri'
include Nokogiri

class Era::EraXmlParser < XML::SAX::Document

  def initialize(era_check, era_job, era_client, delimiter, single_line_wrap)
    @era_check = era_check
    @era_job = era_job
    @era_client = era_client
    @era_check_attributes = era_check.attributes
    @era_job_attributes = era_job.attributes
    @delimiter = delimiter
    @single_line_wrap = single_line_wrap
    @era_config = YAML.load(File.read("#{Rails.root}/lib/era/era_parser_config.yml"))
  end

  #Nokogiri Parser Method to process Starting elements of XML
  def start_element(element, attributes = [])
    @current_element = element
    if @unique_transaction
      #get attribute values to process 835 segments based on Qualifiers
      @attribute_value = (@era_config['SKIP_SEGMENTS'].keys.include?(@current_element) ? @attribute_value : Hash[*attributes.flatten(1)]['decode'])
      segment_level_initialization(element)
      @adjustment_included = true if @current_element == 'PLB01'
    end
  end

  #Nokogiri Parser Method to process Values of XML elements
  def characters(string)
    if string.present?  #to escape new lines and tab spaces as segment values
      #starting of a single ST-SE transaction
      if @current_element == "ST02" && string == @era_check_attributes["tracking_number"]
        @unique_transaction = true
        @claim_adjustments, @service_adjustments = [], []
        initialize_transaction_records  #Initialize all the transaction records associated with a single ST-SE transaction
      end
      if @unique_transaction
        update_attributes_hash(string)  #call to update the correspnding record hash with current segment value
        cas_segment_data_intialization(string)
        get_payer_details(string) if (@attribute_value == 'Payer' || 
                                      @attribute_value == 'Payer Identification Number' || 
                                      @current_element == 'TRN03')
        get_payee_details(string) if @attribute_value == 'Payee'
        collect_additional_payee_info(string) if @era_config['PAYEE_ADD_IDENTIFICATION'].has_key?(@attribute_value)
      end
    end
  end

  #Nokogiri Parser Method to process End elements of XML
  def end_element(element)
    end_of_transaction_operations if element == "SE" && @unique_transaction
    update_misc_segments if @misc_segment && (element == @misc_end_segment)
    if element == 'CAS'
      collect_adjustments
      @nested_cas_segment = false
    end
  end

  def segment_level_initialization(element)
    case element
    when 'BPR'
      @segment_level = 'CHECK'
    when 'LX'
      @segment_level = 'CLAIM DETAIL'
    when 'CLP'
      @segment_level = 'CLAIM'
      update_claim_information if @first_claim
      @first_claim = true
    when 'SVC'
      @segment_level = 'SERVICE'
      update_service_information if @first_service
      @first_service = true
    end
  end

  #create insurance_payment_era record with values from last parsed CLP segment and initialize new hash for next CLP segment
  def update_claim_information
    @insurance_payment_era.update_attributes!(@insurance_payment_era_attributes)
    @insurance_payment_era = InsurancePaymentEra.create!(:era_check_id => @era_check.id, :lx_number => @claim_header_number)
    @insurance_payment_era_attributes = @insurance_payment_era.attributes
    update_claim_adjustments
  end

  #create service_payment_era record with values from last parsed SVC segment and initialize new hash for next SVC segment
  def update_service_information
    alter_svc_info if @service_payment_era_attributes['service_product_qualifier'] == 'NU'
    @service_payment_era = ServicePaymentEra.create!(@service_payment_era_attributes)
    @service_payment_era_attributes = ServicePaymentEra.new(:insurance_payment_era_id => @insurance_payment_era.id).attributes
    update_service_adjustments
  end

  def alter_svc_info
    @service_payment_era_attributes.merge!('revenue_code' => @service_payment_era_attributes['service_procedure_code'])
    @service_payment_era_attributes.merge!('service_procedure_code' => '')
  end

  def update_claim_adjustments
    ClaimLevelAdjustmentsEra.create!(@claim_adjustments)
    @claim_adjustments = []
  end

  def update_service_adjustments
    service_adjustments = []
    @service_adjustments.each do |service_adjustment_attributes|
      service_adjustment_attributes.merge!('service_payment_era_id' => @service_payment_era.id)
      service_adjustments << service_adjustment_attributes
    end
    ServiceLevelAdjustmentsEra.create!(service_adjustments)
    @service_adjustments = []
  end

  #Initialize all the transaction records associated with a single ST-SE transaction
  def initialize_transaction_records
    @insurance_payment_era = InsurancePaymentEra.create!(:era_check_id => @era_check.id)
    @insurance_payment_era_attributes = @insurance_payment_era.attributes
    @service_payment_era_attributes = ServicePaymentEra.new(:insurance_payment_era_id => @insurance_payment_era.id).attributes
    @era_provider_adjustment_attributes = EraProviderAdjustment.new(:era_check_id => @era_check.id).attributes
    @crosswalk_attributes = Crosswalk.new.attributes
  end

    #add the current segment value to corresponding attribute hash
  def update_attributes_hash(segment_value)
    transaction_records.each do |class_name, transaction_record|
      if transaction_record.has_key?(@era_config['TRN_DETAILS'][@current_element])
        merge_attributes_to_hash("@#{class_name.tableize.singularize}_attributes", segment_value)
        break
      elsif @era_config['TRN_DETAILS'][@attribute_value] &&
          transaction_record.has_key?(@era_config['TRN_DETAILS'][@attribute_value][@current_element])
        merge_attributes_to_hash("@#{class_name.tableize.singularize}_attributes", segment_value, @attribute_value)
        break
      elsif !@era_config["TRN_DETAILS"][@attribute_value] && @era_config["MISC_SEGMENTS"].has_key?(@current_element)
          intialize_misc_segments
          break
      end
    end
    update_835_odd_segments(segment_value)
  end

  def merge_attributes_to_hash(object_instance_hash, segment_value, qualifier = nil)
    if qualifier
      eval("#{object_instance_hash}.merge!(@era_config['TRN_DETAILS'][qualifier][@current_element] => segment_value)")
    else
      eval("#{object_instance_hash}.merge!(@era_config['TRN_DETAILS'][@current_element] => segment_value)")
    end
  end

  def intialize_misc_segments
    @misc_segment = true
    @misc_end_segment = @current_element.slice(0..2)
    @segment_text = @current_element.slice(0..2  )
  end

  def update_835_odd_segments(segment_value)
    @segment_text << (/^[0-9]*\.[0-9]{1}$/.match(segment_value) ? "#{segment_value+'0'}" : "#{segment_value}") if @misc_segment
    case @current_element
    when 'DTM02'
      update_claim_or_service_date(segment_value)
    when 'LX01'
      @claim_header_number = segment_value
      @insurance_payment_era_attributes['lx_number'] = segment_value unless @first_claim
    when 'AMT01'
      @amount_qualifier = segment_value
    when 'AMT02'
      update_claim_or_service_amount(segment_value)
    when 'QTY01'
      @quantity_qualifier = segment_value
    when 'QTY02'
      update_service_amt_or_misc_segment(segment_value)
    end
  end

  def update_claim_or_service_date(value)
    if @attribute_value == 'Claim Statement Period Start' && @insurance_payment_era_attributes['claim_to_date'].blank?
      @insurance_payment_era_attributes['claim_to_date'] = value
    elsif @attribute_value == 'Service' && @service_payment_era_attributes['date_of_service_to'].blank?
      @service_payment_era_attributes['date_of_service_to'] = value
    end
  end

  def update_claim_or_service_amount(value)
    if @segment_level == 'CLAIM'
      @insurance_payment_era_attributes.merge!('amt_qualifier' => @amount_qualifier, 'amt_amount' => value)
    elsif @segment_level == 'SERVICE'
      @service_payment_era_attributes.merge!('service_amount_qualifier_code' => @amount_qualifier, 'service_amount' => value)
    end
  end

  def update_service_amt_or_misc_segment(value)
    if @segment_level == 'CLAIM'
      @segment_text = "QTY#{@quantity_qualifier}#{value}"
      update_misc_segments
    elsif @segment_level == 'SERVICE'
      @service_payment_era_attributes.merge!('service_supp_quantity_qualifier' => @quantity_qualifier, 'service_supp_quantity' => value)
    end
  end

  def cas_segment_data_intialization(value)
    case @current_element
    when 'CAS01'
      @cas_group_code = value
    when 'CAS02'
      initialize_adjustment_records
    when 'CAS05'
      collect_adjustments
      initialize_adjustment_records
      @nested_cas_segment = true
    end
    @nested_cas_segment ? update_nested_adjustments(value) : update_cas_attributes(@current_element, value)
  end

  def initialize_adjustment_records
    case @segment_level
    when 'CLAIM'
      @claim_adjustment_attributes = ClaimLevelAdjustmentsEra.new(
        :insurance_payment_era_id => @insurance_payment_era.id, :cas_group_code => @cas_group_code).attributes
    when 'SERVICE'
      @service_adjustment_attributes = ServiceLevelAdjustmentsEra.new(:cas_group_code => @cas_group_code).attributes
    end
  end

  #collect all CAS segments within a claim or service in an array
  def collect_adjustments
    if ['CLAIM', 'SERVICE'].include?(@segment_level)
      eval("@#{@segment_level.downcase}_adjustments") << eval("@#{@segment_level.downcase}_adjustment_attributes")
    end
  end

  #update cas segment data if CAS segment have multiple adjustments
  def update_nested_adjustments(value)
    config_segment_number = get_cas_config_number(@current_element.split('CAS').last.to_i % 3)
    match_element = 'CAS0'+"#{config_segment_number}"
    if eval("@#{@segment_level.downcase}_adjustment_attributes[@era_config['ADJUSTMENTS'][match_element]]")
      collect_adjustments
      initialize_adjustment_records
    end
    update_cas_attributes(match_element, value)
  end

  #merge cas data to claim or service level adjustment record attributes
  def update_cas_attributes(element, value)
    if @era_config['ADJUSTMENTS'].has_key?(element) && ['CLAIM', 'SERVICE'].include?(@segment_level)
      eval("@#{@segment_level.downcase}_adjustment_attributes.merge!(@era_config['ADJUSTMENTS'][element] => value)")
    end
  end

  #return cas segment number to match column name from era parser config file
  def get_cas_config_number(cas_segment_number)
    case cas_segment_number
    when 0
      3
    when 1
      4
    when 2
      2
    end
  end

  #Get payer details from Payer identification loop of 835 file.
  def get_payer_details(value)
    case @current_element
    when 'N102'
      @payer_name = value
    when 'N104'
      @payer_npi = value
    when 'N301'
      @payer_address = value
    when 'N401'
      @payer_city = value
    when 'N402'
      @payer_state = value
    when 'N403'
      @payer_zip = value
    when 'TRN03'
      @payer_tin = value.gsub(/^1/,"")
      @era_check_attributes["trn_payer_company_identifier"] = @payer_tin
    when 'REF01'
      @payid_qualifier = value
    when 'REF02'
      @payer_unique_id = value
    end
  end

  #Get payee details from Payee identification loop of 835 file
  def get_payee_details(value)
    case @current_element
    when 'N103'
      @payee_qualifier = value
    when 'N104'
      if @payee_qualifier == 'XX'
        @site_npi = value
      elsif @payee_qualifier == 'FI'
        @site_tin = value
      elsif @payee_qualifier == 'XV'
        @plan_id = value
      end
    when 'N102'
      @site_name = value
    end
  end

  def collect_additional_payee_info(value)
    case @current_element
    when 'REF01'
      @additional_segment_key = @era_config['PAYEE_REF_WEIGHT'][value]
    when 'REF02'
      @additional_payee_segments ||= {}
      @additional_payee_segments.merge!(@additional_segment_key => value)
    end
  end

  #end of a single ST-SE transaction
  def end_of_transaction_operations
    map_payer
    map_payee
    update_payee_additional_info if @additional_payee_segments.present?
    save_transaction_records  #call to create records when one transaction ends
    update_misc_seg_line_numbers
    @unique_transaction, @first_claim, @first_service, @claim_header_number = false, false, false, nil
  end

  def update_misc_segments
    @misc_segment = false
    MiscSegmentsEra.create!(:era_id => @era_job.era_id, :segment_level => @segment_level,
      :segment_header => @segment_text.slice(0..2), :segment_text => @segment_text) if @segment_text.length > 3
  end

  #Map Payer for the transaction based on payer_identification_loop 835 segment values
  def map_payer
    if defined?(@payer_unique_id) && !Payer.where(:payid => @payer_unique_id).blank?
      @payers = Payer.where(:payid => @payer_unique_id)
    elsif defined?(@payer_npi) && !Payer.where(:payid => @payer_npi).blank?
      @payers = Payer.where(:payid => @payer_npi)
    else
      @payers = Payer.where(:payer_tin => @payer_tin)
    end

    if !@payers.blank?
      @payers.each do |payer|
        if (@payer_name == payer.era_payer_name && @payer_address == payer.pay_address_one && 
            @payer_city == payer.payer_city && @payer_state == payer.payer_state && @payer_zip == payer.payer_zip)
          @era_check_attributes.merge!('payer_id' => payer.id, 'status' => 'MAPPED')
          payer.update_attributes(:payer_tin => @payer_tin)
          break
        elsif (@payer_address == payer.pay_address_one && @payer_city == payer.payer_city && 
               @payer_state == payer.payer_state && @payer_zip == payer.payer_zip)
          @era_check_attributes.merge!('payer_id' => payer.id, 'status' => 'MAPPED')
          payer.update_attributes(:era_payer_name => @payer_name, :payer_tin => @payer_tin)
          break
        end
      end
      @era_check_attributes.merge!('status' => 'Unidentified Payer', 'exception_status' => 'Unidentified Payer') if @era_check_attributes['status'] != 'MAPPED'
    else
      @era_check_attributes.merge!('status' => 'Unidentified Payer', 'exception_status' => 'Unidentified Payer')
    end
  end

  #Map payee for the transaction based on payee_identification_loop 835 segment values
  def map_payee
    if @payee_qualifier == 'XX'
      @era_job_attributes.merge!('payee_npi' => @site_npi, 'payee_tin' => @era_job_attributes['era_addl_payeeid'])
      if @era_client.try(:name).try(:upcase) == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
        @facility = FacilitiesNpiAndTin.find_by_npi(@site_npi).try(:upmc_facility)
      else
        @facility = FacilitiesNpiAndTin.find_by_npi(@site_npi).try(:facility)
      end
      find_site_tin(@era_job_attributes['payee_tin']) if @facility.blank? && !@era_job_attributes['payee_tin'].blank?
    elsif @payee_qualifier == 'FI'
      @era_job_attributes.merge!('payee_tin' => @site_tin)
      find_site_tin(@site_tin)
    end
    if !@facility.blank?
      @era_job_attributes.merge!('facility_id' => @facility.id, 'client_id' => @era_client.try(:id), 'status' => 'MAPPED')
    else
      @era_job_attributes.merge!('status' => 'Unidentified Site')
      #update era_check exception status
      if @era_check_attributes['exception_status'].blank?
        @era_check_attributes.merge!('exception_status' => 'Unidentified Site')
      else
        @era_check_attributes.merge!('exception_status' => 'Both')
      end
    end
  end

  #Search for ERA file site TIN in application database
  def find_site_tin(site_tin)
    if @era_client.try(:name).try(:upcase) == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER"
      @facility = UpmcFacility.find_by_tin(site_tin)
      @facility = nil if !@facility.blank? && @facility.name != @site_name && @facility.facility_aliases.where(:name => @site_name).blank?
    else
      @facility = FacilitiesNpiAndTin.where(:tin => site_tin).map(&:facility)
      @facility = nil if !@facility.blank? && !@facility.map(&:name).include?(@site_name) && !@facility.map(&:facility_aliases).flatten.map(&:name).include?(@site_name)
    end
  end

  def update_payee_additional_info
    @additional_payee_segments.sort_by{|weight, value| weight}.reverse.each_with_index do |segment, index|
      if index == 0
        @era_job_attributes.merge!('era_addl_payeeid_qualifier' => @era_config['PAYEE_REF_WEIGHT'].key(segment.first), 'era_addl_payeeid' => segment.last)
      else
        MiscSegmentsEra.create!(:era_id => @era_job.era_id, :segment_level => 'CHECK',
        :segment_header => 'REF', :segment_text => "REF#{@era_config['PAYEE_REF_WEIGHT'].key(segment.first)}#{segment.last}")
      end
    end
  end

  #create associated records at the end of transaction
  def save_transaction_records
    @insurance_payment_era.update_attributes!(@insurance_payment_era_attributes)
    alter_svc_info if @service_payment_era_attributes['service_product_qualifier'] == 'NU'
    @service_payment_era = ServicePaymentEra.create!(@service_payment_era_attributes) if @first_service
    update_claim_adjustments
    update_service_adjustments
    @era_check.update_attributes!(@era_check_attributes)
    @era_job.update_attributes!(@era_job_attributes)
    EraProviderAdjustment.create!(@era_provider_adjustment_attributes) if @adjustment_included
  end

  #update line numbers for misc segments
  #this iterates over the source 835 file and find the segment and update its line number
  def update_misc_seg_line_numbers
    segments = MiscSegmentsEra.where(:era_id => @era_job.era_id).map(&:segment_text)
    raw_era_file = File.open("#{@era_job.era.inbound_file_information.file_path}/#{@era_job.era.inbound_file_information.name}", 'r')

    @segments = ''
    IO.foreach(raw_era_file){|segment| @segments += segment}
    @raw_835_segments = @segments.delete("\n").split("~").collect{|line| line.strip+"~\n"}

    @raw_835_segments.each_with_index do |line, index|
      @track_number = line.split(@delimiter)[2].chomp.split(/~/).first if /^ST((\*)|(\|)).*$/.match(line)
      if check_835_file(segments, line) && @track_number == @era_check.tracking_number
        misc_segment = MiscSegmentsEra.where(:era_id => @era_job.era_id, :segment_text => @formated_text, :segment_line_number_in_file => nil).first
        misc_segment.update_attributes(:segment_line_number_in_file => index + 1, :segment_text => line.chop) if misc_segment
      end
    end
  end

  def check_835_file(segments, line)
    line_segments = line .delete('~').chop.split(@delimiter)
    @formated_text = ''
    line_segments.each do |line_segment|
      @formated_text << (/^[0-9]*\.[0-9]{1}$/.match(line_segment) ? line_segment+'0' : line_segment)
    end
    segments.include?(@formated_text)
  end

  #Hash containing all record attributes which are going to be populated at the end of ST-SE transaction
  def transaction_records
    {
      'EraJob' => @era_job_attributes,
      'EraCheck' => @era_check_attributes,
      'InsurancePaymentEra' => @insurance_payment_era_attributes,
      'ServicePaymentEra' => @service_payment_era_attributes,
      'EraProviderAdjustment' => @era_provider_adjustment_attributes,
      'Crosswalk' => @crosswalk_attributes
    }
  end

end
