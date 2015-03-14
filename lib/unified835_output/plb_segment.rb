# To change this template, choose Tools | Templates
# and open the template in the editor.

module  Unified835Output::PlbSegment

  def provider_adjustment
    interest_exists_and_should_be_printed = false
    provider_adjustment_elements = []
    plb_separator = @output_config.details["plb_separator"]
    @element_seperator = "*"
    @facility_name = @facility.name.upcase.strip
    @facility_lockboxes = @facility.facility_lockbox_mappings
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (@facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)
    provider_adjustments = @check.job.get_all_provider_adjustments
    write_provider_adjustment_excel(provider_adjustments)  if @plb_excel_sheet
    provider_adjustment_groups = provider_adjustment_grouping(provider_adjustments)
    provider_adjustment_group_keys = provider_adjustment_groups.keys
    provider_adjustment_group_values = provider_adjustment_groups.values
    start_index = 0
    array_length = 6
    provider_adjustment_to_print = []
    provider_adjustment_to_print,interest_eobs,facility_group_code = get_plb_segments(provider_adjustments,interest_exists_and_should_be_printed,provider_adjustment_group_keys,array_length,provider_adjustment_group_values,start_index,plb_separator,interest_eobs,provider_adjustment_to_print)
    get_provider_adjustment_with_interest_amount(provider_adjustment_to_print,interest_exists_and_should_be_printed,interest_eobs,@output_config.details[:interest_amount],provider_identifier, array_length,plb_separator)
    #provider_adjustment_elements = plb_interest_segments(interest_eobs,plb_separator,facility_group_code,provider_adjustment_elements)
   plb_interest_segments(interest_eobs,plb_separator,facility_group_code,provider_adjustment_elements)
    provider_adjustment_to_print
  end
  
  def get_provider_adjustment_with_interest_amount(provider_adjustment_to_print,interest_exists_and_should_be_printed,interest_eobs,config_details_interest_amount,provider_identifier, array_length,plb_separator)
    if provider_adjustment_to_print.empty? && interest_exists_and_should_be_printed && interest_eobs &&
        config_details_interest_amount == "Interest in PLB"
      plb_segment_with_interest_amount(interest_eobs, provider_identifier, array_length, provider_adjustment_to_print,plb_separator)
    end
  end

  def plb_interest_segments(interest_eobs,plb_separator,facility_group_code,provider_adjustment_elements)
    if interest_eobs && interest_eobs.length > 0 && !@facility.details[:interest_in_service_line] &&
        @output_config.details[:interest_amount] == "Interest in PLB"
      plb_segments_with_interest_eobs_to_excel(interest_eobs,plb_separator, provider_adjustment_elements)
    end
   end

  def plb_segments_with_interest_eobs_to_excel(interest_eobs,plb_separator, provider_adjustment_elements)
    interest_eobs.each do |eob|
      current_check = eob.check_information
      excel_row = [current_check.batch.date.strftime("%m/%d/%Y"), current_check.batch.batchid, current_check.check_number]
      plb05 = adjustment_reason_code('L6').to_s + plb_separator.to_s + provider_adjustment_identifier(eob.patient_account_number).to_s
      provider_adjustment_elements << plb05
      provider_adjustment_elements << provider_adjustment_amount(eob,true,true)
      provider_adjustment_in_excel_sheet(excel_row,plb05,eob)
    end
  end

  def provider_adjustment_in_excel_sheet(excel_row,plb05,eob)
    if @plb_excel_sheet
      excel_row << plb05.split(plb_separator)
      excel_row << provider_adjustment_amount(eob,true,false)
      @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
      @excel_index += 1
    end
  end

  def get_plb_segments(provider_adjustments,interest_exists_and_should_be_printed,provider_adjustment_group_keys,array_length,provider_adjustment_group_values,start_index,plb_separator,interest_eobs,provider_adjustment_to_print)
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      facility_group_code = @client.group_code.to_s.strip
      provider_adjustment_group_length = provider_adjustment_group_keys.length
      remaining_provider_adjustment_group = provider_adjustment_group_length % array_length
      total_number_of_plb_seg = (remaining_provider_adjustment_group == 0)?
        (provider_adjustment_group_length / array_length):
        ((provider_adjustment_group_length / array_length) + 1)
      plb_seg_number = 0
      provider_adjustment_final = []
      provider_adjustment_final = plb_segments_to_print_in_output(plb_seg_number,total_number_of_plb_seg,provider_adjustment_group_values,start_index,array_length,plb_separator,facility_group_code,provider_adjustment_final)


      interest_eob_length = interest_eobs.length
      more_segment_elements_to_add,create_new_plb_segment= plb_segment_last_provider_adjustment_segment(provider_adjustment_final,interest_eobs,array_length,plb_separator,facility_group_code,interest_eob_length)
      provider_adjustment_to_print = get_provider_adjustment_final(provider_adjustment_final,interest_eobs,interest_eob_length,more_segment_elements_to_add,create_new_plb_segment,provider_adjustment_to_print,array_length)
     end
    return provider_adjustment_to_print,interest_eobs,facility_group_code
  end
  def get_provider_adjustment_final(provider_adjustment_final,interest_eobs,interest_eob_length,more_segment_elements_to_add,create_new_plb_segment,provider_adjustment_to_print,array_length)
    provider_adjustment_final.each do |prov_adj_final|
      prov_adj_final_string = prov_adj_final.join(@element_seperator)
      provider_adjustment_to_print << prov_adj_final_string
    end
    provider_adjustment_to_print = plb_interest_more_segments(interest_eobs,interest_eob_length,more_segment_elements_to_add,create_new_plb_segment,provider_adjustment_to_print,array_length)

  end

  def plb_interest_more_segments(interest_eobs,interest_eob_length,more_segment_elements_to_add,create_new_plb_segment,provider_adjustment_to_print,array_length)
    if interest_eobs && interest_eob_length > 0 && ((more_segment_elements_to_add && more_segment_elements_to_add > 0) || create_new_plb_segment ) &&
        !@facility.details[:interest_in_service_line] &&
        @output_config.details[:interest_amount] == "Interest in PLB"
      remaining_interest_eobs = interest_eobs[more_segment_elements_to_add, interest_eob_length]
      if remaining_interest_eobs && remaining_interest_eobs.length > 0
        provider_adjustment_to_print << plb_segment_with_interest_amount(remaining_interest_eobs,
          array_length, provider_adjustment_to_print)
      end
    end
    return provider_adjustment_to_print
  end

  def plb_segment_last_provider_adjustment_segment(provider_adjustment_final,interest_eobs,array_length,plb_separator,facility_group_code,interest_eob_length)
    if provider_adjustment_final && interest_eobs && interest_eob_length > 0 && !@facility.details[:interest_in_service_line] &&
        @output_config.details[:interest_amount] == "Interest in PLB"
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
      plb_more_segments_to_print(more_segment_elements_to_add,interest_eobs,plb_separator,last_provider_adjsutment_segment)

    end
    return more_segment_elements_to_add,create_new_plb_segment
  end

  def plb_more_segments_to_print(more_segment_elements_to_add,interest_eobs,plb_separator,last_provider_adjsutment_segment)
    if more_segment_elements_to_add && more_segment_elements_to_add > 0
      interest_eobs_to_be_added_in_last_incomplete_plb_segemnt = interest_eobs[0, more_segment_elements_to_add]
      if interest_eobs_to_be_added_in_last_incomplete_plb_segemnt
        interest_eobs_to_added_in_last_incomplete_plb(interest_eobs_to_be_added_in_last_incomplete_plb_segemnt,plb_separator,last_provider_adjsutment_segment)
      end
    end
  end

  def  interest_eobs_to_added_in_last_incomplete_plb(interest_eobs_to_be_added_in_last_incomplete_plb_segemnt,plb_separator,last_provider_adjsutment_segment)
    interest_eobs_to_be_added_in_last_incomplete_plb_segemnt.each do |eob|
      if eob
        adjustment_identifier = adjustment_reason_code('L6').to_s + plb_separator.to_s + provider_adjustment_identifier(eob.patient_account_number).to_s
        last_provider_adjsutment_segment << adjustment_identifier
        last_provider_adjsutment_segment << provider_adjustment_amount(eob,false,true) #(eob.amount('claim_interest') * -1)
      end
    end
  end

  def plb_segments_to_print_in_output(plb_seg_number,total_number_of_plb_seg,provider_adjustment_group_values,start_index,array_length,plb_separator,facility_group_code,provider_adjustment_final)
    while(plb_seg_number < total_number_of_plb_seg)
      provider_adjustment_groups_new = provider_adjustment_group_values[start_index,array_length]
      if !provider_adjustment_groups_new.blank?
        plb_seg_number += 1
        start_index = array_length * plb_seg_number
        provider_adjustment_elements = []
        provider_adjustment_elements << 'PLB'
        provider_adjustment_elements <<  provider_identifier_for_plb
        provider_adjustment_elements << fiscal_period_date_for_plb
        provider_adjustment_elements = provider_adjustment_group_values(provider_adjustment_groups_new,plb_separator,facility_group_code,provider_adjustment_elements)

        provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
        provider_adjustment_final << provider_adjustment_elements
      end
    end
    return provider_adjustment_final
  end

  def provider_adjustment_group_values(provider_adjustment_groups_new,plb_separator,facility_group_code,provider_adjustment_elements)
    provider_adjustment_groups_new.each do |prov_adj_grp|
      plb_03 = adjustment_reason_code(prov_adj_grp.first.qualifier.to_s.strip)
      if !prov_adj_grp.first.patient_account_number.blank?

        plb_03 += plb_separator.to_s.strip + provider_adjustment_identifier(prov_adj_grp.first.patient_account_number).to_s
        adjustment_amount = prov_adj_grp.first.amount
      else
        adjustment_amount = 0
        prov_adj_grp.each do |prov_adj|
          adjustment_amount = adjustment_amount.to_f + prov_adj.amount.to_f
        end
      end
      # plb_03 = 'WO' if facility_group_code == 'ADC'
      provider_adjustment_elements << plb_03
      # provider_adjustment_elements << (format_amount(adjustment_amount) * -1)
      provider_adjustment_elements << provider_adjustment_amount(adjustment_amount,false,true,true)
    end
    return provider_adjustment_elements
  end

  def plb_segment_with_interest_amount(interest_eobs, array_length, provider_adjustment_to_print,plb_separator)
    provider_adjustment_header = ['PLB',provider_identifier_for_plb,fiscal_period_date_for_plb]
    interest_eobs.each_slice(array_length) do |eobs_with_interest|
      provider_adjustment_elements = []
      provider_adjustment_elements << provider_adjustment_header
      eobs_with_interest.each do |interest_eob|
        if interest_eob
          provider_adjustment_elements << adjustment_reason_code('L6').to_s + plb_separator.to_s + provider_adjustment_identifier(eob.patient_account_number).to_s
          provider_adjustment_elements << provider_adjustment_amount(interest_eob,false,true)#(interest_eob.amount('claim_interest') * -1)
        end
      end
      provider_adjustment_elements = provider_adjustment_elements.flatten
      provider_adjustment_to_print << provider_adjustment_elements.join(@element_seperator)
    end
  end
   
  #element_level
  def provider_identifier_for_plb
    if (['AVITA HEALTH SYSTEMS','METROHEALTH SYSTEM' ].include?(@facility_name) )
      code = identify_service_payee
    else
      code, qual =  (@client.name.gsub("'", "") == "CHILDRENS HOSPITAL OF ORANGE COUNTY")? service_payee_identification_choc : service_payee_identification
    end
   return code
  end

  def fiscal_period_date_for_plb
    "#{Date.today.year()}1231"
  end

  def provider_adjustment_amount(argument,format_flag,amount_negation,decimal_format=false)
  
    return (format_amount(argument) * -1) if decimal_format
 
    return (argument.amount('claim_interest') * -1) if (!format_flag && amount_negation)

    return argument.amount('claim_interest').to_s.to_dollar if (format_flag && !amount_negation)

    return (argument.amount('claim_interest') * -1).to_s.to_dollar if (format_flag && amount_negation)
  end

  def adjustment_reason_code(adj_reason_code)
    adj_reason_code
  end

  def provider_adjustment_identifier(eob_patient_account_number)
    captured_or_blank_patient_account_number(eob_patient_account_number)
  end

  def identify_service_payee
    if has_default_identification
      facility_lockbox_value = facility_lockbox.npi.presence || facility_lockbox.tin.presence
      return facility_lockbox_value.strip.upcase if facility_lockbox_value
    end
    service_payee = @check.payee_npi.presence || (@claim && @claim.npi.presence) || @facility.npi.presence || @check.payee_tin.presence || (@claim && @claim.tin.presence) || @facility.tin.presence
    service_payee.strip.upcase if service_payee
  end
  
  def has_default_identification
    facilities = ['AVITA HEALTH SYSTEMS','METROHEALTH SYSTEM' ]
    @facility_lockboxes.map(&:lockbox_number).include?(@batch.lockbox) if facilities.include?(@facility_name)
  end

  def facility_lockbox
    @facility_lockboxes.where(:lockbox_number => @batch.lockbox).first if has_default_identification
  end

  #Added on sunday

   def provider_adjustment_grouping(provider_adjustments)
    provider_adjustments.group_by{|prov_adj| "#{prov_adj.qualifier}_#{prov_adj.patient_account_number}"}
  end

#  def output_payid(payer)
#    if payer.id
#      output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(payer.id, @client.id, @facility.id)
#      output_payid_record.output_payid if output_payid_record
#    end
#  end


  def write_provider_adjustment_excel provider_adjustments
    @excel_index = @plb_excel_sheet.last_row_index + 1
    provider_adjustments.each do |prov_adj|
      current_job = prov_adj.job
      current_job = Job.find(current_job.parent_job_id) if current_job.parent_job_id
      prov_adj_patient_account_number = prov_adj.patient_account_number
      if prov_adj_patient_account_number.blank? and (@client.name.to_s.upcase == 'ORBOGRAPH' || @client.name.to_s.upcase == 'ORB TEST FACILITY')
        prov_adj_patient_account_number = "-"
       end
      excel_row = [current_job.batch.date.strftime("%m/%d/%Y"), current_job.batch.batchid, current_job.check_number, prov_adj.qualifier,
        prov_adj_patient_account_number, format_amount(prov_adj.amount).to_s.to_dollar
      ]
      @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
      @excel_index += 1
    end
  end

   def service_payee_identification_choc
     code, qual = nil, nil
    if (@claim && @claim.payee_tin.present?)
      code = @claim.payee_tin
      qual = 'FI'
      Output835.log.info "Payee TIN from 837 is chosen"
    elsif @facility.facility_tin.present?
      code = @facility.facility_tin
      qual = 'FI'
      Output835.log.info "facility TIN from FC is chosen"
    end
    return code, qual
  end

  # Returns the following in that precedence.
  # i. User entered Provider NPI   ii. If not, Provider NPI from 837  iii.If not, Provider NPI from 837 iv. If not NPI from FC UI   v. If not TIN from FC UI
  # Returns qualifier 'XX' for NPI and 'FI' for TIN
  def service_payee_identification
    if (@claim && @claim.payee_npi.present?)
      code = @claim.payee_npi
      qual = 'XX'
      Output835.log.info "Payee NPI from the 837 is chosen"
    elsif (@claim && @claim.payee_tin.present?)
      code = @claim.payee_tin
      qual = 'FI'
      Output835.log.info "Payee TIN from 837 is chosen"
    elsif @facility.facility_npi.present?
      code = @facility.facility_npi
      qual = 'XX'
      Output835.log.info "facility NPI from FC is chosen"
    elsif @facility.facility_tin.present?
      code = @facility.facility_tin
      qual = 'FI'
      Output835.log.info "facility TIN from FC is chosen"
    end

    return code, qual
  end

  def captured_or_blank_patient_account_number(captured_ac_number, output_type = nil)
    default_ac_number = @facility.patient_account_number_default_match.to_s.upcase
    return captured_ac_number.to_s.strip if default_ac_number.blank?
    captured_ac_number.strip.upcase == default_ac_number ? blank_output_format(output_type) : captured_ac_number.to_s.strip
  end

  def captured_or_blank_patient_first_name(captured_first_name, output_type = nil)
    default_first_name = @facility.patient_first_name_default_match.to_s.upcase
    return captured_first_name.to_s.strip if default_first_name.blank?
    captured_first_name.strip.upcase == default_first_name ? blank_output_format(output_type) : captured_first_name.to_s.strip
  end

  def captured_or_blank_patient_last_name(captured_last_name, output_type = nil)
    default_last_name = @facility.patient_last_name_default_match.to_s.upcase
    return captured_last_name.to_s.strip if default_last_name.blank?
    captured_last_name.strip.upcase == default_last_name ? blank_output_format(output_type) : captured_last_name.to_s.strip
  end

   def blank_output_format(output_type)
    output_type.present? ? '-' : ''
  end

   def format_amount(amount)
    amount.to_s.to_dollar.to_f.to_amount
  end


end
