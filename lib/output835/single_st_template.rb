#Represents an 835 document with single ST/SE loop
class Output835::SingleStTemplate < Output835::Template

  # Wrapper for each check in this 835
  def transactions
    segments = []
    @check_nums = @checks.collect(&:check_number)
    @check_ids =  @checks.collect(&:id)
    @check = @checks.first
    @check_grouper.last_check = @check
    @batch = @check.batch
    @job = @check.job
    @flag = 0  #for identify if any of the billing provider details is missing
    @eob_type = @check.eob_type
    @eobs =  @checks.collect(&:insurance_payment_eobs).flatten
    @micr = @check.micr_line_information
    if @micr && @micr.payer && @facility.details[:micr_line_info]
      @payer = @micr.payer
    else
     @payer = @check.payer
    end
    @check_amount = check_amount.to_s.to_dollar
    @facility_output_config = @facility.output_config(@payer.payer_type)
    @is_correspndence_check = @check.correspondence?
    segments += generate_check
    segments
  end

  
  #  If grouping is 'By Check',returns Payer id from Payer table
  #  If grouping is 'By Payer',returns Payer id from Payer table for Insurance eobs
  #  and Patpay payer Id from FC UI for PatPay eobs.
  #  If grouping is 'By Batch', 'By Batch Date',returns commercial payer Id from FC UI
  #  for Insurance eobs and Patpay payer Id from FC UI for PatPay eobs.
  def payer_id
    payer = @first_check.payer
    payer_type = payer.payer_type if payer
    output_config = @facility.output_config(payer_type)
    @payid = case output_config.grouping
    when 'By Check'
      @first_check.supply_payid if @first_check
    when 'By Payer','By Payer Id'
      payer_wise_payer_id(output_config)
    when 'By Batch', 'By Batch Date', 'By Cut'
      generic_payer_id(output_config)
    end
  end

  # The use of identical data interchange control numbers in the associated
  # functional group header and trailer is designed to maximize functional
  # group integrity. The control number is the same as that used in the
  # corresponding header.
  def functional_group_trailer(*args)
    ['GE', '0001', '2831'].join(@element_seperator)
  end

  def generate_check
    transaction_segments = [transaction_set_header, financial_info, reassociation_trace,
         date_time_reference, payer_identification_loop, payee_identification_loop,
         claim_loop, provider_adjustment]
    transaction_segments = transaction_segments.flatten.compact
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments
  end

  #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    ['ST', '835', '0001'].join(@element_seperator)
  end

  def financial_info(facility = nil,check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
    @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
    @micr = @micr.nil?? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil?? correspondence_check : @is_correspndence_check
      @check_amount = @check_amount.nil?? check_amount : @check_amount
    @facility_output_config = @facility_output_config.nil?? facility_config : @facility_output_config
    bpr_elements = ['BPR']
    if @check_amount.to_f > 0
      bpr_elements << "C"
      bpr_4_element = "CHK"
    elsif (@check_amount.to_f.zero?)
      bpr_elements << "H"
      bpr_4_element = "NON"
    end
    bpr_elements += [@check_amount.to_s.to_dollar, 'C', bpr_4_element]
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      bpr_elements += ["CCP", "01", "999999999", "DA", "999999999", "9999999999",
          "199999999", "01", "999999999", "DA", "999999999"]
    else
      bpr_elements << ''
      if get_micr_condition
        bpr_elements += [id_number_qualifier, routing_number.to_s, account_num_indicator, account_number]
      else
        bpr_elements << ['', '', '', '']
      end
      bpr_elements << ['', '', '', '', '', '']
    end
    bpr_elements << effective_payment_date
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end





  # If the returned object is of Payer class , print payer name.
  # If the returned object is of Facility class and
  # if the eob type is Patient, then print 'PATIENT PAYMENT' ,
  # elsif the eob type is Insurance, then print 'COMMERCIAL INSURANCE'
  def payer_identification(party)
    elements = ['N1', 'PR']
    payer_string = (@eob_type == 'Patient' ? 'PATIENT PAYMENT' : 'COMMERCIAL INSURANCE')
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
     @eobs.each_with_index do |eob, index|
      @check_grouper.last_eob = eob
      @check = eob.check_information
      @job = @check.job
      if @check.micr_line_information && @check.micr_line_information.payer && @facility.details[:micr_line_info]
        @payer = @check.micr_line_information.payer
      else
        @payer = @check.payer
      end
      @facility_output_config = @facility.output_config(@payer.payer_type)
      @reason_codes = nil    #this variable is used in  child class for configurable section
      @eob = eob
      @claim = eob.claim_information
      @eob_index = index
      @services = eob.service_payment_eobs
      @is_claim_eob = (eob.category.upcase == "CLAIM")
      @count = count
      segments << transaction_set_line_number(index + 1)
      segments << transaction_statistics([eob])
      segments += generate_eobs
    end
    segments.flatten.compact
  end

#to find the sequence number of check number of each eob
#its check whether it duplicates or not if duplicates it find out the occurence of repitaion and return that
  def count
    check = @eob.check_information
    if Output835.element_duplicates?(check.check_number, @check_nums)
      occurence = Output835.all_occurence(check.check_number, @check_nums)
      index_of_check_id = @check_ids.index(check.id)
      count = occurence[index_of_check_id]
    end
    count
  end

  def provider_adjustment(eobs = nil,facility = nil,payer=nil,check = nil,plb_excel_sheet = nil,facility_output_config = nil,xml_flag = nil)
    @eobs = @eobs.nil?? eobs : @eobs
    @facility = @facility.nil?? facility : @facility
    @payer = @payer.nil?? payer : @payer
    @check = @check.nil?? check : @check
    @plb_excel_sheet = @plb_excel_sheet.nil?? plb_excel_sheet : @plb_excel_sheet
     @facility_output_config = @facility_output_config.nil?? facility_output_config : @facility_output_config
    eob_klass = Output835.class_for("Eob", @facility)
    eob_obj = eob_klass.new(@eobs.first, @facility, @payer, 1, @element_seperator) if @eobs.first

    interest_exists_and_should_be_printed = false
    provider_adjustment_elements = []
    plb_separator = @facility_output_config.details["plb_separator"]
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    # Although EOBs with non zero interest amount exist, if the facility is configured
    # to have interest in service line, interest is not to be printed in PLB segment
    interest_exists_and_should_be_printed = (@facility.details[:interest_in_service_line] == false &&
        interest_eobs && interest_eobs.length > 0)

    # Follow the below hierarchy:
    # i. Payee NPI from 837
    # ii. If not, Payee TIN from 837
    # iii. If not NPI from FC UI
    # iv. If not TIN from FC UI
    code, qual = eob_obj.service_payee_identification
    provider_adjustments = get_provider_adjustment
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
      provider_adjustment_elements << code
      provider_adjustment_elements << "#{Date.today.year()}1231"
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
        plb_amount = (format_amount(adjustment_amount) * -1).to_s.to_dollar
        provider_adjustment_elements << plb_amount
      end
      provider_adjustment_elements = Output835.trim_segment(provider_adjustment_elements)
      provider_adjustment_final << provider_adjustment_elements
        end
      end
      write_provider_adjustment_excel  if @plb_excel_sheet
            interest_eob_length = interest_eobs.length
      if provider_adjustment_final && interest_eobs && interest_eob_length > 0 && !@facility.details[:interest_in_service_line] &&
          @facility_output_config.details[:interest_amount] == "Interest in PLB"
        last_provider_adjsutment_segment = provider_adjustment_final.last
        if last_provider_adjsutment_segment
          length_of_elements = last_provider_adjsutment_segment.length
          if length_of_elements < 15
            segment_elements = last_provider_adjsutment_segment[3, length_of_elements]
            more_segment_elements_to_add = 6 - (segment_elements.length / 2) if segment_elements
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

      if interest_eobs && interest_eob_length > 0 && more_segment_elements_to_add && more_segment_elements_to_add > 0
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
  def write_provider_adjustment_excel
    @excel_index = @plb_excel_sheet.last_row_index + 1
    @whole_checks.each do |check|
      job = check.job
      provider_adjustments = job.get_all_provider_adjustments
      provider_adjustments.each do |prov_adj|
        current_job = prov_adj.job
        current_job = Job.find(current_job.parent_job_id) if current_job.parent_job_id
        excel_row = [current_job.batch.date.strftime("%m/%d/%Y"), current_job.batch.batchid, current_job.check_number, prov_adj.qualifier,
          captured_or_blank_patient_account_number(prov_adj.patient_account_number), format_amount(prov_adj.amount).to_s.to_dollar
        ]
        @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
        @excel_index += 1
      end
    end
  end

  def get_provider_adjustment
    ids_of_all_jobs = []
    @checks.each do |check|
      job = check.job
      ids_of_all_jobs += job.get_ids_of_all_child_jobs if job.eob_count == 0
      ids_of_all_jobs << job.id
    end
    conditions = "provider_adjustments.job_id IN (#{ids_of_all_jobs.uniq.join(',')})"
    provider_adjustments = ProviderAdjustment.find(:all, :conditions => conditions)
    provider_adjustments.flatten.compact
  end

  def transaction_set_trailer(segment_count)
    ['SE', segment_count, '0001'].join(@element_seperator)
  end

  
  #  Total of check amount based on the output grouping.
  def check_amount
    @checks.inject(0) {|sum, c| sum = sum + c.check_amount.to_f}
  end

  # Condition for displaying Micr related info.
  def get_micr_condition
    @facility.details[:micr_line_info] &&  @facility_output_config.grouping == 'By Payer'
  end

  # TRN02 segment value for SourceCorp is always BatchID, For all other clients its Batch Date
  def ref_number
    if ['AHN', 'SUBURBAN HEALTH', 'UWL', 'ANTHEM'].include?(@facility_name)
      file_number = @batch.file_name.split('_')[0][3..-1] rescue "0"
      date = @batch.date.strftime("%Y%m%d")
      "#{date}_#{file_number}"
    else
      (@batch.batchid.include?("AH") ? @batch.batchid : @batch.date.strftime("%Y%m%d"))
    end
  end

  # If Output grouping is on the basis of payer,
  # and if its a insurance eob, and if client is not AHN return payer
  # else return payee
  def get_payer
    is_grouped_payerwise =  @facility_output_config.grouping == 'By Payer'
    if is_grouped_payerwise && @payer && @eob_type == 'Insurance' && @client_name != 'AHN'
      Output835.log.info "\n Getting payer details from payers table"
      @payer
    else
      Output835.log.info "\n Getting payer details from facilities table"
      @facility
    end
  end

  
  def generic_payer_id(output_config)
    case output_config.eob_type
    when 'Insurance EOB'
      if @facility.commercial_payerid
        @facility.commercial_payerid
      else
        raise "Commercial Payer ID must be configured to generate Single ST 835 for Insurance EOBs"
      end
    when 'Patient Payment'
      if @facility.patient_payerid
        @facility.patient_payerid
      else
        raise "Patient Payer ID must be configured to generate Single ST 835 for Patient EOBs"
      end
    end
  end

  def payer_wise_payer_id(output_config)
    case output_config.eob_type
    when 'Insurance EOB'
      @payer.supply_payid if @payer
    when 'Patient Payment'
      if @facility.patient_payerid
        @facility.patient_payerid
      else
        raise "Patient Payer ID must be configured to generate Single ST 835 for Patient EOBs"
      end
    end
  end

  def get_payee_name(payee)
    @facility.name.strip.upcase
  end
  
end