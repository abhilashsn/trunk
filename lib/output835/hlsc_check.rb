
class Output835::HlscCheck < Output835::Check
  #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    st_elements = []
    st_elements << 'ST'
    st_elements << '835'
    st_elements << transaction_counter
    st_elements.join(@element_seperator)
  end
  
  #The BPR segment indicates the beginning of a Payment Order/Remittance Advice Transaction
  #Set and total payment amount, or enables related transfer of funds and/or
  #information from payer to payee to occur
  def financial_info
    bpr_elements = []
    bpr_elements << 'BPR'
    bpr_elements << (check.correspondence? ? 'H' : 'I')
    bpr_elements << check_amount
    bpr_elements << 'C'
    bpr_elements << payment_indicator
    bpr_elements << ''
    bpr_elements << id_number_qualifier
    bpr_elements << routing_number if routing_number
    bpr_elements << account_num_indicator
    bpr_elements << account_number
    bpr_elements << (payer.supply_payid.rjust(10, '0') if payer)
    bpr_elements << "999999999"
    bpr_elements << "01"
    bpr_elements << "043000096"
    bpr_elements << "DA"
    bpr_elements << check.batch.facility.client_dda_number
    bpr_elements << check.batch.date.to_s.strip.split('-').join
    bpr_elements.join(@element_seperator)
  end

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    trn_elements = []
    trn_elements << 'TRN'
    trn_elements << '1'
    trn_elements << check.check_number
    trn_elements << (payer.supply_payid.rjust(10, '0') if payer)
    trn_elements << '999999999'
    trn_elements.join(@element_seperator)
  end

  def payee_additional_identification(payee)
    if legacy_provider_number      
      elements = []      
      elements << 'REF'
      elements << 'PQ'
      elements << legacy_provider_number
      elements.join(@element_seperator)
    end    
  end
  
  #The LX segment is used to provide a looping structure and
  #logical grouping of claim payment information.
  def transaction_set_line_number(index = 1)
    elements = []
    elements << 'LX'
    elements << index
    elements.join(@element_seperator)
  end

  #supplies provider-level control information
  def transaction_statistics(eobs)
    ts_elements = []
    ts_elements << "TS3"
    ts_elements << federal_tax_id
    ts_elements << (facility_type_code.blank? ? '13' :  facility_type_code)
    ts_elements << year_end_date
    ts_elements << eobs.length
    ts_elements << sum_eob_charges(eobs)
    ts_elements.join(@element_seperator)
  end

  def payee_identification(payee)
    elements = []
    elements << 'N1'
    elements << 'PE'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      n1_pe_02 = @facility_config.details[:payee_name].strip.upcase
    else
      n1_pe_02 = payee.name.strip.upcase
    end
    elements << n1_pe_02
    if !payee.facility_tin.blank?
      elements << 'FI'
      elements << payee.facility_tin
    elsif !payee.facility_npi.blank?
      elements << 'XX'
      elements << payee.facility_npi
    else
      elements << 'FI'
      elements << '999999999'
    end    
    elements.join(@element_seperator)
  end
  
  # Loop 2000 : identification of a particular
  # grouping of claims for sorting purposes
  def claim_loop
    segments = []
    index = 0
    eobs_grouped_by_bill_type.each do |bill_type, eobs|
      Output835.log.info "Bill Type: #{bill_type}"
      segments << transaction_set_line_number(index + 1)
      segments << transaction_statistics(eobs)
      eobs.each do |eob|
        eob_klass = Output835.class_for("Eob", facility)
        eob_obj = eob_klass.new(eob, facility, payer, index, @element_seperator) if eob
        Output835.log.info "Applying class #{eob_klass}"
        segments += eob_obj.generate
      end
      index += 1
    end
    segments = segments.flatten.compact
    segments unless segments.blank?
  end
  
  def transaction_set_trailer(segment_count)
    se_elements = []
    se_elements << 'SE'
    se_elements << segment_count
    se_elements << transaction_counter
    se_elements.join(@element_seperator)
  end

  def transaction_counter
    batch_id = check.batch.batchid.to_s
    batch_id = batch_id.length > 6 ? batch_id.slice(0, 6) : batch_id.rjust(6, '0')
	  "#{batch_id}#{ (@index + 1).to_s.rjust(3, '0') }"
  end
  
  def federal_tax_id
    tin = eobs.first.check_information.job.batch.facility.facility_tin
    (tin unless tin.blank?) || '999999999'
  rescue
    '999999999'
  end

  # HLSC Business Logic to determine
  # Legacy Provider Number
  def legacy_provider_number
    iplan = eobs.first.claim_information.iplan if eobs.first && eobs.first.claim_information
    supplimental_iplan = eobs.first.claim_information.supplemental_iplan if eobs.first && eobs.first.claim_information
    denied_amount = eobs.first.amount('total_denied') if eobs.first
    if iplan == 'MBR'
      supplimental_iplan
    elsif supplimental_iplan && denied_amount != 0.00
      supplimental_iplan
    elsif iplan
      iplan
    else
      payer.supply_payid if payer
    end
  end

  # Returns a 2D array of EOBs, by grouping them based on
  # Bill Type from Claim or the default bill type 
  def eobs_grouped_by_bill_type
    eobs.group_by do |eob|
      if eob.claim_information
        eob.claim_information.bill_type
      elsif
        "113"
      end
    end
  end
end