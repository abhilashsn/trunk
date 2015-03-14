class Output835::ShepherdEyeSurgicenterTemplate < Output835::Template

  # Starts and identifies an interchange of zero or more
  # functional groups and interchange-related control segments
  def interchange_control_header
    ['ISA', '00', (' ' * 10), '00', (' ' * 10), '30', '582574363      ',  '30', isa_08,
         Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
         ((!@output_version || @output_version == '4010') ? 'U' : '^'),
         ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
         (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record), '1', 'P', ':'].join(@element_seperator)
  end

  # header part of a functional group loop
  def functional_group_header
    ['GS', 'HP', payer_id, strip_string('1000000'), Time.now().strftime("%Y%m%d"), Time.now().strftime("%H%M"),
        (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record), 'X',
        ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end

  # The use of identical data interchange control numbers in the associated
  # functional group header and trailer is designed to maximize functional
  # group integrity. The control number is the same as that used in the
  # corresponding header.
  def functional_group_trailer(batch_id)
    ['GE', checks_in_functional_group(batch_id),
      (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record)].join(@element_seperator)
  end

  def payer_id
    payid = @facility_config.details[:isa_06]
    if payid == 'Predefined Payer ID'
      payer = @first_check.payer
      if payer
        output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(payer.id, @client.id, @facility.id)
	      payid = (output_payid_record.blank?) ? @facility_config.predefined_payer.to_s : output_payid_record.output_payid
      end
    else
      payid.to_s
    end
  end

  def isa_08
    if @config_835[:payee_name].present?
      @config_835[:payee_name].upcase.justify(15)
    else
      @facility.tin.justify(15)
    end
  end

  # This is the business identification information for the transaction
  # receiver. This may be different than the EDI address or identifier of the receiver
  def reciever_id
    [ 'REF', 'EV', @job.original_file_name.to_s[0...50]].trim_segment.join(@element_seperator) if @job.initial_image_name
  end

   #The ST segment indicates the start of a transaction set and assigns a control number
  def transaction_set_header
    ['ST', '835', (@check_index + 1).to_s.rjust(9, '0')].join(@element_seperator)
  end

  # Changing the logic back to that of July release as directed by Ops
  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    ['TRN', '1', @check.check_number, payid].join(@element_seperator) if @payer
  end

  # Loop 2000 : identification of a particular
  # grouping of claims for sorting purposes
  def claim_loop
    segments = transaction_set_line_number
    @eobs.each_with_index do |eob, index|
      @check_grouper.last_eob = eob
      @eob = eob
      @claim = eob.claim_information
      @eob_index = index
      @services = eob.service_payment_eobs
      @is_claim_eob = (eob.category.upcase == "CLAIM")
      segments << transaction_statistics([eob])
      segments += generate_eobs
    end
    segments.flatten.compact
  end

  #The LX segment is used to provide a looping structure and
  #logical grouping of claim payment information.
  def transaction_set_line_number
    [] << ['LX', '1'].join(@element_seperator)
  end

  #payee or payer address
  def address(party)
    address_elements =  ['N3']
    address_elements << party.address_one.strip.upcase if party.address_one
    if (party.class == Payer)
      address_elements << party.address_two.strip.upcase if party.address_two
    end
    address_elements.trim_segment.join(@element_seperator)
  end

  def provider_adjustment_old
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
    code = eob_obj.service_payee_identification
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

   #Supplies the full name of an individual or organizational entity
   #Required when the insured or subscriber is different from the patient
  def service_prov_name(eob = nil, claim = nil)
    @eob =  @eob.nil?? eob : @eob
    ['NM1', '82', (@eob.rendering_provider_last_name.strip.blank? ? '2': '1'),
        prov_last_name_or_org, @eob.rendering_provider_first_name,
        @eob.rendering_provider_middle_initial, '', '',
        ('FI' unless @eob.provider_tin.blank?),
        @eob.provider_tin].trim_segment.join(@element_seperator)
  end

  def other_claim_related_id
    images = @job.images_for_jobs
    eob_page_from = @eob.image_page_no
    index = eob_page_from - 1
#    if images.length < 2
    eob_image = images[index]
#    else
#      eob_image =  images.detect{|image|image.image_number == @eob.image_page_no}
#    end
#    eob_image.filename = eob_image.exact_file_name
    ['REF', 'F8', eob_image.original_file_name].join(@element_seperator) if eob_image
  end

  def generate_services
    is_adjustment_line = @service.adjustment_line_is?
    service_segments = []
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference
    unless is_adjustment_line
      cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, @element_seperator)
    else
      cas_segments, pr_amount = nil,0.0
    end
    service_segments << cas_segments unless is_adjustment_line
    service_segments << provider_control_number unless is_adjustment_line
    supp_amount = supplemental_amount
    service_segments << service_supplemental_amount(supp_amount) unless (supp_amount.blank? || supp_amount.to_f.zero?)
    [service_segments.compact.flatten, pr_amount]
  end

  #The DTM segment in the SVC loop is to be used to express dates and date
  #ranges specifically related to the service identified in the SVC segment
  # If service from and to dates are same, only print one segment with qual 472
  # Else print one segment each for the two dates
  def service_date_reference
    svc_date_segments = []
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    svc_date_segments << ['DTM', '150', from_date].join(@element_seperator) if can_print_service_date(from_date)
    svc_date_segments << ['DTM', '151', to_date].join(@element_seperator) if can_print_service_date(to_date)
    svc_date_segments unless svc_date_segments.blank?
  end


  
end