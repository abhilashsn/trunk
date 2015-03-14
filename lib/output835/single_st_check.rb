class Output835::SingleStCheck < Output835::Check
  attr_reader :checks, :check, :index, :payer, :grouped_eobs, :facility, :output_config_grouping, :eob_type, :facility_output_config
  def initialize(checks, facility, index, element_seperator, check_num)
    @checks = checks
    @check = checks.first
    @index = index
    @element_seperator = element_seperator
    @facility = facility    
    @eob_type = check.eob_type
    if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
      @payer = check.micr_line_information.payer
    else
      @payer = check.payer
    end
    @client = @facility.client
    job = @check.job
    @facility_config = facility.facility_output_configs.first
    @facility_output_config = facility.output_config(job.payer_group)
    @output_config_grouping = @facility_output_config.grouping
    @flag = 0
    @check_amount = check_amount.to_s.to_dollar
    @check_num = check_num
    @check_id =  checks.collect{|check| check.id}
  end

  def generate
    check_numbers = checks.collect{|check| check.check_number} if checks && checks.length > 0
    Output835.log.info "\n\nChecks with numbers : #{check_numbers.join(' ,')} undergoing processing"
    Output835.log.info "Generating single ST-SE for all the above checks"
    transaction_segments =[]
    transaction_segments << transaction_set_header
    transaction_segments << financial_info
    transaction_segments << reassociation_trace
    transaction_segments << date_time_reference
    transaction_segments << payer_identification_loop
    transaction_segments << payee_identification_loop
    transaction_segments << claim_loop
    transaction_segments << provider_adjustment
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments unless transaction_segments.blank?
  end

  #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    st_elements = []
    st_elements << 'ST'
    st_elements << '835'
    st_elements << '0001'
    st_elements.join(@element_seperator)
  end

  def financial_info
    bpr_elements = []
    bpr_elements << 'BPR'
    if @check_amount.to_f > 0
      bpr_elements << "C"
      bpr_4_element = "CHK"
    elsif (@check_amount.to_f.zero?)
      bpr_elements << "H"
      bpr_4_element = "NON"
    end
    bpr_elements << @check_amount
    bpr_elements << 'C'
    bpr_elements << bpr_4_element
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




  # If the returned object is of Payer class , print payer name.
  # If the returned object is of Facility class and
  # if the eob type is Patient, then print 'PATIENT PAYMENT' ,
  # elsif the eob type is Insurance, then print 'COMMERCIAL INSURANCE'
  def payer_identification(party)
    elements = []
    elements << 'N1'
    elements << 'PR'
    payer_string = eob_type == 'Patient' ? 'PATIENT PAYMENT' : 'COMMERCIAL INSURANCE'
    unless party.class == Payer
      elements << payer_string
    else
      elements << party.name.strip.upcase
    end
    elements.join(@element_seperator)
  end
  
  # Loop 2000 : identification of a particular
  # grouping of claims for sorting purposes
  def claim_loop
    segments = []
    eobs.each_with_index do |eob, index|
      Output835.log.info "\n\n Check number #{eob.check_information.check_number} undergoing processing"
      Output835.log.info "\n\n Check has #{eob.check_information.insurance_payment_eobs.length} eobs"
      segments << transaction_set_line_number(index + 1)
      segments << transaction_statistics([eob])
      eob_klass = Output835.class_for("SingleStEob", facility)
      eob_obj = eob_klass.new(eob, facility, payer, index, @element_seperator, @check_num,count(eob)) if eob
      Output835.log.info "Applying class #{eob_klass}" if index == 0
      segments += eob_obj.generate
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end
  
#to find the sequence number of check number of each eob
#its check whether it duplicates or not if duplicates it find out the occurence of repitaion and return that
  def count(eob)
    str =eob.check_information.check_number
    if Output835.element_duplicates?(str, @check_num)
      occurence = Output835.all_occurence(str, @check_num)
      index_of_check_id = @check_id.index(eob.check_information.id)
      count = occurence[index_of_check_id]
    end
    count
  end

  def eobs
    checks.collect{|check| get_ordered_insurance_payment_eobs(check)}.flatten
  end

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
      write_provider_adjustment_excel  if @plb_excel_sheet
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

  def write_provider_adjustment_excel
    @excel_index = @plb_excel_sheet.last_row_index + 1
    checks.each do |check|
      job = check.job
      provider_adjustments = job.get_all_provider_adjustments
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
  end
  
  def get_provider_adjustment
    ids_of_all_jobs = []
    checks.each do |check|
      job = check.job
      ids_of_all_jobs += job.get_ids_of_all_child_jobs if job.eob_count == 0
      ids_of_all_jobs << job.id
    end
    conditions = "provider_adjustments.job_id IN (#{ids_of_all_jobs.uniq.join(',')})"
    provider_adjustments = ProviderAdjustment.find(:all, :conditions => conditions)
    provider_adjustments = provider_adjustments.flatten.compact
  end

  def transaction_set_trailer(segment_count)
    se_elements = []
    se_elements << 'SE'
    se_elements << segment_count
    se_elements << '0001'
    se_elements.join(@element_seperator)
  end
  
  protected ########################## PROTECTED Methods ########################

  #  Total of check amount based on the output grouping. 
  def check_amount
    checks.inject(0) {|sum, c| sum = sum + c.check_amount.to_f}
  end
  
  # Condition for displaying Micr related info.
  def get_micr_condition
    facility.details[:micr_line_info] && output_config_grouping == 'By Payer'
  end
  
  # TRN02 segment value for SourceCorp is always BatchID, For all other clients its Batch Date
  def ref_number
    batch = check.batch
    facility_name = facility.name.upcase
    if (facility_name == 'AHN' || facility_name == 'SUBURBAN HEALTH' ||
          facility_name == 'UWL' || facility_name == 'ANTHEM')
      file_number = batch.file_name.split('_')[0][3..-1] rescue "0"
      date = batch.date.strftime("%Y%m%d")
      "#{date}_#{file_number}"
    else
      (batch.batchid.include?("AH") ? batch.batchid : batch.date.strftime("%Y%m%d"))
    end
  end
  
  # If Output grouping is on the basis of payer,
  # and if its a insurance eob, and if client is not AHN return payer
  # else return payee
  def get_payer
    is_grouped_payerwise = output_config_grouping == 'By Payer'
    client = check.job.batch.client.name.upcase
    Output835.log.info "\n Grouping is #{output_config_grouping}"
    Output835.log.info "\n EOB Type is #{eob_type}"
    Output835.log.info "\n Client Name is #{client}"
    if is_grouped_payerwise && payer && eob_type == 'Insurance' && client != 'AHN'
      Output835.log.info "\n Getting payer details from payers table"
      payer
    else
      Output835.log.info "\n Getting payer details from facilities table"
      facility 
    end
  end

  def get_payee_name(payee)
    facility.name.strip.upcase
  end
 
end