class Output835::ShepherdEyeSurgicenterCheck < Output835::NavicureCheck
   
  #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    st_elements = []
    st_elements << 'ST'
    st_elements << '835'
    st_elements << (@index + 1).to_s.rjust(9, '0')
    st_elements.join(@element_seperator)
  end
  
  # Changing the logic back to that of July release as directed by Ops  
  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    if payer
      trn_elements = []
      trn_elements << 'TRN'
      trn_elements << '1'
      trn_elements <<  check.check_number
      trn_elements << payer_id
      trn_elements.join(@element_seperator)
    end
  end
  
  # Loop 2000 : identification of a particular
  # grouping of claims for sorting purposes
  def claim_loop
    segments = []
    segments << transaction_set_line_number
    Output835.log.info "\n\nCheck has #{eobs.length} eobs"
    eobs.each_with_index do |eob, index|
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
  def transaction_set_line_number
    elements = []
    elements << 'LX'
    elements << '1'
    elements.join(@element_seperator)
  end
  
  #payee or payer address
  def address(party)
    address_elements = []
    address_elements << 'N3'
    address_elements << party.address_one.strip.upcase if party.address_one
    if (party.class == Payer)
      address_elements << party.address_two.strip.upcase if party.address_two
    end
    address_elements = Output835.trim_segment(address_elements.compact)
    address_elements.join(@element_seperator)
  end

  def provider_adjustment
    eob_klass = Output835.class_for("Eob", facility)
    eob_obj = eob_klass.new(eobs.first, facility, payer, 1, @element_seperator) if eobs.first
    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = eobs.clone
    interest_eobs = interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
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
    provider_adjustments = check.job.provider_adjustments
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << code
      provider_adjustment_elements << year_end_date
      provider_adjustments.each do |adjustment|
        plb_03 = adjustment.qualifier.to_s.strip()
        unless adjustment.patient_account_number.blank?
          plb_03 += ':'+ adjustment.patient_account_number.to_s.strip()
        end
        provider_adjustment_elements << plb_03
        provider_adjustment_elements << (format_amount(adjustment.amount) * -1)
      end
      if interest_eobs && interest_eobs.length > 0 && !facility.details[:interest_in_service_line]
        interest_eobs.each do |eob|
          provider_adjustment_elements << 'L6:'+ eob.patient_account_number
          provider_adjustment_elements << (eob.amount('claim_interest') * -1) 
        end
      end
      provider_adjustment_elements.join(@element_seperator) unless provider_adjustment_elements.empty?
    end
  end
 
  def transaction_set_trailer(segment_count)
    se_elements = []
    se_elements << 'SE'
    se_elements << segment_count
    se_elements << (@index + 1).to_s.rjust(9, '0')
    se_elements.join(@element_seperator)
  end
  
  def payer_id
    batch = check.batch
    facility = batch.facility
    check_payer = check.payer
    
    if check_payer
      default_payer = FacilitiesPayersInformation.find(:first,:conditions=>["facility_id = #{check.batch.facility.id} and payer= '#{check.payer.payer}' "])
      payid = (default_payer.blank?) ? 1000000009 : default_payer.output_payid
      
    end
    payid
  end

end