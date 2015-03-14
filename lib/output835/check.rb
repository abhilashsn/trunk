#Represents an ST-SE Transaction
class Output835::Check
  attr_reader :check, :index, :payer, :eob_type, :grouped_eobs, :facility, :facility_config, :facility_output_config
  def initialize(check, facility, index, element_seperator, check_eob_hash=nil)
    @facility = facility
    @index = index
    @element_seperator = element_seperator
    @facility_config = facility.facility_output_configs.first
    @flag = 0  #for identify if any of the billing provider details is missing
    init_check_info check unless check.nil?
    @check_eob_hash = check_eob_hash
    @client = @facility.client
  end
  
  def init_check_info(check)
    @check = check
    
    @eob_type = check.eob_type
    @eobs = @check_eob_hash ? @check_eob_hash[check.id] :  check.insurance_payment_eobs
    # Circumventing using Check <-> Payer association because of the existing
    # bug in MICR module where it does not update payer_id in check
    # after identifying the payer for a check, while loading grid
    if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end
    job = check.job
    @check_amount = check_amount
    @facility_output_config = facility.output_config(job.payer_group)
  end
  
  def generate_new(chk,idx)
    @index = idx
    init_check_info(chk)
    generate
  end
  
  def generate
    Output835.log.info "\n\nCheck number : #{check.check_number} undergoing processing"
    Output835.log.info "Payer : #{check.payer.payer}, Check ID: #{check.id}"
    transaction_segments =[]
    transaction_segments << transaction_set_header
    
    transaction_segments << financial_info
    transaction_segments << reassociation_trace
    transaction_segments << ref_ev_loop if !@facility_output_config.details.blank? and @facility_output_config.details[:ref_ev_batchid]== true
    transaction_segments << reciever_id
    transaction_segments << date_time_reference
    transaction_segments << payer_identification_loop
    transaction_segments << payee_identification_loop
    transaction_segments << claim_loop
    transaction_segments << provider_adjustment
    transaction_segments = transaction_segments.flatten.compact
    @se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments unless transaction_segments.blank? 
  end

  def eobs #SUNIL: need to remove this method
    if @check_eob_hash
      @eobs = @check_eob_hash[check.id]
    else
      @eobs = check.insurance_payment_eobs if check.job
    end
  end

  #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    st_elements = []
    st_elements << 'ST'
    st_elements << '835'
    st_elements << (@index+1).to_s.rjust(4, '0')
    st_elements.join(@element_seperator)
  end
  
  #The BPR segment indicates the beginning of a Payment Order/Remittance Advice Transaction
  #Set and total payment amount, or enables related transfer of funds and/or
  #information from payer to payee to occur
  def financial_info
    bpr_elements = []
    bpr_elements << 'BPR'
    if (@check_amount.to_f > 0 && check.payment_method == "CHK")
      bpr_elements << "C"
    elsif (@check_amount.to_f.zero?)
      bpr_elements << "H"
    elsif (@check_amount.to_f > 0 && check.payment_method == "EFT")
      bpr_elements << "I"
    elsif (check.payment_method == "OTH")
      bpr_elements << "D"
    end
    bpr_elements << @check_amount
    bpr_elements << 'C'
    bpr_elements << payment_indicator
    if @check_amount.to_f > 0 && check.payment_method == "EFT"
      bpr_elements << "CCP"
      bpr_elements << "01"
      bpr_elements << "999999999"
      bpr_elements << "DA"
      bpr_elements << "999999999"
      bpr_elements << "9999999999"
      bpr_elements << "199999999"
      bpr_elements << "01"
      bpr_elements << "999999999"
      bpr_elements << "DA"
      bpr_elements << "999999999"
    else
      bpr_elements << ''
      if get_micr_condition
        bpr_elements << id_number_qualifier
        bpr_elements << (routing_number.blank? ? '': routing_number)
        bpr_elements << account_num_indicator
        bpr_elements << account_number
      else
        bpr_elements << ['', '', '', '']
      end
      bpr_elements << ['', '', '', '', '', '']
    end
    bpr_elements << effective_payment_date
    bpr_elements = bpr_elements.flatten
    bpr_elements = Output835.trim_segment(bpr_elements)
    bpr_elements.join(@element_seperator)
  end

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    trn_elements = []
    simple_client_array_for_1000000009 = ["NAVICURE", "ASCEND CLINICAL LLC"]
    trn_elements << 'TRN'
    trn_elements << '1'
    trn_elements <<  ref_number
    if simple_client_array_for_1000000009.include? (facility.client.name.upcase)
      trn_elements << '1000000009'
    elsif @check_amount.to_f > 0 && check.payment_method == "EFT"
      unless facility.facility_tin.blank?
        trn_elements <<  '1' + facility.facility_tin
      end
    else
      trn_elements <<  '1999999999'
    end
    trn_elements = Output835.trim_segment(trn_elements)
    trn_elements.join(@element_seperator)
  end
  
  def reciever_id    
  end

  #specifies pertinent dates and times of 835 generation
  def date_time_reference
    dtm_elements = []
    dtm_elements << 'DTM'
    dtm_elements << '405'
    dtm_elements << check.batch.date.strftime("%Y%m%d")
    dtm_elements.join(@element_seperator)
  end

  #The N1 loop allows for name/address information for the payer
  #which would be utilized to address remittance(s) for delivery.
  def payer_identification_loop(repeat = 1)
    payer = get_payer
    output_version = @facility_config.details[:output_version]
    Output835.log.info "\n payer is #{payer.name}"
    if payer
      payer_segments = []
      repeat.times do
        payer_segments << payer_identification(payer)
        payer_segments << address(payer)
        payer_segments << geographic_location(payer)
        payer_segments << unique_output_payid(payer) if @client.name.upcase == "QUADAX" and ((!(output_payid(payer).blank?))|| @eob_type == 'Patient')
        payer_segments << payer_additional_identification_bac(payer)
        payer_segments << reference_identification_bac
        payer_segments << submitter_identification_bac
        payer_segments << payer_technical_contact(payer) if ($IS_PARTNER_BAC || (output_version && output_version != '4010'))
      end
      payer_segments = payer_segments.compact
      payer_segments unless payer_segments.blank?
    end 
  rescue NoMethodError
    raise "Payer is missing for check : #{check.check_number} id : #{check.id}"
  end
  
  #The N1 loop allows for name/address information for the payee
  #which would be utilized to address remittance(s) for delivery.
  def payee_identification_loop(repeat = 1)
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? || payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility #if any of the billing provider address details is missing get facility address
      end
      payee_segments = []
      repeat.times do
        payee_segments << image_name_bac
        payee_segments << payee_identification(payee)
        payee_segments << address(payee)
        payee_segments << geographic_location(payee)
        payee_segments << payee_additional_identification(payee)
        payee_segments << payee_additional_identification_1_bac
        payee_segments << payee_additional_identification_2_bac
        payee_segments << name_bac
      end
      payee_segments = payee_segments.compact
      payee_segments unless payee_segments.blank?
    end      
  end
  
  def payer_identification(payer)
    elements = []
    elements << 'N1'
    elements << 'PR'
    elements << payer.name.strip.upcase[0...60].strip
    elements.join(@element_seperator)
  end

  def payer_technical_contact payer
    ['PER', 'BL', payer.name.strip.upcase[0...60].strip].join(@element_seperator)
  end

  def payee_identification(payee)
    elements = []
    elements << 'N1'
    elements << 'PE'
    facility_array = ["TATTNALL HOSPITAL COMPANY LLC","ORTHOPEDIC SURGEONS OF GEORGIA","OPTIM HEALTHCARE"]
    if (facility_array.include?(facility.name.upcase))
      eob = check.insurance_payment_eobs.first
      @facility_payee = FacilitySpecificPayee.find(:all,:conditions=>"facility_id=#{facility.id} and payer_type='#{@eob_type}'",:order=>"weightage desc")
      if @facility_payee
        @facility_payee.each do|facility_payee|
          identifier_position = eob.patient_account_number.upcase.index("#{facility_payee.db_identifier}")
          if (facility_payee.match_criteria.to_s == 'like' and !identifier_position.blank? and identifier_position >= 1 )
            @new_payee_name = facility_payee.payee_name
            break
          elsif (facility_payee.match_criteria.to_s == 'start_with' and !identifier_position.blank? and identifier_position == 0 )
            @new_payee_name = facility_payee.payee_name
            break
          elsif facility_payee.db_identifier == 'Other'
            @new_payee_name = facility_payee.payee_name
            break
          end
        end
      end
      elements << @new_payee_name.strip.upcase
    else
      if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
        n1_pe_02 = @facility_config.details[:payee_name].strip.upcase
      else
        n1_pe_02 = get_payee_name(payee)
      end
      elements << n1_pe_02
    end
   
    if @claim && !@claim.npi.blank?
      elements << 'XX'
      elements << @claim.npi.strip.upcase
    elsif !payee.npi.blank?
      elements << 'XX'
      elements << payee.npi.strip.upcase
    elsif @claim && !@claim.tin.blank?
      elements << 'FI'
      elements << @claim.tin.strip.upcase
    elsif !payee.tin.blank?
      elements << 'FI'
      elements << payee.tin.strip.upcase
    elsif !@facility.tin.blank?
      elements << 'FI'
      elements << @facility.tin.strip.upcase
    end
    elements.join(@element_seperator)
  end

  def get_payee_name(payee)
    payee.name.strip.upcase
  end

  def payee_additional_identification(payee)
    npi = (payee.class == Facility ? payee.output_npi : payee.npi)
    if  @claim && !@claim.npi.blank? || !npi.blank?
      elements = []
      elements << 'REF'
      elements << 'TJ'
      elements << @facility.output_tin
      elements.join(@element_seperator)
    end
  end

  def address(party)
    address_elements = []
    address_elements << 'N3'
    address_elements <<  party.address_one.strip.upcase if party.address_one
    address_elements.join(@element_seperator)
  end

  def geographic_location(party)
    location_elements = []
    location_elements << 'N4'
    location_elements <<  party.city.strip.upcase if party.city
    location_elements <<  party.state.strip.upcase if party.state
    location_elements <<  party.zip_code.strip if party.zip_code
    location_elements = Output835.trim_segment(location_elements)
    location_elements.join(@element_seperator)
  end

  def unique_output_payid(payer)
    output_payid_elements = []
    output_payid_elements << 'REF'
    output_payid_elements << '2U'
    if @eob_type == 'Patient'
      output_payid_elements << '99999'
    else
      output_payid_elements << output_payid(payer)
    end
    output_payid_elements = Output835.trim_segment(output_payid_elements)
    output_payid_elements.join(@element_seperator)
  end

  # Loop 2000 : identification of a particular
  # grouping of claims for sorting purposes
  def claim_loop
    segments = []
    Output835.log.info "\n\nCheck has #{eobs.length} eobs"
    eobs.each_with_index do |eob, index|
      segments << transaction_set_line_number(index + 1) 
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
  
  #The LX segment is used to provide a looping structure and
  #logical grouping of claim payment information.
  def transaction_set_line_number(index)
    elements = []
    elements << 'LX'
    elements << index.to_s.rjust(4, '0')
    elements.join(@element_seperator)
  end

  def ref_ev_loop
    elements = []
    elements << 'REF'
    elements << 'EV'
    elements << check.batch.batchid[0...50]
    elements.join(@element_seperator)
  end

  #supplies provider-level control information
  def transaction_statistics(eobs)
  end
  
  # Reports adjustments to the actual payment that are NOT
  # specific to a particular claim or service
  # These adjustments can either decrease the payment (a positive
  # number) or increase the payment (a negative number)
  # such as the remainder of check amount subtracted by total eob payemnts (provider adjustment)
  # or interest amounts of eobs etc.
  # On PLB segment this adjustment amount and interest amount should
  # always print with opposite sign. 
  def provider_adjustment
    eob_klass = Output835.class_for("Eob", facility)
    eob_obj = eob_klass.new(eobs.first, facility, payer, 1, @element_seperator) if eobs.first

    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)
    
    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    code, qual = eob_obj.service_payee_identification
    provider_adjustments = get_provider_adjustment
    write_provider_adjustment_excel(provider_adjustments)  if @plb_excel_sheet
    provider_adjustment_groups = provider_adjustment_grouping(provider_adjustments)
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = @client.group_code.to_s.strip
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << code
      provider_adjustment_elements << year_end_date
      plb_separator = facility_output_config.details["plb_separator"]
      provider_adjustment_groups.each do |key, prov_adj_grp|
        plb_03 = prov_adj_grp.first.qualifier.to_s.strip
        if !prov_adj_grp.first.patient_account_number.blank?
          plb_03 += plb_separator.to_s.strip + prov_adj_grp.first.patient_account_number.to_s.strip
          adjustment_amount = prov_adj_grp.first.amount
        else
          adjustment_amount = 0
          prov_adj_grp.each do |prov_adj|
            adjustment_amount = adjustment_amount.to_f + prov_adj.amount.to_f
          end
        end
        plb_03 = 'WO' if facility_group_code == 'ADC'
        provider_adjustment_elements << plb_03
        plb_amount = (format_amount(adjustment_amount) * -1).to_s.to_dollar
        provider_adjustment_elements << plb_amount
      end
      if interest_eobs && interest_eobs.length > 0 && !facility.details[:interest_in_service_line] && 
          facility_output_config.details[:interest_amount] == "Interest in PLB"
        interest_eobs.each do |eob|
          current_check = eob.check_information
          excel_row = [current_check.batch.date.strftime("%m/%d/%Y"), current_check.batch.batchid, current_check.check_number]
          plb05 = 'L6'+ plb_separator.to_s + eob.patient_account_number
          plb05 = 'L6' if facility_group_code == 'ADC'
          provider_adjustment_elements << plb05
          plb_interest =  (eob.amount('claim_interest') * -1).to_s.to_dollar
          provider_adjustment_elements << plb_interest
          if @plb_excel_sheet
            excel_row << plb05.split(plb_separator)
            excel_row << eob.amount('claim_interest').to_s.to_dollar
            @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
            @excel_index += 1
          end
        end
      end
      provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
      provider_adjustment_elements.join(@element_seperator) unless provider_adjustment_elements.empty?
    end
  end

  def write_provider_adjustment_excel provider_adjustments
    @excel_index = @plb_excel_sheet.last_row_index + 1
    provider_adjustments.each do |prov_adj|
      current_job = prov_adj.job
      current_job = Job.find(current_job.parent_job_id) if current_job.parent_job_id
      excel_row = [current_job.batch.date.strftime("%m/%d/%Y"), current_job.batch.batchid, current_job.check_number, prov_adj.qualifier,
        prov_adj.patient_account_number, format_amount(prov_adj.amount).to_s.to_dollar
      ]
      @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
      @excel_index += 1
    end
  end

  def output_payid(payer)
    facility_payer_info = FacilitiesPayersInformation.find(:first,
      :conditions => "payer_id = #{payer.id} and facility_id = #{@facility.id}
           and output_payid is not null") if payer.id
    facility_payer_info.blank? ? nil : facility_payer_info.output_payid
  end
  
  def get_provider_adjustment
    job = check.job
    job.get_all_provider_adjustments
  end
  
  def provider_adjustment_grouping(provider_adjustments)
    provider_adjustments.group_by{|prov_adj| "#{prov_adj.qualifier}_#{prov_adj.patient_account_number}"}
  end
  
  def transaction_set_trailer(segment_count)
    se_elements = []
    se_elements << 'SE'
    se_elements << segment_count
    se_elements << (@index + 1).to_s.rjust(4, '0')
    se_elements.join(@element_seperator)
  end

  def federal_tax_id
    tin = facility.facility_tin
    (tin unless tin.blank?) || '999999999'
  rescue
    '999999999'
  end

  def facility_npi
    facility.facility_npi
  end

  def facility_type_code
    eobs.first.facility_type_code || '13'
  rescue
    '13'
  end

  def year_end_date
    "#{Date.today.year()}1231"
  end

  def sum_eob_charges(eobs)
    if check.job
      sum = 0
      eobs.each { |eob| sum += eob.amount('total_submitted_charge_for_claim')}
      sum = ((sum == sum.truncate)? sum.truncate : sum)
      sum
    end
  end
  
  def check_amount
    if facility.sitecode.to_s.strip.upcase == '00549' # NYU specific logic
      amount = @eobs.collect(&:total_submitted_charge_for_claim).sum.to_f
    else
      amount = check.check_amount.to_f
    end
    amount = (amount == (amount.truncate)? amount.truncate : amount)
  end
  
  # Condition for displaying Micr related info.
  def get_micr_condition
    facility.details[:micr_line_info]
  end
  
  # TRN02 segment value
  def ref_number
    facility_name = facility.name.upcase
    if (facility_name == 'AHN' || facility_name == 'SUBURBAN HEALTH' ||
          facility_name == 'UWL' || facility_name == 'ANTHEM')
      batch = check.batch
      file_number = batch.file_name.split('_')[0][3..-1] rescue "0"
      date = batch.date.strftime("%Y%m%d")
      "#{date}_#{file_number}"
    else
      output_check_number
    end
  end

  def trim(string, size)
    if string.strip.length > size
      string.strip.slice(0,size)
    else
      string.strip.ljust(size)
    end
  end
  
  def payment_indicator
    #    correspondence_check? ? 'NON' : 'CHK'
    if check.payment_method == "CHK" || check.payment_method == "OTH"
      "CHK"
    elsif @check_amount.to_f.zero?
      "NON"
    elsif (@check_amount.to_f > 0 && check.payment_method == "EFT")
      "ACH"
    end
  end

  def id_number_qualifier
    check.correspondence? ? '' : '01'
  end

  def correspondence_check?
    if facility.sitecode.to_s.strip == '00549' #NYU specific logic
      @check_amount.zero?
    else
      check.correspondence? && @check_amount.to_f.zero?
    end
  end

  def routing_number
    (check.micr_line_information && !check.correspondence?) ? check.micr_line_information.aba_routing_number.to_s.strip : ''
  end

  def account_num_indicator
    check.correspondence? ? '' : 'DA'
  end

  def account_number
    check.correspondence? ? '' : (check.micr_line_information.payer_account_number.to_s.strip if check.micr_line_information)
  end
  
  def effective_payment_date
    if check.correspondence?
      date_config = facility_output_config.details[:bpr_16_correspondence]
    else
      date_config = facility_output_config.details[:bpr_16]
    end
    if date_config == "Batch Date"
      check.job.batch.date.strftime("%Y%m%d")
    elsif date_config == "835 Creation Date"
      Time.now.strftime("%Y%m%d")
    elsif date_config == "Check Date"
      check.check_date.strftime("%Y%m%d")
    end
  end

  #Identify the first eob having an associated claim record, then fetch the claim
  #Give precedence to payee details stored in claim, over the payee details entered in the app.
  def get_facility    
    claim = (eobs.collect {|eob| (eob.claim_information unless eob.claim_information.nil?)}).first

    if claim
      Output835.log.info "\n There's a claim associated with an eob, the claim id : #{claim.id},
     patient account num : #{claim.patient_account_number}"
      (claim.facility = facility)
    end
    claim || facility
  end

  def get_payer
    Output835.log.info "\n EOB Type is : #{check.eob_type}"
    if check.eob_type == 'Patient'
      eob = check.insurance_payment_eobs.first
      patient = eob.patients.first if eob
      if patient
        Output835.log.info "\n Getting patient details from patients table"
        full_address = "#{patient.address_one}#{patient.city}#{patient.state}#{patient.zip_code}"
        if full_address.blank?
          output_payer = Patient.new(:last_name => patient.last_name, :first_name => patient.first_name, :address_one => payer.address_one,
            :city => payer.city, :state => payer.state, :zip_code => payer.zip_code)
        else
          output_payer = patient
        end
      else
        Output835.log.info "\n Getting patient details from payers table as patient record does not exist"
        output_payer = payer
      end
      default_patient_name = @facility_output_config.details[:default_patient_name]
      unless default_patient_name.blank?
        output_payer.first_name, output_payer.last_name =  default_patient_name.strip.upcase.split
        output_payer.last_name ||= ""
      end
      output_payer
    else
      Output835.log.info "\n Getting payer details from payers table"
      payer
    end
  end

  # Formats a dollar amount that is to be printed in the output
  # returns the amount if present else returns 0
  def format_amount(amount)
    amount = amount.to_f
    (amount == amount.truncate) ? amount.truncate : amount
  end
    
  #This method is to bypass bac specific methods which is suffixed with 'bac'
  def method_missing m, *args
    unless m.to_s[-3..-1] == 'bac'
      super
    else
      nil
    end
  end

  def total_submitted_charges
    sum = 0
    @eobs.each do |eob|
      sum += eob.amount('total_submitted_charge_for_claim')
    end
    sum
  end

  def output_check_number
    check_num = check.check_number
    (check_num ? check_num.to_s : "0")
  end

end
