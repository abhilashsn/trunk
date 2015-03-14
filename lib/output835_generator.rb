
class Output835Generator
  attr_reader :facility

  include Output835GeneratorHelper

  def initialize checks, facility, config
    @checks = checks
    @facility = facility
    @client = @facility.client
    @facility_config = config
    @config_835 = config.details
    @batch = checks.first.batch
    @output_version = @config_835[:output_version]

    initialize_segment_config
  end

  def create_segment seg_name, static_part
    if @config_835["configurable_segments"][seg_name]
      config_part = @config_835["#{seg_name}_segment"].convert_keys
      segment = config_part.merge(static_part).segmentize
      segment = eval( "if @#{seg_name}_config
                         segment.collect! do |element|
                           if element.include? '@'
                             element, default = element.split('@')
                           end
                           if element =~ /^\\[[^\\[\\]]+\\]$/
                             value = eval_hash @#{seg_name}_config[element]
                           else
                             value = element
                           end
                           ((value.blank? && default) ? default : value)
                         end
                       else
                         segment
                       end " )
      trim_segment(segment).join('*')
    else
      nil
    end
  end

  def eval_hash value_string
    eval(value_string.to_s)
  end

  def trim_segment(array)
    while array.last.blank?
      array.pop
    end
    array
  end

  def generate
    @isa_record = IsaIdentifier.find(:first)
    @counter =  @isa_record? @isa_record.isa_number.to_s.justify(9, '0') : nil
    segments = [interchange_control_header, functional_group_loop, interchange_control_trailer]
    segments = segments.flatten.compact
    unless segments.blank?
      if @config_835[:wrap_835_lines]
        segments = segments.join("~") + '~'
        segments = segments.scan(/.{1,80}/).join("\n")
      else
        segments = segments.join('~' + "\n") + '~'
      end
      @isa_record.update_attributes({:isa_number => (@isa_record.isa_number + 1)})
      return segments
    else
      return false
    end
  end

  def interchange_control_header
    isa_elements = {0=> 'ISA', 2 => ' ' * 10, 4 => ' ' * 10, 9 => Time.now().strftime('%y%m%d'),
        10 => Time.now().strftime('%H%M') }
    isa = create_segment('isa', isa_elements)
    isa = isa.split('*')
    isa[6] = isa[6].justify(15)
    isa[8] = isa[8].justify(15)
    isa.join('*')
  end

  def functional_group_loop
    segments = [functional_group_header, transactions,functional_group_trailer]
    segments = segments.flatten.compact
  end

  def interchange_control_trailer
    elements = {0 => 'IEA', 1 => '1'}
    create_segment 'iea', elements
  end
 
  def functional_group_header
    elements = {0 => 'GS', 1 => 'HP', 5 => "#{Time.now().strftime('%H%M')}", 7 => 'X'  }
    create_segment 'gs', elements
  end

  def transactions
    segments = []
    @batch_based_index = 0
    @checks.each_with_index do |check, index|
      @check = check
      @index = index
      @batch_based_index += 1
      @batch_based_index = 1 if new_batch?
      segments << generate_check
    end
    segments
  end

  def functional_group_trailer
    elements =  {0 => 'GE', 1 => @checks.length}
    create_segment 'ge', elements
  end

  def generate_check
    @micr = @check.micr_line_information
    if @micr && @micr.payer && @facility.details[:micr_line_info]
      @payer = @micr.payer
    else
      @payer = @check.payer
    end
    #check_image = @check.image_file_name.to_s
    @batch = @check.batch
    @eob_type = eob_type
    @eobs = @check.insurance_payment_eobs
    @payer_tin = (@payer && @payer.payer_tin) ? '1' + @payer.payer_tin : '1' + @facility.facility_tin
    @payerid =  @payer.payer_identifier(@micr)
    #st03 = (@claim && !@claim.npi.blank? || !@payee.npi.blank?) ? 'XX' :'FI'
    @check_sequence = (@index + 1).to_s
    @default_payer_address = @payer.default_payer_address(@facility, @check)
    @is_correspndence_check = correspondence_check?
    transaction_segments = [ transaction_set_header, financial_info, reassociation_trace]
    transaction_segments << ref_ev_loop if !@config_835.blank? and @config_835[:ref_ev_batchid]== true
    transaction_segments << date_time_reference
    transaction_segments << payer_identification_loop
    transaction_segments << payee_identification_loop
    transaction_segments << claim_loop
    transaction_segments << provider_adjustment
    #@se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
  end


  def transaction_set_header
    elements = {0 => 'ST', 1 => '835'}
    create_segment 'st', elements
  end

  def financial_info
    elements = {0 => 'BPR', 1 => (@is_correspndence_check ? 'H' : 'I'), 2 => @check.check_amount.to_s.to_dollar,
      3 => 'C', 4 => payment_indicator, 5 => '' }
    create_segment 'bpr', elements
  end

  def reassociation_trace
    if @payer
      elements =  {0 => 'TRN', 1 => '1'}
      create_segment 'trn', elements
    end
  end

  def ref_ev_loop
    elements = ['REF', 'EV', @batch.batchid.split('_').first].join('*')
  end

  def date_time_reference
    elements = {0 => 'DTM', 1 => '405'}
    create_segment 'dtm405', elements
  end

  def payer_identification_loop
    @default_payer_address = @payer.default_payer_address(@facility, @check)
    payer = get_payer
    if payer
      payer_segments = [payer_identification, address(payer), geographic_location(payer), payer_technical_contact(payer)]
      payer_segments = payer_segments.compact
    end
  end

  def payer_identification
    elements = {0 => 'N1', 1 => 'PR'}
    create_segment 'n1pr', elements
  end

  def address(party)
    elements = {0 => 'N3'}
    id = ((party.class == Payer ) ? 'pr' : 'pe')
    create_segment "n3#{id}", elements
  end

  def geographic_location(party)
    elements = {0 => 'N4', 4 => '', 5 => '', 6 => ''}
    id = ((party.class == Payer) ? 'pr' : 'pe')
    create_segment "n4#{id}", elements
  end

  def payer_technical_contact payer
    elements = {0 => 'PER', 1 => 'BL'}
    create_segment "per", elements
  end

  def payee_identification_loop
    @provider_tin = ((@claim && !@claim.tin.blank?) ? @claim.tin : @facility.facility_tin)
    @payee = find_payee
    @st03 = (@claim && !@claim.npi.blank? || !@payee.npi.blank?) ? 'XX' :'FI'
    if @payee
      payee_segments = [ payee_identification, address(@payee), geographic_location(@payee),payee_additional_identification(@payee),
        provider_number]
      payee_segments = payee_segments.compact
    end
  end

  def payee_identification
    elements = {0 => 'N1', 1 => 'PE'}
    create_segment 'n1pe', elements
  end

  def payee_additional_identification payee
    if @claim && !@claim.npi.blank? || !payee.npi.blank?
      elements = {0 => 'REF'}
     create_segment 'reftj', elements
    end
  end

  def provider_number
    elements = {0 => 'REF', 1 => 'PQ'}
    create_segment 'refpq', elements
  end

  def claim_loop
    segments = []
    lx_selection = @config_835[:lx_segment]["1"] rescue "1"
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

  def write_claim_payment_information(params)
    segments = []
    params[:eobs].each_with_index do |eob, index|
      @eob = eob
      @claim = eob.claim_information
      @services = eob.service_payment_eobs
      if params[:count_condition] == 'single' && index == 0
        lx01 = params[:index] ? params[:index] : index + 1
        segments << transaction_set_line_number(lx01, params[:justification], params[:value])
      elsif params[:count_condition] == 'multiple'
        segments << transaction_set_line_number(index + 1, params[:justification])
      end
      segments << provider_summary_info if index == 0
      segments << generate_eob
    end
    segments = segments.flatten.compact
  end

  def transaction_set_line_number(index, justification, value = nil)
    elements = []
    elements << 'LX'
    elements << (value ? value.to_s : index.to_s.rjust(justification, '0'))
    elements.join('*')
  end

  def transaction_set_trailer(segment_count)
     elements = {0 => 'SE', 1 => segment_count.to_s}
     create_segment 'se', elements
  end

  def provider_summary_info
    elements =  {0 => 'TS3', 3 => "#{Date.today.year()}1231", 4 => @eobs.length.to_s,
      5 => total_submitted_charges.to_s.to_dollar, 6 => '', 7 => '', 8 => ''}
    create_segment 'ts3', elements
  end

  def generate_eob
    is_claim_level_eob = claim_level_eob?
    @provider_npi =  ((@claim && !@claim.provider_npi.blank?) ? @claim.provider_npi : @facility.facility_npi)
    claim_segments = [claim_payment_loop]
    if @facility.sitecode.strip == "00895"
      claim_period_start_date = @claim.blank? ? nil : @claim.claim_statement_period_start_date
      @service_date =  claim_period_start_date.blank? ? nil : claim_period_start_date.strftime("%Y%m%d")
    else
      @service_date = claim_level_eob? ? eob.claim_from_date.strftime("%Y%m%d") : least_service_date
    end
    claim_segments << (is_claim_level_eob ? claim_from_date : statement_from_date)
    claim_segments << (is_claim_level_eob ? claim_to_date : nil)
    if @facility.details[:interest_in_service_line] == false
      claim_segments << claim_supplemental_info
    end
    #claim_segments << claim_level_allowed_amount
    claim_segments << (is_claim_level_eob ? standard_industry_code_segments(@eob) : service_payment_info_loop)
    update_clp! claim_segments
    claim_segments = claim_segments.flatten.compact
  end

  def claim_payment_loop
    if @config_835['nm1qc_segment'] &&  @config_835['nm1qc_segment']['9'].include?('ID')
      option = @config_835['nm1qc_segment']['9'][1..-2].downcase.gsub(' ', '_')
      eval("@id, @quali = @eob.#{option}_and_qualifier")
    end
    
    claim_payment_segments = [ claim_payment_information, claim_interest_information ]
    if claim_level_eob?
      cas_segments, @clp_05_amount = Output835.cas_adjustment_segments(eob,
      client, facility, payer, @element_seperator)
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << patient_name
    unless @eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    claim_payment_segments << service_prov_name
    #claim_payment_segments << service_prov_identifier
    #claim_payment_segments << reference_id
    #claim_payment_segments << image_page_name
    claim_payment_segments << other_claim_related_id
    claim_payment_segments = claim_payment_segments.compact
  end

  def claim_payment_information
    elements =  {0 => 'CLP', 1 => @eob.patient_account_number, 3 =>
        @eob.amount('total_submitted_charge_for_claim').to_s.to_dollar, 4 => @eob.amount('total_amount_paid_for_claim').to_s.to_dollar,
      5 => (@eob.claim_type_weight == 22 ? "" : @eob.patient_responsibility_amount.to_s.to_dollar.to_blank), 10 => '' }
   create_segment 'clp', elements
  end

  def claim_interest_information
    unless (@eob.amount('claim_interest').to_f.zero?)
      elements = {0 => 'CAS', 3 => @eob.amount('claim_interest').to_s.to_dollar}
      create_segment 'cas', elements
    end
  end

  def patient_name
    elements =  {0 => 'NM1', 1 => 'QC', 2 => '1', 5 => @eob.patient_middle_initial.to_s.strip, 6 => ''}
    create_segment 'nm1qc', elements
  end

  def insured_name
    elements =  {0 => 'NM1', 1 => 'IL', 2 => '1', 3 => @eob.subscriber_last_name.to_s.strip,
      4 => @eob.subscriber_first_name.to_s, 5 => @eob.subscriber_middle_initial.to_s.strip,
      6 => '', 7 => @eob.subscriber_suffix.to_s.strip}
    create_segment 'nm1il', elements
  end

  def service_prov_name
    elements = {0 => 'NM1', 1 => '82', 6 => '', 8 => 'PC' }
    create_segment 'nm182', elements
  end

   def other_claim_related_id
     amount = eval(@refig_config[@config_835['refig_segment']['2']]).to_f if @config_835['refig_segment']
     if amount && !amount.zero?
       elements = {0 =>'REF', 1 => 'IG'}
       create_segment 'refig', elements
     end
  end

  def claim_from_date
    unless @eob.claim_from_date.blank?
       elements =   {0 => 'DTM', 1=> '232'} unless @service_date.blank?
       create_segment 'dtm232', elements
    end
  end

  def statement_from_date
    unless @service_date.blank?
      elements =   {0 => 'DTM', 1=> '232'}
      create_segment 'dtm232', elements
    end
  end

  def claim_to_date
    unless @eob.claim_to_date.blank?
      elements = claim_end_date
      create_segment 'dtm233', elements
    end
  end

  def claim_supplemental_info
    amount = eval(@amti_config[@config_835['amti_segment']['2']]).to_f if @config_835['amti_segment']
    if amount && !amount.zero?
      elements = {0 => 'AMT', 1 => 'I'}
      create_segment 'amti', elements
    end
  end

  def service_payment_info_loop
    segments = []
    @clp_05_amount = 0
    @services.each_with_index do |service, index|
      @service = service
      @charge_amount = @service.amount('service_procedure_charge_amount')
      @paid_amount = @service.amount('service_paid_amount')
      service_segments = generate_services
      segments += service_segments[0]
      @clp_05_amount += service_segments[1]
    end
    segments
  end

  def generate_services
    service_segments = []
    if !@charge_amount.zero? || !@paid_amount.zero?
      service_segments = [service_payment_information, service_date_reference]
    end
    cas_segments, pr_amount = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, '*')
    service_segments << cas_segments
    service_segments << provider_control_number
    service_segments << service_supplemental_amount
    if !@charge_amount.zero? || !@paid_amount.zero?
      service_segments << standard_industry_code_segments(@service)
    end
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

  def service_payment_information
    if !@charge_amount.zero? || !@paid_amount.zero?
      @delimiter = @config_835['isa_segment']['16'] if @config_835['isa_segment']
      elements = {0 => 'SVC', 1 => composite_med_proc_id, 2 => @charge_amount.to_s.to_dollar,
        3 => @paid_amount.to_s.to_dollar }
      create_segment 'svc', elements
    end
  end

  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    @from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    @to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (@from_date == @to_date)

    if !@from_date.nil? && (@to_date.nil? || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      service_date_elements = dtm_472(@from_date)
      service_date_elements unless service_date_elements.blank?
    else
      if @from_date
       svc_date_segments << dtm_150(@from_date)
      end
      if @to_date
        svc_date_segments << dtm_151(@to_date)
      end
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end

  def dtm_472(date)
    elements = {0 => 'DTM', 1 => '472' }
    create_segment 'dtm472', elements
  end

  def dtm_150 date
    elements = {0 => 'DTM', 1 => '150'}
    create_segment 'dtm150', elements
  end

  def dtm_151 date
    elements = {0 => 'DTM', 1 => '151'}
    create_segment 'dtm150', elements
  end

  def provider_control_number
    unless @service.service_provider_control_number.blank?
      elements = {0 => 'REF', 1 => '6R'}
      create_segment 'ref6r', elements
    end
  end

  def service_supplemental_amount
    amount = eval(@amtb6_config[@config_835['amtb6_segment']['2']]).to_f if @config_835['amtb6_segment']
    unless amount.zero?
      elements = amtb6_elements
      create_segment 'amtb6', elements
    end
  end

  def provider_adjustment
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.clone
    interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}

    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (!interest_eobs.empty? && !@facility.details[:interest_in_service_line] )

    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    @eob = @eobs.first
    code, qual = service_payee_identification
    job = @check.job
    provider_adjustments = job.provider_adjustments
    if !provider_adjustments.empty? || interest_exists_and_should_be_printed
      facility_group_code = @facility.client.group_code.to_s.strip
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << code
      provider_adjustment_elements <<  "#{Date.today.year()}1231"
      plb_separator = @config_835["plb_separator"]
      provider_adjustment_groups = provider_adjustments.group_by{|prov_adj| "#{prov_adj.qualifier}_#{prov_adj.patient_account_number}"}
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
        provider_adjustment_elements << (format_amount(adjustment_amount) * -1).to_s.to_dollar
      end
      if interest_exists_and_should_be_printed && @config_835[:interest_amount] == "Interest in PLB"
        interest_eobs.each do |eob|
          plb05 = 'L6:'+ eob.patient_account_number
          plb05 = 'L6' if facility_group_code == 'ADC'
          provider_adjustment_elements << plb05
          provider_adjustment_elements << (eob.amount('claim_interest') * -1).to_s.to_dollar
        end
      end
      provider_adjustment_elements = trim_segment(provider_adjustment_elements).join('*')
      if @config_835['plb_segment']
        plb01 = eval(@plb_config[@config_835['plb_segment']['1']].to_s)
        plb01 = @config_835['plb_segment']['1'].to_s if plb01.blank?
        plb05 = @config_835['plb_segment']['5'].to_s
        provider_adjustment_elements = provider_adjustment_elements.split('*')
        provider_adjustment_elements[1] = plb01
        provider_adjustment_elements[5] = 'L6' if (plb05 != '[Patient Account Number]') && provider_adjustment_elements[5] && (provider_adjustment_elements[5][0..1] == 'L6')
        provider_adjustment_elements = provider_adjustment_elements.join('*')
      end
    provider_adjustment_elements

    end
  end

  
  
end
