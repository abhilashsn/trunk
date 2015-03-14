class Output835::Template

  include Output835Helper
  def initialize(checks, facility, config, check_grouper=nil, conf = {},check_eob_hash=nil, total_jobs=nil)
    default_configuration = {:single_transaction => false, :element_seperator => '*', :segment_separator => '~', :lookahead => "\n"}
    conf.reverse_merge!(default_configuration)
    @single_transaction = conf[:single_transaction]
    @element_seperator = conf[:element_seperator]
    @segment_separator = conf[:segment_separator]
    @lookahead = conf[:lookahead]
    @check_eob_hash = check_eob_hash
    @checks = checks
    @facility = facility
    @facility_name = facility.name.upcase
    @client = facility.client
    @client_name = @client.name.strip.upcase
    @facility_config = config
    @config_835 = config.details
    @first_check = @checks.first
    @batch = @first_check.batch
    batchids = @checks.collect{|check| check.batch.id}
    @batchids = batchids.uniq
    @output_version = @config_835[:output_version]
    @isa_record = IsaIdentifier.first
    @delimiter = ':'
    @output_configs_hash = output_configs_hash
    @facility_lockboxes = @facility.facility_lockbox_mappings
    @check_grouper = check_grouper
    @total_jobs = total_jobs
  end

  def generate
    Output835.log.info "\n\n\n\n Starting 835 output generation at #{Time.now} for batch id/s #{@batchids} (without 835 config)\n\n\n"
    Output835.log.info "Total no. of checks : #{@checks.length}"
    segments = [interchange_control_header, functional_group_loop, interchange_control_trailer].flatten.compact
    if segments.blank?
      puts "835 output generation failed with errors, please refer <rails_root>/835Generation.log for details"
      return false
    else
      if @config_835[:wrap_835_lines]
        segments = segments.join(@segment_separator) + '~'
        segments = segments.scan(/.{1,80}/).join("\n")
      else
        segments = if (@config_835[:content_835_no_wrap])
          segments.join(@segment_separator) + '~'
        else
          segments.join(@segment_separator + @lookahead) + '~'
        end
      end
      @isa_record.update_attributes({:isa_number => (@isa_record.isa_number + 1)})
      return segments
    end
  end

  # Starts and identifies an interchange of zero or more
  # functional groups and interchange-related control segments
  def interchange_control_header
    ['ISA', '00', (' ' * 10), '00', (' ' * 10), 'ZZ', payer_id.to_s.justify(15),
      'ZZ', isa_08, Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
      ((!@output_version || @output_version == '4010') ? 'U' : '^'),
      ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
      (@isa_record.isa_number.to_s.justify(9, '0') if @isa_record), '0', 'P', ':'].join(@element_seperator)
  end

  # A functional group of related transaction sets, within the scope of X12
  # standards, consists of a collection of similar transaction sets enclosed by a
  # functional group header and a functional group trailer
  def functional_group_loop
    [functional_group_header, transactions, functional_group_trailer(@batch.id)].compact
  end

  def functional_group_header
    ['GS', 'HP', @payid, strip_string(gs_03), group_date, Time.now().strftime("%H%M"), '2831', 'X',
      ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end

  # The use of identical data interchange control numbers in the associated
  # functional group header and trailer is designed to maximize functional
  # group integrity. The control number is the same as that used in the
  # corresponding header.
  def functional_group_trailer(batch_id = nil)
    ['GE', checks_in_functional_group(batch_id), '2831'].join(@element_seperator)
  end


  # To define the end of an interchange of zero or more functional groups and
  # interchange-related control segments
  def interchange_control_trailer
    [ 'IEA', '1', (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)].join(@element_seperator)
  end

    
  # Wrapper for each check in this 835
  def transactions
    segments = []
    batch_based_index = 0
    @checks.each_with_index do |check, index|
      @check_grouper.last_check = check
      @check = check
      @check_index = index
      @batch = check.batch
      @job = check.job
      @flag = 0  #for identify if any of the billing provider details is missing
      @eob_type = @check.eob_type
      if @check.insurance_payment_eobs.length > 1
        @eobs =  get_ordered_insurance_payment_eobs(@check)
      else
        @eobs = @check.insurance_payment_eobs
      end
      @micr = @check.micr_line_information
      if @micr && @micr.payer && @facility.details[:micr_line_info]
        @payer = @micr.payer
      else
        @payer = @check.payer
      end
      @check_amount = check_amount
      @facility_output_config = if @output_configs_hash.has_key?(@job.payer_group)
        @output_configs_hash[@job.payer_group]
      else
        @output_configs_hash['Insurance']
      end
      batch_based_index += 1
      batch_based_index = 1 if new_batch?
      @batch_based_index =  batch_based_index
      @is_correspndence_check = @check.correspondence?
      segments += generate_check
      #need to store the check_id
    end
    segments
  end
  
  
  #Generating check level segments
  
  def generate_check
    Output835.log.info "\n\nCheck number : #{@check.check_number} undergoing processing"
    transaction_segments =[ transaction_set_header, financial_info, reassociation_trace]

    transaction_segments << ref_ev_loop if @facility_output_config.details[:ref_ev_batchid]
    transaction_segments += [reciever_id, date_time_reference, payer_identification_loop,
      payee_identification_loop, reference_identification]
    transaction_segments << claim_loop if !@check.interest_only_check
    transaction_segments << provider_adjustment


    transaction_segments = transaction_segments.flatten.compact
    @se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments
  end


  #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    ['ST', '835' ,(@check_index + 1).to_s.rjust(4, '0')].join(@element_seperator)
  end


  def financial_info(facility = nil,check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
    @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
    @micr = @micr.nil?? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil?? correspondence_check : @is_correspndence_check
    @facility_output_config = @facility_output_config.nil?? facility_config : @facility_output_config
    @check_amount = @check_amount.nil?? check_amount : @check_amount
    bpr_elements = [ 'BPR', bpr_01, @check_amount.to_s, 'C', payment_indicator]
    bpr_elements.delete_at(1) if bpr_elements[1].nil?
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      bpr_elements += ["CCP", "01", "999999999","DA", "999999999", "9999999999",
        "199999999", "01", "999999999", "DA", "999999999"]
    else
      bpr_elements << ''
      if @facility.details[:micr_line_info]
        bpr_elements += [id_number_qualifier,  routing_number, account_num_indicator, account_number]
      else
        bpr_elements += ['', '', '', '']
      end
      bpr_elements += ['', '', '', '', '', '']
    end
    bpr_elements << effective_payment_date
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

  
  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    simple_client_array_for_1000000009 = ["NAVICURE", "ASCEND CLINICAL LLC"]
    trn_elements = ['TRN', '1', ref_number]
    if simple_client_array_for_1000000009.include? (@client_name)
      trn_elements << '1000000009'
    elsif @check_amount.to_f > 0 && @check.payment_method == "EFT"
      trn_elements <<  '1' + @facility.facility_tin if @facility.facility_tin.present?
    else
      trn_elements <<  '1999999999'
    end
    trn_elements.trim_segment.join(@element_seperator)
  end

  
  #specifies pertinent dates and times of 835 generation
  def date_time_reference
    ['DTM', '405', @batch.date.strftime("%Y%m%d")].join(@element_seperator)
  end

  #The N1 loop allows for name/address information for the payer
  #which would be utilized to address remittance(s) for delivery.
  def payer_identification_loop(repeat = 1)
    payer = get_payer    
    if payer
      Output835.log.info "\n payer is #{payer.name}"
      payer_segments = []
      repeat.times do
        payer_segments << payer_identification(payer)
        payer_segments << address(payer)
        payer_segments << geographic_location(payer)
        payer_segments << unique_output_payid(payer) if @client_name == "QUADAX" && (((output_payid(payer).present?))|| @eob_type == 'Patient')
        payer_segments << payer_additional_identification(payer)
        payer_segments << payer_technical_contact(payer) if ((@output_version && @output_version != '4010'))
      end
      payer_segments.compact
    end
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
      address_payee = @facility.details[:default_payee_details] ? @facility : payee
      repeat.times do
        payee_segments << payee_identification(payee)
        payee_segments << address(address_payee)
        payee_segments << geographic_location(address_payee)
        payee_segments << payee_additional_identification(payee)
      end
      payee_segments.compact
    end
  end

  def payer_identification(payer)
    ['N1', 'PR', payer.name.strip.upcase[0...60].strip].join(@element_seperator)
  end

  def payer_technical_contact payer
    ['PER', 'BL', payer.name.strip.upcase[0...60].strip].join(@element_seperator)
  end

  def payee_identification(payee,check = nil,claim = nil,eobs = nil)
    @check =  @check.nil?? check : @check
    @claim = @claim.nil?? claim : @claim
    elements = ['N1', 'PE']
    elements << if @check.payee_name?
      @check.payee_name.strip.upcase
    elsif @config_835[:payee_name].present?
      @config_835[:payee_name].strip.upcase
    else
      get_payee_name(payee)
    end
    if @check.payee_npi.present?
      elements << 'XX'
      elements << @check.payee_npi.strip.upcase
#    elsif @claim && @claim.npi.present?
#      elements << 'XX'
#      elements << @claim.npi.strip.upcase
#    elsif payee.npi.present?
#      elements << 'XX'
#      elements << payee.npi.strip.upcase
    elsif @check.payee_tin.present?
      elements << 'FI'
      elements << @check.payee_tin.strip.upcase
#    elsif @claim && @claim.tin.present?
#      elements << 'FI'
#      elements << @claim.tin.strip.upcase
#    elsif payee.tin.present?
#      elements << 'FI'
#      elements << payee.tin.strip.upcase
#    elsif @facility.tin.present?
#      elements << 'FI'
#      elements << @facility.tin.strip.upcase
    end
    elements.join(@element_seperator)
  end

  def get_payee_name(payee)
    payee.name.strip.upcase
  end

  def payee_additional_identification(payee)
    if has_default_identification
      [ 'REF', 'TJ', facility_lockbox.tin.strip.upcase].join(@element_seperator)
    else
      npi = (payee.class == Facility ? payee.output_npi : payee.npi)
      tin_value =  @check.payee_tin.strip.upcase if @check.payee_tin.present?
#        @check.payee_tin.strip.upcase
#      elsif @claim && @claim.tin.present?
#        @claim.tin.strip.upcase
#      elsif payee.tin.present?
#        payee.tin.strip.upcase
#      elsif @facility.output_tin.present?
#        @facility.output_tin.strip.upcase
#      end
      if (@check.payee_npi.present?) && (tin_value.present?)
        [ 'REF', 'TJ', tin_value].join(@element_seperator)
      end
    end
  end

  def address(party)
    address_elements = ['N3']
    if has_default_identification && party and party.class != Payer
      address_elements << facility_lockbox.address_one.strip.upcase 
    elsif party && party.address_one
      address_elements <<  party.address_one.strip.upcase 
    end
    address_elements.join(@element_seperator)
  end

  def geographic_location(party)
    location_elements = ['N4']
    if has_default_identification and party.class != Payer
      location_elements << facility_lockbox.city.strip.upcase
      location_elements << facility_lockbox.state.strip.upcase
      location_elements << facility_lockbox.zipcode.strip
    else
      location_elements << party.city.strip.upcase if party.city
      location_elements <<  party.state.strip.upcase if party.state
      location_elements << party.zip_code.strip if party.zip_code
    end
    location_elements.join(@element_seperator)
  end

  def unique_output_payid(payer)
    ['REF', '2U', (@eob_type == 'Patient' ? '99999' : output_payid(payer))].trim_segment.join(@element_seperator)
  end

  
  #The LX segment is used to provide a looping structure and
  #logical grouping of claim payment information.
  def transaction_set_line_number(index)
    ['LX', index.to_s.rjust(4, '0')].join(@element_seperator)
  end

  def ref_ev_loop
    [ 'REF', 'EV', @batch.batchid[0...50]].join(@element_seperator)
  end

  
  # Reports adjustments to the actual payment that are NOT
  # specific to a particular claim or service
  # These adjustments can either decrease the payment (a positive
  # number) or increase the payment (a negative number)
  # such as the remainder of check amount subtracted by total eob payemnts (provider adjustment)
  # or interest amounts of eobs etc.
  # On PLB segment this adjustment amount and interest amount should
  # always print with opposite sign.
  #TODO: refactor
  def provider_adjustment(eobs = nil,facility = nil,payer=nil,check = nil,plb_excel_sheet = nil,facility_output_config = nil,orb_xml_flag=nil)
    @eobs = (@eobs.nil? || @eobs.blank? || orb_xml_flag) ? eobs : @eobs
    @facility = (@facility.nil? || orb_xml_flag)? facility : @facility
    @payer = (@payer.nil? || orb_xml_flag) ? payer : @payer
    @check = (@check.nil? || orb_xml_flag)? check : @check
    @plb_excel_sheet = @plb_excel_sheet.nil?? plb_excel_sheet : @plb_excel_sheet
    @facility_output_config = @facility_output_config.nil?? facility_output_config : @facility_output_config
    eob_klass = Output835.class_for("Eob", @facility)
    eob_obj = eob_klass.new(@eobs.first, @facility, @payer, 1, @element_seperator) if @eobs && @eobs.first

    interest_exists_and_should_be_printed = false
    provider_adjustment_elements = []
    plb_separator = @facility_output_config.details["plb_separator"]
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.delete_if{|eob| eob.claim_interest.to_f.zero?} if @eobs
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (@facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)

    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    if @client_name.gsub("'", "") == "CHILDRENS HOSPITAL OF ORANGE COUNTY"
      code, qual = service_payee_identification_choc
    else
      code, qual = eob_obj.service_payee_identification if eob_obj
    end
    
    provider_adjustments = @check.job.get_all_provider_adjustments
    write_provider_adjustment_excel(provider_adjustments)  if @plb_excel_sheet
    provider_adjustment_groups = provider_adjustment_grouping(provider_adjustments)
    provider_adjustment_group_keys = provider_adjustment_groups.keys
    provider_adjustment_group_values = provider_adjustment_groups.values
    start_index = 0
    array_length = 6
    provider_adjustment_to_print = []
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = @client.group_code.to_s.strip
      provider_adjustment_group_length = provider_adjustment_group_keys.length
      remaining_provider_adjustment_group = provider_adjustment_group_length % array_length
      total_number_of_plb_seg = (remaining_provider_adjustment_group == 0)?
        (provider_adjustment_group_length / array_length):
        ((provider_adjustment_group_length / array_length) + 1)
      plb_seg_number = 0
      provider_adjustment_final = []

      while(plb_seg_number < total_number_of_plb_seg)
        provider_adjustment_groups_new = provider_adjustment_group_values[start_index,array_length]
        unless provider_adjustment_groups_new.blank?
          plb_seg_number += 1
          start_index = array_length * plb_seg_number
          provider_adjustment_elements = []
          provider_adjustment_elements << 'PLB'
          provider_adjustment_elements <<  code
          provider_adjustment_elements << "#{Date.today.year()}1231"
         # plb_separator = @facility_output_config.details["plb_separator"]
          provider_adjustment_groups_new.each do |prov_adj_grp|
            plb_03 = prov_adj_grp.first.qualifier.to_s.strip
            if !prov_adj_grp.first.patient_account_number.blank?
              plb_03 += plb_separator.to_s.strip + captured_or_blank_patient_account_number(prov_adj_grp.first.patient_account_number)
              adjustment_amount = prov_adj_grp.first.amount
            else
              adjustment_amount = 0
              prov_adj_grp.each do |prov_adj|
                adjustment_amount = adjustment_amount.to_f + prov_adj.amount.to_f
              end
            end
            plb_03 = 'WO' if facility_group_code == 'ADC'
            provider_adjustment_elements << plb_03
            provider_adjustment_elements << (format_amount(adjustment_amount) * -1)
          end
          provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
          provider_adjustment_final << provider_adjustment_elements
        end
      end

      interest_eob_length = interest_eobs.length
      if provider_adjustment_final && interest_eobs && interest_eob_length > 0 && !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        last_provider_adjsutment_segment = provider_adjustment_final.last
        if last_provider_adjsutment_segment
          length_of_elements = last_provider_adjsutment_segment.length
          if length_of_elements < 15
            segment_elements = last_provider_adjsutment_segment[3, length_of_elements]
            more_segment_elements_to_add = 6 - (segment_elements.length / 2) if segment_elements
          elsif length_of_elements % array_length == 3
            create_new_plb_segment = true
            more_segment_elements_to_add = 0
          end
        end
        if more_segment_elements_to_add && more_segment_elements_to_add > 0
          interest_eobs_to_be_added_in_last_incomplete_plb_segemnt = interest_eobs[0, more_segment_elements_to_add]
          if interest_eobs_to_be_added_in_last_incomplete_plb_segemnt
            interest_eobs_to_be_added_in_last_incomplete_plb_segemnt.each do |eob|
              if eob
                adjustment_identifier = 'L6'+ plb_separator.to_s + captured_or_blank_patient_account_number(eob.patient_account_number)
                adjustment_identifier = 'L6' if facility_group_code == 'ADC'
                last_provider_adjsutment_segment << adjustment_identifier
                last_provider_adjsutment_segment << (eob.amount('claim_interest') * -1)
              end
            end
          end
        end
      end

       provider_adjustment_final.each do |prov_adj_final|
        prov_adj_final_string = prov_adj_final.join(@element_seperator)
        provider_adjustment_to_print << prov_adj_final_string
      end

      if interest_eobs && interest_eob_length > 0 && ((more_segment_elements_to_add && more_segment_elements_to_add > 0) || create_new_plb_segment ) &&
        !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        remaining_interest_eobs = interest_eobs[more_segment_elements_to_add, interest_eob_length]
        if remaining_interest_eobs && remaining_interest_eobs.length > 0
          provider_adjustment_to_print << plb_segment_with_interest_amount(remaining_interest_eobs,
            code, array_length, provider_adjustment_to_print)
        end
      end
    end

    if provider_adjustment_to_print.empty? && interest_exists_and_should_be_printed && interest_eobs &&
        @facility_output_config.details[:interest_amount] == "Interest in PLB"
      plb_segment_with_interest_amount(interest_eobs, code, array_length, provider_adjustment_to_print)
    end
  #  provider_adjustment_to_print
  #end



      if interest_eobs && interest_eobs.length > 0 && !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        interest_eobs.each do |eob|
          current_check = eob.check_information
          excel_row = [current_check.batch.date.strftime("%m/%d/%Y"), current_check.batch.batchid, current_check.check_number]
          plb05 = 'L6'+ plb_separator.to_s + captured_or_blank_patient_account_number(eob.patient_account_number)
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
#      provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
#      provider_adjustment_elements.join(@element_seperator) unless provider_adjustment_elements.empty?
#    end
    provider_adjustment_to_print
  end

  def plb_segment_with_interest_amount(interest_eobs, code, array_length, provider_adjustment_to_print)
    provider_adjustment_header = ['PLB',code,"#{Date.today.year()}1231"]
    interest_eobs.each_slice(array_length) do |eobs_with_interest|
      provider_adjustment_elements = []
      provider_adjustment_elements << provider_adjustment_header
      eobs_with_interest.each do |interest_eob|
        if interest_eob
          provider_adjustment_elements << 'L6:'+ captured_or_blank_patient_account_number(interest_eob.patient_account_number)
          provider_adjustment_elements << (interest_eob.amount('claim_interest') * -1)
        end
      end
      provider_adjustment_elements = provider_adjustment_elements.flatten
      provider_adjustment_to_print << provider_adjustment_elements.join(@element_seperator)
    end
  end

       
  def transaction_set_trailer(segment_count)
    [ 'SE', segment_count, (@check_index + 1).to_s.rjust(4, '0')].join(@element_seperator)
  end

                            
  def claim_loop
    segments = []
    @eobs.each_with_index do |eob, index|
      @check_grouper.last_eob = eob
      @eob = eob
      @claim = eob.claim_information
      @eob_index = index
      @services = eob.service_payment_eobs
      @is_claim_eob = (eob.category.upcase == "CLAIM")
      segments << transaction_set_line_number(index + 1)
      segments << provider_summary_info if index == 0
      segments << transaction_statistics([eob])
      segments += generate_eobs
    end
    segments.flatten.compact
  end


  # Generating Eob level segments



  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
    claim_segments = [claim_payment_loop, include_claim_dates]
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
    claim_segments << claim_level_allowed_amount
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments << service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end
 

  #Loop 2100 : Supplies information common to all services of a claim
  def claim_payment_loop
    claim_payment_segments = []
    @clp_pr_amount = nil
    claim_payment_segments << claim_payment_information
    service_eob = @services.detect{|service| service.adjustment_line_is? }
    if service_eob
      cas_segments, @clp_pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(service_eob,
        @client, @facility, @payer, @element_seperator, @eob, @batch, @check)
      claim_payment_segments << cas_segments
    end
    if @is_claim_eob
      cas_segments, @clp_05_amount, crosswalked_codes = Output835.cas_adjustment_segments(@eob,
        @client, @facility, @payer, @element_seperator, @eob, @batch, @check)
      claim_payment_segments << cas_segments
    end
    claim_payment_segments << patient_name
    unless @eob.pt_name_eql_sub_name?
      claim_payment_segments << insured_name
    end
    claim_payment_segments << service_prov_name
    claim_payment_segments << service_prov_identifier
    if @is_claim_eob
      claim_payment_segments << Output835.claim_level_remark_code_segments(@eob, @element_seperator, crosswalked_codes)
    end
    claim_payment_segments << image_page_name
    claim_payment_segments << medical_record_number
    claim_payment_segments << claim_uid if @client_name == "QUADAX"
    claim_payment_segments << other_claim_related_id
    claim_payment_segments.compact
  end

  def include_claim_dates
    @is_claim_eob ? [claim_from_date, claim_to_date] : [statement_from_date, statement_to_date]
  end

  #Supplies information common to all services of a claim
  def claim_payment_information
    claim_weight = claim_type_weight
    clp_elements = ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight,
      @eob.amount('total_submitted_charge_for_claim'), @eob.payment_amount_for_output(@facility, @facility_output_config),
      ( claim_weight == 22 ? "" : @eob.patient_responsibility_amount), plan_type, claim_number, eob_facility_type_code, claim_freq_indicator, nil,
      (@eob.drg_code if @eob.drg_code.present?)].trim_segment.join(@element_seperator)
  end

  # Get claim_number for payer_group not of type 'PatPay'
  def claim_number
    @eob.claim_number.to_s
  end

  def claim_supplemental_info
    unless @eob.claim_interest.blank? || @eob.claim_interest.to_f.zero?
      ["AMT", "I", @eob.amount('claim_interest')].join(@element_seperator)
    end
  end

  def claim_uid
    unless @eob.uid.blank?
      ["REF","BB", @eob.uid].join(@element_seperator)
    end
  end

  def claim_level_allowed_amount
    if @facility_output_config.details[:claim_level_allowed_amt] 
      claim_payment_amt = @eob.payment_amount_for_output(@facility, @facility_output_config)
      unless claim_payment_amt.to_f.zero?
        claim_level_supplemental_amount = @eob.claim_level_supplemental_amount
        unless claim_level_supplemental_amount.to_f.zero?
          ["AMT", "AU", claim_level_supplemental_amount].join(@element_seperator)
        end
      end
    end
  end


  #Supplies the full name of an individual or organizational entity
  def patient_name
    patient_id, qualifier = @eob.patient_id_and_qualifier
    patient_name_details = [ 'NM1', 'QC', '1', captured_or_blank_patient_last_name(@eob.patient_last_name),
      captured_or_blank_patient_first_name(@eob.patient_first_name), @eob.patient_middle_initial.to_s.strip,
      '', @eob.patient_suffix, qualifier, patient_id].trim_segment
    return nil if patient_name_details == [ 'NM1', 'QC', '1']
    patient_name_details.join(@element_seperator)
  end

  # Required when the insured or subscriber is different from the patient
  def insured_name
    if @eob_type != 'Patient'
      id, qual = @eob.member_id_and_qualifier
      ['NM1', 'IL', '1', @eob.subscriber_last_name, @eob.subscriber_first_name,
        @eob.subscriber_middle_initial, '', @eob.subscriber_suffix, qual,id].trim_segment.join(@element_seperator)
    end
  end

  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name(eob = nil,claim = nil )
    @eob =  @eob.nil?? eob : @eob
    prov_id, qualifier = service_prov_identification
    ['NM1', '82', (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
      prov_last_name_or_org, @eob.rendering_provider_first_name,
      @eob.rendering_provider_middle_initial, '', @eob.rendering_provider_suffix,
      qualifier, prov_id].trim_segment.join(@element_seperator)
  end

  def medical_record_number
    if @eob.medical_record_number.present?
      elem = ['REF','EA', @eob.medical_record_number].trim_segment.join(@element_seperator)
    elsif @eob.claim_information.present? && @eob.claim_information.medical_record_number.present?
      elem = ['REF','EA', @eob.claim_information.medical_record_number].trim_segment.join(@element_seperator)
    end
  end

  # Used when additional reference numbers specific to the claim in the
  # CLP segment are provided to identify information used in the process of
  # adjudicating this claim
  def other_claim_related_id
    if @eob.insurance_policy_number.present?
      elem = ['REF','IG', @eob.insurance_policy_number].trim_segment.join(@element_seperator)
    end
  end

  #Specifies pertinent dates and times of the claim
  def statement_from_date
    claim_date = claim_start_date
    if claim_date &&  can_print_service_date(claim_date.strftime("%Y%m%d"))
      ['DTM', '232', claim_date.strftime("%Y%m%d")].join(@element_seperator)
    end
  end

  #Specifies pertinent dates and times of the claim
  def statement_to_date
  end

  #Specifies pertinent From date of the claim
  def claim_from_date
    if @eob.claim_from_date.present? && can_print_service_date(@eob.claim_from_date.strftime("%Y%m%d"))
      [ 'DTM', '232', @eob.claim_from_date.strftime("%Y%m%d")].join(@element_seperator)
    end
  end

  #Specifies pertinent To dates of the claim
  def claim_to_date
    if @eob.claim_to_date.present? && can_print_service_date(@eob.claim_to_date.strftime("%Y%m%d"))
      ['DTM', '233', @eob.claim_to_date.strftime("%Y%m%d")].join(@element_seperator)
    end
  end

          
  def service_payment_info_loop
    segments = []
    @clp_05_amount = 0
    @services.each_with_index do |service, index|
      @service = service
      @service_index = index
      @crosswalked_reason_codes = []
      @crosswalked_reason_code_objects = []
      service_segments = generate_services
      segments += service_segments[0]
      @clp_05_amount += service_segments[1]
    end
    segments
  end


  #generating service level segments


  def generate_services
    is_adjustment_line = @service.adjustment_line_is?
    service_segments = []
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference
    unless is_adjustment_line
      cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, @element_seperator, @eob, @batch, @check)
      service_segments << cas_segments
    else
      pr_amount = 0.0
    end
    service_segments << service_line_item_control_num unless is_adjustment_line
    service_segments << provider_control_number unless is_adjustment_line
    supp_amount = supplemental_amount
    service_segments << service_supplemental_amount(supp_amount)  unless supp_amount.blank? || @service.amount('service_paid_amount').blank?
    service_segments << patpay_specific_lq_segment if @facility.abbr_name == "RUMC"
    service_segments << standard_industry_code_segments(@service)
    [service_segments.compact.flatten, pr_amount]
  end

  
  #supplies payment and control information to a provider for a particular service
  def service_payment_information(eob = nil,service = nil,check = nil,is_claim_eob = nil,payer = nil)
    @service =  @service.nil?? service : @service
    ['SVC', composite_med_proc_id, @service.amount('service_procedure_charge_amount'), @service.amount('service_paid_amount'),
      svc_revenue_code, @service.service_quantity.to_f.to_amount, svc_procedure_cpt_code].trim_segment.join(@element_seperator )
  end


  #The DTM segment in the SVC loop is to be used to express dates and date
  #ranges specifically related to the service identified in the SVC segment
  # If service from and to dates are same, only print one segment with qual 472
  # Else print one segment each for the two dates
  def service_date_reference
    svc_date_segments = []
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (from_date == to_date)
    is_client_upmc = (@client_name == "UNIVERSITY OF PITTSBURGH MEDICAL CENTER")
    if from_date && (!to_date || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
       if(@client_name == "ISTREAMS" && from_date == "20000101")
         svc_date_segments = dtm_472("00000000")
       elsif !(is_client_upmc && from_date == "20000112")
          svc_date_segments = dtm_472(from_date) if can_print_service_date(from_date)
       end
    else
      svc_date_segments << dtm_150(from_date) if can_print_service_date(from_date)
      svc_date_segments << dtm_151(to_date)  if can_print_service_date(to_date)
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end


  def dtm_472(date)
    ['DTM', '472', date].join(@element_seperator)
  end


  def dtm_150 date
    ['DTM', '150', date].join(@element_seperator)
  end


  def dtm_151 date
    ['DTM', '151', date].join(@element_seperator)
  end


  def service_supplemental_amount amount
    ["AMT", "B6", amount].join(@element_seperator)
  end

  def provider_control_number
    if @facility.details[:reference_code] && @service.service_provider_control_number
      ['REF', '6R', @service.service_provider_control_number].trim_segment.join(@element_seperator)
    end
  end

  def trim(string, size)
    string.strip.ljust(size).slice(0, size)
  end
   
  def output_configs_hash
    {
      'Insurance' => @facility.output_config('Insurance'),
      'PatPay' => @facility.output_config('PatPay')
    }
  end
  
  def has_default_identification
    facilities = ['AVITA HEALTH SYSTEMS','METROHEALTH SYSTEM' ]
    @facility_lockboxes.map(&:lockbox_number).include?(@batch.lockbox) if facilities.include?(@facility_name)
  end

  def facility_lockbox
    @facility_lockboxes.where(:lockbox_number => @batch.lockbox).first if has_default_identification
  end

  # Method deletes the leading and trailing spaces of string.
  # Method is called for GS03 facility name as per the requirement Feature 23701

  def strip_string string
    string.strip
  end
end











  
