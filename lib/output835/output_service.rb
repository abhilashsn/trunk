################################################################################
# Description : This class is responsible for generating configured service level
#               segments in 835 output.
# Created     : 28-04-11 by Sunil Antony @ Revenuemed
################################################################################

class Output835::OutputService < Output835::Service
 
  def initialize(service, facility, payer, index, element_seperator)
    super                                                                       #calling initialize method of super class
    
    @delimiter = @facility_config.details['isa_segment']['16'] if @facility_config.details['isa_segment']

    #instance variables for each segments, Here we are setting unconfigured part
    # of a segment.
    @charge_amount = service.amount('service_procedure_charge_amount')
    @paid_amount = service.amount('service_paid_amount')

    if !@charge_amount.zero? || !@paid_amount.zero?
      @svc = {0 => 'SVC', 1 => composite_med_proc_id, 2 => @charge_amount.to_s.to_dollar,
        3 => @paid_amount.to_s.to_dollar }
    
      @dtm472 = {0 => 'DTM', 1 => '472'}
      @dtm150 = {0 => 'DTM', 1 => '150'}
      @dtm151 = {0 => 'DTM', 1 => '151'}
    end
     
    create_config_hash
    if @facility_config.details['amtb6_segment'] && !@config_hash[@facility_config.details['amtb6_segment']['2']].to_f.zero?
      @amtb6 = amtb6_elements
    end

    if @facility_config.details['ref6r_segment'] && !@config_hash[@facility_config.details['ref6r_segment']['2']].blank?
      @ref6r = {0 => 'REF', 1 => '6R'} 
    end

  end
  
  def create_config_hash
    from_date = service.date_of_service_from.blank? ? nil : service.\
      date_of_service_from.strftime("%Y%m%d")
    to_date = service.date_of_service_to.strftime("%Y%m%d") unless service.date_of_service_to.blank?
      
    # configuration hash for UI to datapoint mapping.
    # keys represent UI selected value which is saved in the database and values
    # represent corresponding datapoint.
    @config_hash = {  "[Blank]" => '', 
      "[True]" => service.service_quantity,
      "[Reference Number]" => service.service_provider_control_number,
      "[Service Date]" => from_date,
      "[Service To Date]" => to_date,
      "[Revenue Code]" => service.revenue_code.to_s.strip,
      "[Supplemental Amount]" => supplemental_amount.to_s.to_dollar,
      "[Retention Fee]" => service.amount('retention_fees').to_s.to_dollar,
      "[Interest Amount]" => service.insurance_payment_eob.amount('claim_interest').to_s.to_dollar,
      "[Network Discount Amount]" => 'B6:' + service.amount('service_discount').to_s.to_dollar,
      "[Allowed Amount]" => client_specific_allowed_amount.to_s.to_dollar,
      "[Xpeditor Document number]" => xpeditor_document_number
    }
    
    @config_hash_keys = @config_hash.keys
  end
  
  # method names and corresponding segment. This hash is used for dynamic method
  # definition. Method name should match corresponding segments method in base 
  # class. This method name matching logic is for handling both bank and non-bank
  # outputs. Segment name should match corrresponding segment name from databse. 
  methods = [{:method => "service_payment_information", :segment => :svc_segment},
    {:method => "provider_control_number", :segment => :ref6r_segment},
    {:method => "dtm_472", :segment => :dtm472_segment},
    {:method => "service_supplemental_amount", :segment => :amtb6_segment},
    {:method => "dtm_150", :segment => :dtm150_segment},
    {:method => "dtm_151", :segment => :dtm151_segment}
  ]
  
  # Dynamically defining methods for corresponding configured seqments
  methods.each do |method_params|
    define_method "#{method_params[:method]}" do |*args|
      if !(@facility_config.details[:configurable_segments].has_key?method_params[:segment].to_s.split("_").first)             # if the segment is not configured call correponding method from super class
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
      actual, default = elem.split('@')                                          #handling default values which is seperated by '@'
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
  
  #-----------------------------------------------------------------------------
  # Description : Over riding method 'composite_med_proc_id' in base class
  # Input       : None
  # Output      : segment string
  #-----------------------------------------------------------------------------    
  def composite_med_proc_id
    qualifier = facility.sitecode =~ /^0*00S66$/ ? 'AD' : 'HC'
    elem = []
    proc_code = (service.service_procedure_code.blank? ? 'ZZ' + @delimiter.to_s +
        'E01' : qualifier + @delimiter.to_s + service.service_procedure_code)
    proc_code = 'ZZ' + @delimiter.to_s + 'E01' if service.service_procedure_code.to_s == 'ZZE01'
    modifier_condition = (@facility_config.details['svc_segment'] && (@facility_config.details['svc_segment']['1'].to_s == '[CPT Code + Modifiers]'))
    elem = modifier_condition ? [proc_code, service.service_modifier1 , service.service_modifier2 ,
      service.service_modifier3 , service.service_modifier4] : [proc_code]
    elem = Output835.trim_segment(elem)
    elem.join(@delimiter)
  end

  def client_specific_allowed_amount
    group_code = facility.client.group_code.to_s.strip
    co_insurance = service.amount('service_co_insurance')
    paid = service.amount('service_paid_amount')
    charge = service.amount('service_procedure_charge_amount')
    allowed = service.amount('service_allowable')
    denied = service.amount('denied')
    non_covered =  service.amount('service_no_covered')
    deductable = service.amount('service_deductible')
    copay = service.amount('service_co_pay')
    ppp = service.amount('primary_payment')
    contractual = service.amount('contractual_amount')
    case group_code
    when 'ADC'
      allowed.zero? ? ((co_insurance + paid) == charge ? charge : allowed) : allowed
    when 'ATI', 'USC'
      amount = co_insurance + deductable + paid
      (!ppp.zero? && !charge.zero?) ? charge : (amount.zero? ? '' : amount)
    when 'CCS'
      amount = charge - denied - non_covered
      allowed.zero? ? (amount <= 0 ? '' : amount  ) : allowed
    when 'CHCS'
      amount = paid + deductable + co_insurance + copay
      amount.zero? ? '' : amount
    when 'ESI'
      allowed.zero? ? (paid.zero? ? '' : paid): allowed
    when 'MAXH'
      amount = paid + deductable + co_insurance
      allowed.zero? ? (amount.zero? ? '' : amount) : allowed
    when 'MCP', 'MDQ'
      amount = paid + deductable + co_insurance
      amount.zero? ? '' : amount
    when 'NYU'
      amount = paid + deductable + co_insurance + contractual
      allowed.zero? ? (amount.zero? ? '' : amount) : allowed
    else
      allowed
    end
  end

  def amtb6_elements
    retention_fee = service.amount('retention_fees')
    if @client.group_code.to_s == 'ADC' && payer && payer.name.to_s.upcase.include?('TUFTS') && !retention_fee.zero?
      {0 => 'AMT', 1 => 'B6', 3 => 'KH', 4 => retention_fee.to_s.dollar }
    else
      {0 => 'AMT', 1 => 'B6'}
    end
  end

  def standard_industry_code_segments
    if @facility_config.details[:configurable_segments]['lqhe']
      Output835.standard_industry_code_segments(service, client, facility, payer, @element_seperator)  if !@charge_amount.zero? || !@paid_amount.zero?
    end
  end

  def xpeditor_document_number
    service_claim = service.insurance_payment_eob.claim_information
    xpeditor_document_number = service_claim.xpeditor_document_number if service_claim
    service_index_number = (index + 1).to_s.rjust(4 ,'0')
    xpeditor_number = (xpeditor_document_number.blank? || xpeditor_document_number == 0)?  nil : (xpeditor_document_number + service_index_number)
    xpeditor_number
  end
  
end
