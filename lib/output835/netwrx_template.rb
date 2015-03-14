class Output835::NetwrxTemplate < Output835::Template

  def functional_group_trailer(batch_id)
    ['GE', checks_in_functional_group(batch_id), '2831'].join(@element_seperator)
  end

  def transaction_set_header
    ['ST', '835', (@check_index + 1).to_s.rjust(9, '0')].join(@element_seperator)
  end

    
  def address(party)
    address_elements =  ['N3']
    address_elements << party.address_one.strip.upcase if party.address_one
    if (party.class == Payer)
      address_elements << party.address_two.strip.upcase if party.address_two
    end
    address_elements.trim_segment.join(@element_seperator)
  end

  def provider_adjustment_old(eobs = nil,facility = nil,payer=nil,check = nil,plb_excel_sheet = nil,facility_output_config = nil)
    @eobs = @eobs.nil?? eobs : @eobs
    @facility = @facility.nil?? facility : @facility
    @payer = @payer.nil?? payer : @payer
    @check = @check.nil?? check : @check
    @plb_excel_sheet = @plb_excel_sheet.nil?? plb_excel_sheet : @plb_excel_sheet
    @facility_output_config = @facility_output_config.nil?? facility_output_config : @facility_output_config
    eob_klass = Output835.class_for("Eob", @facility)
    eob_obj = eob_klass.new(@eobs.first, @facility, @payer, 1, @element_seperator) if @eobs.first
    interest_exists_and_should_be_printed = false
    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.clone
    interest_eobs = interest_eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
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
    provider_adjustments = @check.job.provider_adjustments
    if provider_adjustments.length > 0 || interest_exists_and_should_be_printed
      provider_adjustment_elements = []
      provider_adjustment_elements << 'PLB'
      provider_adjustment_elements << code
      provider_adjustment_elements << "#{Date.today.year()}1231"
      provider_adjustments.each do |adjustment|
        plb_03 = adjustment.qualifier.to_s.strip()
        unless adjustment.patient_account_number.blank?
          plb_03 += ':'+ captured_or_blank_patient_account_number(adjustment.patient_account_number)
        end
        provider_adjustment_elements << plb_03
        provider_adjustment_elements << (format_amount(adjustment.amount) * -1)
      end
      if interest_eobs && interest_eobs.length > 0 && !@facility.details[:interest_in_service_line]
        interest_eobs.each do |eob|
          provider_adjustment_elements << 'L6:'+ captured_or_blank_patient_account_number(eob.patient_account_number)
          provider_adjustment_elements << (eob.amount('claim_interest') * -1)
        end
      end
      provider_adjustment_elements.join(@element_seperator) unless provider_adjustment_elements.empty?
    end
  end

  def transaction_set_trailer(segment_count)
    ['SE', segment_count, (@check_index + 1).to_s.rjust(9, '0')].join(@element_seperator)
  end

  def payid
    payer = @check.payer
    if payer
      output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(payer.id, @client.id, @facility.id)
      payid = (output_payid_record.blank?) ? 1000000009 : output_payid_record.output_payid
    end
    payid
  end

  def reassociation_trace
    ['TRN', '1', ref_number, '1000000009'].join(@element_seperator) if @payer
  end


  def financial_info(facility = nil,check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
      @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
      @check_amount = @check_amount.nil?? check_amount : @check_amount
      @micr = @micr.nil?? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil?? correspondence_check : @is_correspndence_check

    @facility_output_config = @facility_output_config.nil?? facility_config : @facility_output_config
    bpr_elements = ['BPR', bpr_01, @check_amount.to_s, 'C', payment_indicator]
    if @check_amount.to_f > 0 && @check.payment_method == "EFT"
      bpr_elements += ["CCP", "01", "999999999", "DA", "999999999", "9999999999",
          "199999999", "01", "999999999", "DA", "999999999"]
    else
      bpr_elements << (' ' * 11).split('')
    end
    bpr_elements << effective_payment_date
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

  def reciever_id
    ['REF', 'EV', @check.job.initial_image_name.to_s[0...50]].trim_segment.join(@element_seperator)
  end

  def transaction_set_line_number(index)
    ['LX', index.to_s.rjust(4, '0')].join(@element_seperator)
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
      segments << transaction_statistics([eob])
      segments += generate_eobs
    end
    segments.flatten.compact
  end

   
  def other_claim_related_id
    images = @job.images_for_jobs
    if images.length < 2
      eob_image = images.first
    else
      eob_image =  images.detect{|image|image.image_number == @eob.image_page_no}
    end
    ['REF', 'F8', eob_image.original_file_name].join(@element_seperator) if eob_image
  end

  def claim_payment_information
    claim_weight = claim_type_weight
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, @eob.amount('total_submitted_charge_for_claim'),
        @eob.amount('total_amount_paid_for_claim'),
         ( claim_weight == 22 ? "" : @eob.patient_responsibility_amount),
         plan_type, claim_number, eob_facility_type_code,
         claim_freq_indicator].trim_segment.join(@element_seperator)
  end

  #CLP07 segment
  def claim_number
    if @facility.name == 'HOT SPRINGS MEDICAL ASSOCIATE' and @eob.claim_number.blank?
      'NOTPROVIDED'
    else
      @eob.claim_number
    end
  end
  
  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name(eob = nil,claim = nil)
    @eob =  @eob.nil?? eob : @eob
    prov_id, qualifier = service_prov_identification
    ['NM1', '82', (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
        prov_last_name_or_org, @eob.rendering_provider_first_name,
       @eob.rendering_provider_middle_initial, '', '', qualifier,
       prov_id].trim_segment.join(@element_seperator)
  end

  #Specifies pertinent From date of the claim
  def claim_from_date
    if @eob.claim_from_date.present?
      if @eob.claim_from_date.strftime("%Y%m%d") == "20000101"
        claim_from_date = "00000000"
      else
        claim_from_date = @eob.claim_from_date.strftime("%Y%m%d")
      end
      can_print_date = (claim_from_date == '00000000') ? true : can_print_service_date(claim_from_date)
      ['DTM', '232', claim_from_date].join(@element_seperator) if can_print_date
    end
  end

  #Specifies pertinent To dates of the claim
  def claim_to_date
    if @eob.claim_to_date.present?
      if @eob.claim_from_date.strftime("%Y%m%d") == "20000101"
        claim_to_date = "00000000"
      else
        claim_to_date = @eob.claim_to_date.strftime("%Y%m%d")
      end
      can_print_date = (claim_to_date == '00000000') ? true : can_print_service_date(claim_to_date)
      ['DTM', '233', claim_to_date].join(@element_seperator) if can_print_date
    end
  end
  
end