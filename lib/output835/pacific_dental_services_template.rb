class Output835::PacificDentalServicesTemplate < Output835::Template

  def interchange_control_header
    @gs3 = (@config_835[:payee_name].present? ? @config_835[:payee_name].upcase.justify(15) : @facility_name.justify(15) )
    [ 'ISA', '00', (' '*10), '00', (' '*10), 'ZZ', payer_id.to_s.justify(15),
      'ZZ', @gs3 , Time.now().strftime("%y%m%d"),
      Time.now().strftime("%H%M"), ((!@output_version || @output_version == '4010') ? 'U' : '^'),
      ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
      (@isa_record.isa_number.to_s.rjust(9, '0') if @isa_record), '0', 'P', '>'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', @payid, strip_string(@gs3),
      Time.now().strftime("%Y%m%d"), Time.now().strftime("%H%M"), '1', 'X',
      ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end


  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
    @claim_type_ppo = (@eob.claim_type.to_s.upcase.strip == "PREDETERMINATION PRICING ONLY - NO PAYMENT")
    claim_segments = [claim_payment_loop]
    claim_segments << include_claim_dates unless @claim_type_ppo
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
    claim_segments << claim_level_allowed_amount
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments << service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

   def generate_services
    is_adjustment_line = @service.adjustment_line_is?
    service_segments = []
    service_segments << service_payment_information unless is_adjustment_line
    service_segments << service_date_reference unless @claim_type_ppo
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
    service_segments << standard_industry_code_segments(@service)
    [service_segments.compact.flatten, pr_amount]
  end


  def functional_group_trailer(batch_id = nil)
    ['GE', checks_in_functional_group(batch_id), '1'].join(@element_seperator)
  end

  #The TRN segment is used to uniquely identify a claim payment and advice.
  def reassociation_trace
    ['TRN', '1', ref_number, '1999999999'].join(@element_seperator) if @payer
  end

  def provider_summary_info
    provider_tin = (@claim && @claim.tin.present?)? @claim.tin : @facility.output_tin
    first_claim = @eobs.first.claim_information
    facility_type_code = (first_claim ? first_claim.facility_type_code.to_s : "13")
    facility_type_code = "13" if facility_type_code.blank?
    ["TS3", provider_tin, facility_type_code, "#{Date.today.year()}1231",
      @eobs.length.to_s, total_submitted_charges.to_s.to_dollar].compact.join(@element_seperator)
  end

  def ref_ev_loop
  end

  def transaction_set_line_number(index)
    ['LX', index.to_s].join(@element_seperator)
  end

  def claim_payment_information
    claim_weight = claim_type_weight
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_weight, @eob.amount('total_submitted_charge_for_claim'),
      @eob.payment_amount_for_output(@facility, @facility_output_config),
      (claim_weight == 22 ? "" : @eob.patient_responsibility_amount), plan_type,
      @eob.claim_number, (eob_facility_type_code || "13"),
      (claim_freq_indicator || "1") ].trim_segment.join(@element_seperator)
  end

  def service_prov_name(eob = nil,claim = nil)
    @eob =  @eob.nil?? eob : @eob
    prov_id, qualifier = service_prov_identification
    [ 'NM1', '82', (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
      prov_last_name_or_org, @eob.rendering_provider_first_name, @eob.rendering_provider_middle_initial,
      '', '', qualifier, prov_id].trim_segment.join(@element_seperator)
  end

  def image_page_name
    image = @job.images_for_jobs.first.exact_file_name
    image_name = 'PD' + image.split('PD')[1]
    image_list = @job.client_images_to_jobs.map(&:images_for_job)
    output_image_name = "#{image_name}#{image_list[@eob.image_page_no - 1].actual_image_number}_#{image_list[@eob.image_page_to_number - 1].actual_image_number}"
    ['REF','ZZ', output_image_name].join(@element_seperator)
  end

  def claim_from_date
    from_date = @eob.claim_from_date
    unless from_date.blank?
      from_date = from_date.strftime("%Y%m%d")
      from_date = '19700101' if from_date == "20000101"
      can_print_date = (from_date == '19700101') ? true : can_print_service_date(from_date)
      ['DTM', '232', from_date].join(@element_seperator) if can_print_date
    end
  end

  #Specifies pertinent To dates of the claim
  def claim_to_date
    to_date = @eob.claim_to_date
    unless to_date.blank?
      to_date = to_date.strftime("%Y%m%d")
      to_date = '19700101' if to_date == "20000101"
      can_print_date = (to_date == '19700101') ? true : can_print_service_date(to_date)
      ['DTM', '233', to_date].join(@element_seperator) if can_print_date
    end
  end

  def composite_med_proc_id
    qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'AD'
    if bundled_cpt_code.present?
      elem = ["#{qualifier}>#{bundled_cpt_code}"]
    elsif proc_cpt_code.present?
      elem = ["#{qualifier}>#{captured_or_blank_proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
    elsif revenue_code.present?
      elem = ["NU>#{revenue_code}"]
    else
      elem = ["#{qualifier}>"]
    end
    elem = Output835.trim_segment(elem)
    elem.join('>')
  end

  def svc_procedure_cpt_code
    if bundled_cpt_code.present? and proc_cpt_code.present?
      qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'AD'
      elem = ["#{qualifier}>#{captured_or_blank_proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
      elem = Output835.trim_segment(elem)
      elem.join('>')
    end
  end

  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (from_date == to_date)

    if from_date && (!to_date || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      from_date = (from_date == "20000101") ? "19700101" : from_date
      can_print_date = (from_date == '19700101') ? true : can_print_service_date(from_date)
      service_date_elements =  dtm_472(from_date) if can_print_date
      service_date_elements unless service_date_elements.blank?
    else
      svc_date_segments << dtm_150(from_date) if can_print_service_date(from_date)
      svc_date_segments << dtm_151(to_date) if can_print_service_date(to_date)
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end
  
  def service_line_item_control_num
    if @service && @claim
      if @service.service_provider_control_number
        ['REF', '6R', (@service.service_provider_control_number)].join(@element_seperator)
      elsif @claim.claim_service_informations.present?
        service_info = @claim.claim_service_informations.where('id = ?', @service.claim_service_information_id).first
        unless service_info.provider_control_number.blank?
          ['REF', '6R', (service_info.provider_control_number)].join(@element_seperator)
        end if service_info
      end
    end
  end

  def effective_payment_date
    @is_correspndence_check && @check.check_date.present? ? @check.check_date.strftime("%Y%m%d") : super
  end

end