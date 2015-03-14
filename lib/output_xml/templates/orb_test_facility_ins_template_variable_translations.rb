# This module is meant for translating function calls made in Trident Template.
# This module will be dynamically included in the Document class at processing runtime

module OutputXml::OrbTestFacilityInsTemplateVariableTranslations

  include Output835Helper

  def initialize
    @facility_output_config = FacilityOutputConfig.find(:first,:conditions=>"facility_id=#{@facility.id} and eob_type='Insurance EOB'")
    @config_835 = @facility_output_config.details
    @patient_responsibility_amount = 0
    @temp= Output835::Template.new(@checks, @facility, @facility_output_config)
  end
 
  def service_cas_segments
    is_adjustment_line = @service.adjustment_line_is?
    service_segments, elements = [], []
    unless is_adjustment_line
      # cas_segments, pr_amount, crosswalked_codes = Output835.cas_adjustment_segments(@service, @client, @facility, @payer, "*")
      cas_elements, cas_pr_elements, patient_responsibility_amount = Output835.get_adjustment_code_elements(@service, @client, @facility, @payer, @eob)
      elements = cas_elements if cas_elements.present?
      elements += cas_pr_elements if cas_pr_elements.present?
      cas_segments, grouped_elements_with_crosswalk_flag = Output835.separate_cas_segments(elements, [], "*", @facility)
      service_segments = grouped_elements_with_crosswalk_flag
    else
      patient_responsibility_amount = 0.0
    end
    @patient_responsibility_amount += patient_responsibility_amount.to_f
    return service_segments
  end

  def standard_industry_code_segments(entity, claim_level_eob = false)
    if claim_level_eob
      if @facility.details[:rc_crosswalk_done_by_client]
        lqhe_codes, codes_with_crosswalked_flag_array = Output835.get_standard_industry_codes(@payer, entity, @client, @facility)
      end
    else
      lqhe_codes, codes_with_crosswalked_flag_array = Output835.get_standard_industry_codes(@payer, entity, @client, @facility)
    end
    return codes_with_crosswalked_flag_array
  end


  def claim_cas_segments
    service_eob = nil
    @patient_responsibility_amount = 0
    claim_payment_segments, elements = [], []
    @eob.service_payment_eobs.collect{|service| service_eob=service if service.adjustment_line_is?}
    if !service_eob.blank?
      cas_elements, cas_pr_elements, patient_responsibility_amount = Output835.get_adjustment_code_elements(service_eob, @client, @facility, @payer,  @eob)
    end
    if @is_claim_eob
      cas_elements, cas_pr_elements, patient_responsibility_amount = Output835.get_adjustment_code_elements(@eob, @client, @facility, @payer,  @eob)
    end
    elements = cas_elements if cas_elements.present?
    elements += cas_pr_elements if cas_pr_elements.present?
    cas_segments, grouped_elements_with_crosswalk_flag = Output835.separate_cas_segments(elements, [], "*", @facility)
    claim_payment_segments = grouped_elements_with_crosswalk_flag
    @patient_responsibility_amount += patient_responsibility_amount.to_f
    return claim_payment_segments
  end

  def payee_identification
    elements = []
    elements << payee_name
    if @check.payee_npi.present?
      elements << 'XX'
      elements << @check.payee_npi.strip.upcase
    elsif @check.payee_tin.present?
      elements << 'FI'
      elements << @check.payee_tin.strip.upcase
    end
    return  elements.join("*")
  end

  
  def payee_name#(payee)
    claim = @eobs.map(&:claim_information).flatten.compact.first
    if @check.payee_name?
      @check.payee_name.strip.upcase
    elsif claim and claim.name?
      claim.name.strip.upcase
    elsif @config_835[:payee_name].present?
      @config_835[:payee_name].strip.upcase
    else
      @facility.name.strip.upcase
    end
  end

  def patient_responsibility_amount(claim_weight)
    claim_weight == 22 ? "" : @eob.patient_responsibility_amount
  end

  def service_prov_name
    if @eob && (@eob.provider_npi.present? || @eob.provider_tin.present?) && (@eob.rendering_provider_last_name.present? || @eob.rendering_provider_first_name.present?)
      prov_id = @eob.provider_npi.present? ? @eob.provider_npi : @eob.provider_tin
      qualifier = @eob.provider_npi.present? ? 'XX' : 'FI'
      no_last_name = @eob.rendering_provider_last_name.to_s.strip.blank?
      last_name = @eob.rendering_provider_last_name.upcase unless no_last_name
      first_name = @eob.rendering_provider_first_name
      middle_initial = @eob.rendering_provider_middle_initial
      suffix = @eob.rendering_provider_suffix
    elsif @eob.provider_organisation.present?
      last_name = @eob.provider_organisation.to_s.upcase
      prov_id = @eob.provider_npi.present? ? @eob.provider_npi : @eob.provider_tin
      qualifier = @eob.provider_npi.present? ? 'XX' : 'FI'
      unless prov_id.present?
        payee = get_facility
        prov_id = payee_npi(payee)
        qualifier = 'XX'
      end
      first_name = nil
      middle_initial = nil
      suffix = nil
      no_last_name = true
    else
      payee = get_facility
      if payee
        if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? || payee.state.blank? || payee.zip_code.blank?)
          @claim = payee.clone
          payee = @facility #if any of the billing provider address details is missing get facility address
        end
        prov_id = payee_npi(payee)
        qualifier = 'XX'
        entity = true
        no_last_name = true
        last_name = payee_name#(payee)
        middle_initial = nil
        suffix = nil
      end
    end
    if @facility.name.to_s.strip.upcase == "SOUTH NASSAU COMMUNITY HOSPITAL"
      last_name = "SOUTH NASSAU COMMUNITY HOSPITAL"
      no_last_name = true
      first_name,middle_initial,suffix = nil,nil,nil
    end
    return [(no_last_name ? '2': '1'), last_name, first_name,middle_initial, '',suffix, qualifier, prov_id]
  end

  def procedure_code_value
    elem = []
    qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
    if proc_cpt_code.present?
      code = "#{qualifier}:#{proc_cpt_code}"
    elsif revenue_code.present?
      code = "NU:#{revenue_code}"
    end
    if code.present?
      elem = [code, @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
    end
    return elem
  end

  def bundled_cpt_code_value
    elem = []
    qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
    if bundled_cpt_code.present?
      elem = ["#{qualifier}:#{bundled_cpt_code}"]
    end
    return elem
  end

  #  def composite_med_proc_id
  #    qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
  #    if bundled_cpt_code.present?
  #      elem = ["#{qualifier}:#{bundled_cpt_code}"]
  #    elsif proc_cpt_code.present?
  #      elem = ["#{qualifier}:#{proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
  #    elsif revenue_code.present?
  #      elem = ["NU:#{revenue_code}"]
  #    else
  #      elem = ["#{qualifier}:"]
  #    end
  #    return elem
  #  end

  def include_claim_dates
    from_date = @eob.claim_from_date.strftime("%Y-%m-%d") if @eob.claim_from_date.present?
    to_date = @eob.claim_to_date.strftime("%Y-%m-%d") if @eob.claim_to_date.present?
    #claim_from_date_value = @temp.claim_from_date
    claim_date_value= @is_claim_eob ? ( from_date == to_date ? [from_date,nil] : [from_date, to_date]) : [statement_from_date, @temp.statement_to_date]
    return claim_date_value
  end


  def statement_from_date
    claim_date = claim_start_date
    if claim_date
      claim_date.strftime("%Y-%m-%d")
    end
  end

  #Specifies pertinent dates and times of the claim
  def statement_to_date
  end


  def claim_start_date
    if @claim && @claim.claim_statement_period_start_date
      @claim.claim_statement_period_start_date
    end
  end


  def payee_npi(payee)
    if @check.payee_npi?
      @check.payee_npi.strip.upcase
    end
  end

  def payment_indicator
    payment_method = @check.payment_method
    if payment_method == "CHK" || payment_method == "OTH"
      "CHK"
    elsif payment_method == "ACH"
      @check.mismatch_transaction ? 'NON' : 'ACH'
    elsif @check_amount.to_f.zero?
      "NON"
    end
  end
  def bpr_01
    if (@check_amount.to_f > 0 && @check.payment_method == "CHK")
      "C"
    elsif @check.payment_method == 'ACH'
      @check.mismatch_transaction ? 'H' : 'C'
    elsif (@check_amount.to_f.zero?)
      "H"
    elsif (@check.payment_method == "OTH")
      "D"
    end
  end

  def amount_format(amount)
    amount = 0.0 if amount.blank?
    sprintf("%.2f",amount)
  end

  def output_check_number
    check_num = @check.check_number
    if (@check.payment_method == 'ACH' and @check.mismatch_transaction) || !check_num
      '0'
    else
      check_num.to_s
    end
  end


  def address(party)
    (party.address_one)? party.address_one.strip.upcase : 'PO BOX 9999'
  end

  def geographic_location(party)
    if party
      return [((party.city)? party.city.strip.upcase : 'UNKNOWN'),
        ((party.state)? party.state.strip.upcase : 'GA'),
        ((party.zip_code)? party.zip_code.strip : '12345') ]
    end
  end

  def sender_dfi
    bpr_elements = []
    if @facility.details[:micr_line_info]
      routing_number_to_print = routing_number
      id_qualifier =  routing_number_to_print.to_s.blank?? '' : id_number_qualifier
      account_number_value = account_number
      account_indicator = account_number_value.to_s.blank?? '' : account_num_indicator
      bpr_elements = [id_qualifier, routing_number_to_print, account_indicator, account_number_value ]
    else
      bpr_elements = ['', '', '', '']
    end
    return bpr_elements
  end

 
  def receiver_dfi
    bpr_elements = []
    aba_dda_lookup = @facility.aba_dda_lookups.first
    if aba_dda_lookup
      aba_number = aba_dda_lookup.aba_number
      dda_number = aba_dda_lookup.dda_number
    end
    if @check_amount.to_f > 0 && @check.payment_method != "EFT"
      aba_number = aba_number.blank? ? '' : aba_number
      aba_num_qualifier = aba_number.blank?? '':'01'
      bpr_elements << aba_num_qualifier
      bpr_elements << aba_number
      dda_number = dda_number.blank? ? '' : dda_number
      dda_num_qualifier = dda_number.blank?? '' : 'DA'
      bpr_elements << dda_num_qualifier
      bpr_elements << dda_number
    else
      bpr_elements << ['', '', '', '']
    end
    return bpr_elements
  end

  def check_amount
    amount = @check.check_amount.to_f
    (amount == (amount.truncate)? amount.truncate : amount)
  end


  def transaction_payer_id
    payer_name,payid = nil, nil
    payer_name = @first_check.payer.payer.upcase if @first_check && @first_check.payer
    if payer_name == 'EMPIRE BLUECROSS BLUESHIELD'
      payid ='00303'
    elsif ['OXFORD', 'UNITED HEALTHCARE'].include?(payer_name)
      payid ='87726'
    elsif @first_check.eob_type == 'Patient'
      payid ='P9998'
    else
      payid = @first_check.client_specific_payer_id(@facility)
      if payid.blank?
        payid = payer_id.to_s
      end
    end
    (payid.blank?)? "ORBOMED" : payid.to_s
  end

  def get_normalize_value(value)
    value.to_s.strip.upcase
  end

  def get_insurance_and_patpay_and_correspondece_checks(checks)
    job_ids = checks.map(&:job_id)
    @job_status, @job_rejected_comments, hash_of_checks = {}, {}, {}
    checks.each do |check|
      hash_of_checks[check.id] = check
    end
    @insurance_checks, @patpay_checks, @correspondence_checks = [], [], []
    jobs = Job.select("jobs.id AS id, check_informations.id AS check_id,
      jobs.payer_group, jobs.is_correspondence, jobs.rejected_comment, jobs.job_status").
      joins("INNER JOIN check_informations ON check_informations.job_id = jobs.id
      INNER JOIN client_images_to_jobs ON client_images_to_jobs.job_id = jobs.id
      INNER JOIN images_for_jobs ON images_for_jobs.id = client_images_to_jobs.images_for_job_id").
      where("jobs.id IN (:job_ids)", { :job_ids => job_ids }).
      group("jobs.id").order("images_for_jobs.actual_image_number")
    jobs.each do |job|
      segregate_checks(job, hash_of_checks)
      @job_rejected_comments[job.id] = normalized_rejected_comment(job.rejected_comment)
      @job_status[job.id] = job.job_status
    end
    return @insurance_checks, @patpay_checks, @correspondence_checks
  end

  def segregate_checks(job, hash_of_checks )
    if job.is_correspondence
      @correspondence_checks << hash_of_checks[job.check_id]
    else
      if job.payer_group == 'Insurance'
        @insurance_checks << hash_of_checks[job.check_id]
      else
        @patpay_checks << hash_of_checks[job.check_id]
      end
    end
  end

  def normalized_rejected_comment(rejected_comment)
    if rejected_comment.present? && rejected_comment != '--'
      comment = rejected_comment.upcase.strip
    else
      comment = nil
    end
    comment
  end

  def batch_level_status
    status = "OK"
    if @job_rejected_comments && @job_status
      job_ids = @job_rejected_comments.keys
      incomplete_status = @job_rejected_comments.values.compact
      job_status = @job_status.values.compact.uniq
      job_ids_length = job_ids.length
      all_jobs_incompleted = job_ids_length > 0 && job_status.length == 1 && job_status[0].upcase.strip == "INCOMPLETED"
      unique_incomplete_status = incomplete_status.uniq
      if all_jobs_incompleted && unique_incomplete_status.length == 1 && unique_incomplete_status[0] == "POOR IMAGE QUALITY"
        status = "Poor Image Quality"
        @send_one_transaction_tag_for_incomplete_jobs = true
      end
    end
    status
  end

  def normalize_status(status)
    normalized_status = status
    if status.present?
      words = status.split(' ')
      normalized_words = []      
      words.each do |word|
        word[0] = word[0].upcase
        normalized_words << word
      end
      normalized_status = normalized_words.join(" ")
    end
    normalized_status
  end

end

