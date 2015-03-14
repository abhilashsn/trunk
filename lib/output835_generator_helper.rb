module Output835GeneratorHelper

  def initialize_segment_config

    @isa_config = {"[Payer ID Left Padded With 5 Zeroes]" => "payer_id.to_s.left_padd(15, 5, '0')",
      "[Payer ID]" => "payer_id.to_s", "[Facility Abbreviation]" => "@facility.abbr_name.to_s.strip",
      "[Facility Name]" => "@facility.name.to_s", "[Client TIN]" => "@facility.facility_tin.to_s.strip",
      "[Batch ID Left Padded With 9 Zeroes]" => "@batch.batchid.to_s.justify(9, '0')",
      "[Lockbox Number Left Padded With 0]" => "@facility.lockbox_number.to_s.justify(9, '0')",
      "[Counter]" => "isa_counter", "[Lockbox Number]" => "@facility.lockbox_number.to_s" }

    @gs_config = {"[Current Date(CCYYMMDD)]" => "Time.now.strftime('%Y%m%d')", "[Payer ID]" => "payer_id.to_s",
      "[Client TIN]" => "@facility.facility_tin.to_s.strip",  "[Facility Name]" => "@facility.name.to_s",
      "[Facility Abbreviation]" => "@facility.abbr_name.to_s.strip",  "[CPID From 837]" => "cpid.to_s",
      "[Batch Date]" => "@batch.date.strftime('%Y%m%d')",  "[Current Date(YYMMDD)]" => "Time.now().strftime('%y%m%d')",
      "[Counter]" => "isa_counter"  }

    @st_config = { "[Sequence Number(9 characters)]" => "@check_sequence.justify(9, '0')",
      "[Sequence Number]" => "@check_sequence.justify(4, '0')", "[Batch ID + Sequence]" => "@batch.batchid.justify(6) + @batch_based_index.to_s.justify(3, '0')" }

    @bpr_config = { "[ID Number Qualifier]" => "(get_micr_condition ? id_number_qualifier : '')",
      "[ABA Routing Number]" => "(get_micr_condition ? routing_number : '')",  "[Account Number Qualifier]" => "(get_micr_condition ? account_num_indicator : '')",
      "[DDA Number]" => "(get_micr_condition ? account_number : ' ')", "[Client Specific Payer ID]" => "client_specific_payerid.to_s.justify(10, '0')",
      "[HLSC Payer ID]" => "hlsc_payerid", "[Client DDA Number]" => "@facility.client_dda_number.to_s",
      "[Deposit Date]" => "@batch.date.strftime('%Y%m%d')",  "[Check Date]" => "(@is_correspndence_check  ? '' : @check.check_date.strftime('%Y%m%d'))",
      "[Batch Date]" => "@batch.date.strftime('%Y%m%d')", "[0 + HLSC Payer ID]" => "hlsc_payerid.justify(10, '0')"  }

    @trn_config = {  "[Check Number]" => "@check.check_number",  "[Batch ID]" => "@batch.batchid", "[Batch Date]" => "@batch.date.strftime('%Y%m%d')",
      "[Check Num + Batch Date + Batch Time + Filename]" => "[@check.check_number, @batch.date.strftime('%Y%m%d'), @batch.arrival_time.strftime('%H%M'),
        @batch.file_name].join('-')",  "[Client Specific Payer ID]" => "client_specific_payerid.to_s.justify(10, '0')",
      "[1 + Payer TIN]" => "@payer_tin",  "[HLSC Payer ID]" => "hlsc_payerid",  "[Lockbox Number]_[Batch ID]" => "@facility.lockbox_number.to_s + '_' +@batch.batchid.to_s",
      "[0 + HLSC Payer ID]" => "hlsc_payerid.justify(10, '0')" }

    @dtm405_config = {"[Processing Date]" => "Time.now().strftime('%Y%m%d')", "[Deposit Date]" => "@batch.date.strftime('%Y%m%d')"}

    @n1pr_config = {"[Payer Name]" =>  "@payer.name.blank? ? 'UNKNOWN PAYER' : @payer.name.strip.upcase[0..28]",
      "[Payer Name(No Space)]" => "@payer.name.blank? ? 'UNKNOWNPAYER' : @payer.name.strip.upcase.delete(" ")[0..28]",
      "[Custom Logic Payer Identification]" => "@is_correspndence_check ? 'NONE' : @payer.name.to_s[0..28]",
      "[Mapped Payer Name]" => "@payer.name.to_s[0..28]",  "[HLSC Payer ID]" => "hlsc_payerid",  "[Transaction ID]" => "@check.job.transaction_number",
      "[Identification Code]" => "@eob_type == 'Patient' ? 'PT' : 'IN'"  }

    @n3pr_config = {"[Payer Address]" => "output_payer('address_one')"}

    @n4pr_config = { "[Payer City]" => "output_payer('city')",  "[Payer State]" => "output_payer('state')",
      "[Payer ZipCode]" => "output_payer('zip_code')"  }

    @per_config = {"[Blank]" => "''"}

    @ref_2u_config = { "[HLSC Payer ID]" => "hlsc_payerid", "[3-Tif]" => "check_image.length >= 7 ? check_image[-7..-1] : check_image"}

    @n1pe_config = {"[Provider TIN]" => "@provider_tin", "[Lockbox Number]" => "@facility.lockbox_number",  "[FI or XX]" => "@st03",
      "[Custom Logic]" => "payee_identification_code","[Provider NPI or TIN]" => "@provider_npi.blank? ? @provider_tin : @provider_npi",
      "[Provider Name]" =>  "@payee.name.to_s.strip.upcase" }

    @n3pe_config = {"[Provider Address]" => "@payee.address_one.to_s.strip.upcase"}

    @n4pe_config = { "[Provider City]" => "@payee.city.to_s.strip.upcase",  "[Provider State]" => "@payee.state.to_s.strip.upcase",
      "[Provider ZipCode]" => "@payee.zip_code.to_s.strip.upcase" }

    @reftj_config = { "[Legacy Provider Number]" => "@provider_tin", "[Provider TIN]" => "@provider_tin",  "[Health Plan ID]" => "",
      "[Medicaid Provider Number]" => ""  }

    @refpq_config = {"[Provider TIN]" => "@provider_tin", "[Legacy Provider Number]" => "@provider_tin",  "[Trace Number]" => "@eobs.first.trace_number(@facility, @batch).to_s"}

    @ts3_config = { "[0 + Lockbox Number]" => "@facility.lockbox_number.justify(7, '0')",  "[Provider Number]" => "(@provider_tin.blank? ? @facility.facility_tin : @provider_tin)",
      "[Facility Type Code]" => "@eobs.first.claim_information ? @eobs.first.claim_information.facility_type_code.to_s : ''",
      "[Total Payment]" => "total_payment_amount.to_s.to_dollar" }

    @clp_config = { "[Facility Type Code]" => "eob_facility_type_code.blank? ? '13' : eob_facility_type_code","[Claim Frequency Indicator]" => "claim_freq_indicator.blank? ? '1' : claim_freq_indicator",
      "[Plan Type]" => "plan_type",   "[DRG Code]" => "@eob.drg_code.to_s",  "[Claim Status Code]" => "@eob.output_claim_type_weight(@client, @facility, @facility_config).to_s",
      "[Claim Number]" => "@eob.claim_number.to_s" }

    @cas_config = {'[Blank]' => ''}

    @nm1qc_config = { "[HN]" => "@quali.blank? ? '' : 'HN'", "[MI]" => "@quali.blank? ? '' : 'MI'",   "[Patient Suffix]" => "@eob.patient_suffix",
      "[Patient Last Name]" => "@eob.patient_last_name.to_s.strip.upcase", "[Patient First Name]" => "@eob.patient_first_name.to_s.strip.upcase",
      "[Patient ID]" => "@id.to_s",  "[Patient Account Number]" => "@eob.patient_account_number",   "[Member ID]" => "@id.to_s",  "[HN or 34]" => "@eob.identification_code_qual.to_s" }
    @nm1il_config = { "[Member ID]" => "@id.to_s"}

    @nm182_config = { "[Provider NPI]" => "@provider_npi","[Provider TIN]" => "@provider_tin",  "[Lockbox Number + Trace Number]" => "@facility.lockbox_number.to_s + '-' + @eob.trace_number(@facility, @batch).to_s",
      "[Payer Name]" => "@payer ? @payer.name.to_s.strip.upcase : ''",  "[Provider Suffix]" =>  "@eob.rendering_provider_suffix",
      "[Patient Last Name]" => "@eob.patient_last_name.to_s.strip.upcase",   "[Provider Last Name]" => "prov_last_name_or_org",
      "[Patient First Name]" => "@eob.patient_first_name.to_s.strip.upcase", "[Provider First Name]" => "@eob.rendering_provider_first_name.to_s.upcase",
      "[Patient Middle Initial]" => "@eob.patient_middle_initial.to_s.strip", "[Provider Middle Initial]" => "@eob.rendering_provider_middle_initial",
      "[Facility Name]" => "@facility.name.to_s.strip.upcase", "[Patient Suffix]" => "@eob.patient_suffix" }

    @refig_config = {"[Insurance Policy Number]" => "@eob.insurance_policy_number.to_s"}

    @dtm232_config = { "[Service From Date]" => "@service_date"}

    @amti_config = { "[Monetary Amount(Interest)]" => "@eob.amount('claim_interest').to_s.to_dollar", "[Debit/Credit Indicator]" => "@eob.amount('claim_interest')  > 0 ? 'C' : 'D'"}

    @svc_config = { "[True]" => "@service.service_quantity", "[Revenue Code]" => "@service.revenue_code.to_s.strip" }

    @dtm472_config = { "[Service Date]" => "@from_date"}

    @dtm150_config = { "[Service Date]" => "@from_date"}
    @dtm151_config = {  "[Service To Date]" => "@to_date"}

    @ref6r_config = { "[Reference Number]" => "@service.service_provider_control_number",  "[Retention Fee]" => "@service.amount('retention_fees').to_s.to_dollar" }

    @amtb6_config = { "[Supplemental Amount]" => "supplemental_amount.to_s.to_dollar", "[Interest Amount]" => "@eob.amount('claim_interest').to_s.to_dollar",
      "[Network Discount Amount]" => "'B6:' + @service.amount('service_discount').to_s.to_dollar", "[Allowed Amount]" => "client_specific_allowed_amount.to_s.to_dollar" }

    @se_config = { "[Sequence Number]" => "(@index + 1).to_s.justify(4, '0')",  "[Sequence Number(9 characters)]" => "(@index + 1).to_s.justify(9, '0')",
      "[Batch ID + Sequence]" => "@batch.batchid.justify(6) + @batch_based_index.to_s.justify(3, '0')" }
    @iea_config = {"[Counter]" => "@counter", "[Lockbox Number]" => "@facility.lockbox_number.to_s",   "[Lockbox Number Left Padded With 0]" => "@facility.lockbox_number.to_s.justify(9, '0')",
      "[Batch ID Left Padded With 9 Zeroes]" => "@batch.batchid.to_s.justify(9, '0')" }

    @plb_config = {"[Provider TIN]" => "@provider_tin", "[Provider NPI]" => "@provider_npi",  "[Patient Account Number]" => "@eob.patient_account_number",
      "[Check Number]" => "@check.check_number"  }
  end
  
  def claim_end_date
    if @config_835['dtm233_segment'] && @config_835['dtm233_segment']['2'] ==  '[Service To Date(mandatory)]'
      @eob.claim_to_date.blank? ? nil : {0 => 'DTM', 1 => '233'}
    else
      (@eob.claim_to_date.blank? || (@eob.claim_to_date.eql?@eob.claim_from_date)) ? nil : {0 => 'DTM', 1 => '233'}
    end
  end

  def new_batch?
    batch_id = @check.job.batch_id.to_s
    if batch_id != @prev_batchid
      @prev_batchid = batch_id
      true
    else
      false
    end
  end

  def total_submitted_charges
    @eobs.sum("total_submitted_charge_for_claim")
  end

  def total_payment_amount
    @eobs.sum('total_amount_paid_for_claim')
  end

  def facility_type_code
    @eobs.first.facility_type_code || '13'
  rescue
    '13'
  end

  def eob_facility_type_code
    if @claim && !@claim.facility_type_code.blank?
      @claim.facility_type_code
    end
  end

  def get_micr_condition
    @facility.details[:micr_line_info]
  end

  def payment_indicator
    @is_correspndence_check ? 'NON' : 'CHK'
  end

  def id_number_qualifier
    @is_correspndence_check ? '' : '01'
  end

  def correspondence_check?
    if facility.sitecode.to_s.strip == '00549' #NYU specific logic
      @check.check_amount.zero?
    else
      @check.correspondence?
    end
  end

  def routing_number
    (@micr && !@is_correspndence_check) ? @micr.aba_routing_number.to_s.strip : ''
  end

  def account_num_indicator
    @is_correspndence_check ? '' : 'DA'
  end

  def account_number
    @is_correspndence_check ? '' : (@micr.payer_account_number.to_s.strip if @micr)
  end

  def effective_payment_date
    if @is_correspndence_check
      date_config = facility_output_config.details[:bpr_16_correspondence]
    else
      date_config = facility_output_config.details[:bpr_16]
    end
    if date_config == "Batch Date"
      check.job.batch.date.strftime("%Y%m%d")
    elsif date_config == "835 Creation Date"
      Time.now.strftime("%Y%m%d")
    elsif date_config == "Check Date"
      check.check_date.strftime("%Y%m%d")
    end
  end

  def get_facility
    claim_eob = (@eobs.detect {|eob| !eob.claim_information.blank?})
    claim = claim_eob.claim_information if claim_eob
    claim || @facility
  end

  def least_service_date
    least_date = @services.collect{|service| service.date_of_service_from}.sort.first
    least_date.strftime("%Y%m%d") if !least_date.blank?
  end

  def claim_level_eob?
    @eob.category.upcase == "CLAIM"
  end

  def plan_type
    @eob.plan_type
  end

  def claim_freq_indicator
    if @claim && !@claim.claim_frequency_type_code.blank?
      @claim.claim_frequency_type_code
    end
  end

  def prov_last_name_or_org
    if not @eob.rendering_provider_last_name.to_s.strip.blank?
      @eob.rendering_provider_last_name.upcase
    elsif not @eob.provider_organisation.blank?
      @eob.provider_organisation.to_s.upcase
    else
      @facility.name.upcase
    end
  end

  def standard_industry_code_segments entity
    Output835.standard_industry_code_segments(entity, @client, @facility, @payer, '*')
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
    if $IS_PARTNER_BAC
      clp[5] = @clp_05_amount.to_s.to_dollar.to_blank
    else
      clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? "%.2f" %@clp_05_amount : "")
    end
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end

  def get_payer
    payer = @payer
    if @eob_type == 'Patient'
      eob = @eobs.first
      if eob
        default_patient_payer = Patient.new(:last_name => 'PAYMENT', :first_name => 'PATIENT', :address_one => 'NOT PROVIDED',
          :city => 'DEFAULT CITY', :state => 'XX', :zip_code => '12345')
        payer = eob.patients.first
        payer = default_patient_payer if @config_835[:default_patient_name]
      end
    end
    payer || @payer
  end

  def composite_med_proc_id
    qualifier = @facility.sitecode =~ /^0*00S66$/ ? 'AD' : 'HC'
    elem = []
    proc_code = (@service.service_procedure_code.blank? ? 'ZZ' + @delimiter.to_s +
        'E01' : qualifier + @delimiter.to_s + @service.service_procedure_code)
    proc_code = 'ZZ' + @delimiter.to_s + 'E01' if @service.service_procedure_code.to_s == 'ZZE01'
    modifier_condition = (@config_835['svc_segment'] && (@config_835['svc_segment']['1'].to_s == '[CPT Code + Modifiers]'))
    elem = modifier_condition ? [proc_code, @service.service_modifier1 , @service.service_modifier2 ,
      @service.service_modifier3 , @service.service_modifier4] : [proc_code]
    elem = trim_segment(elem)
    elem.join(@delimiter)
  end

  def amtb6_elements
    retention_fee = @service.amount('retention_fees')
    if @client.group_code.to_s == 'ADC' && @payer && @payer.name.to_s.upcase.include?('TUFTS') && !retention_fee.zero?
      {0 => 'AMT', 1 => 'B6', 3 => 'KH', 4 => retention_fee.to_s.dollar }
    else
      {0 => 'AMT', 1 => 'B6'}
    end
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("case when balance_record_type is null then image_page_no else end_time end , end_time asc")
  end

  def get_ordered_patient_payment_eobs(object)
    object.patient_pay_eobs.order(:image_page_no, :end_time)
  end

  def supplemental_amount
    amount = nil
    if @check.eob_type == 'Patient'
      unless @service.service_paid_amount.blank? || @service.service_paid_amount.to_f.zero?
        amount = @service.amount('service_paid_amount')
      end
    else
      unless @service.service_allowable.blank? || @service.service_allowable.to_f.zero?
        amount = @service.amount('service_allowable')
      end
    end
    amount
  end

  def payer_id
    payid = @facility_config.details[:isa_06]
    (payid == 'Predefined Payer ID' ? @facility_config.predefined_payer.to_s :  payid.to_s)
  end

  def isa_counter
    isa_record = IsaIdentifier.first
    (isa_record ? isa_record.isa_number.to_s.justify(9, '0') : nil)
  end

  def client_specific_payerid
    facility_group_code = @client.group_code.to_s.strip
    case facility_group_code
    when 'ADC','MDR','LLU'
      payid =  @payer && @payerid ? ((@is_correspndence_check && @payer.status.upcase != 'MAPPED') ? 'U9999': @payerid ) : nil
      payid = payid.justify(10, '0')
    when 'BYH'
      payid = @payer && @payerid ? (@is_correspndence_check  ? "1999999999" :(@payer.status.upcase == 'MAPPED' ? @payerid : "00000U9999")): nil
    when 'CNS'
      payid =  @payer && @payerid ? (@is_correspndence_check  ? "1999999999" : @payerid.to_s.justify(10, '0')): nil
    when 'KOD'
      payid = @payer && @payerid ? (@payer.status.upcase == 'MAPPED' ? @payerid : "00000U9999" ): nil
    end
    return payid
  end

  def hlsc_payerid
    (@payer && @payerid ? (@payerid.to_s.strip[0] == 'U' ? 'U9999' : @payerid) : 'U9999')
  end

  def eob_type
    @payer.payid(@micr) == @facility.patient_payerid ? 'Patient' : 'Insurance'
  end

  def output_payer attribute
    begin
      if !@default_payer_address.blank?
        default_attribute = @default_payer_address[attribute.to_sym]
      end
      obtained_attribute = default_attribute || @payer.send(attribute)
      obtained_attribute.to_s.strip.upcase
    rescue
      ''
    end
  end

  def find_payee
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? ||
            payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility
      end
    end
    payee
  end

  def output_claim_type_weight
    "claim"
    #    required_claim_types = @facility_config.required_claim_types.to_s.strip.split(',')
    #    actual_claim_type_weight = claim_status_code
    #    if required_claim_types.blank?
    #      actual_claim_type_weight
    #    else
    #      (required_claim_types.include?actual_claim_type_weight.to_s) ? actual_claim_type_weight : 1
    #    end
  end

  def claim_status_code
    sitecode = @facility.sitecode.to_s.upcase
    services = @services
    sitecodes_for_custiomized_claim_type = ['00895', '00985', '00986',
      '00987', '00988', '00989', '00K22', '00K23', '00K39', '00S40']
    if sitecodes_for_custiomized_claim_type.include?(sitecode)
      claim_status_code = get_customized_claim_type(sitecode)
    else
      if services.blank?
        entity = @eob
      else
        entity = services[0].find_service_line_having_reason_codes(services)
      end
      if entity
        crosswalked_codes = find_reason_code_crosswalk_of_last_adjustment_reason(client, facility, payer)

        claim_status_code = compute_claim_status_code(facility, crosswalked_codes)
      else
        claim_status_code = '1'
      end
    end
    claim_status_code
  end

  def get_customized_claim_type(sitecode)
    copay = @eob.total_co_pay.to_f
    co_insurance = @eob.total_co_insurance.to_f
    deductable = @eob.total_deductible.to_f
    payment = @eob.total_amount_paid_for_claim.to_f
    patient_responsibility = copay + co_insurance + deductable
    if @claim
      claim_type_from_837 = @claim.claim_type.to_s
    end
    if (sitecode == '00S40') && patient_responsibility.zero? && payment.zero?
      '4'
    elsif claim_type_from_837 == 'T' && sitecode == '00895'
      '3'
    elsif !@total_primary_payer_amount.to_f.zero?
      '2'
    else
      '1'
    end
  end

  def client_specific_allowed_amount
    group_code = @client.group_code.to_s.strip
    co_insurance = @service.amount('service_co_insurance')
    paid = @service.amount('service_paid_amount')
    charge = @service.amount('service_procedure_charge_amount')
    allowed = @service.amount('service_allowable')
    denied = @service.amount('denied')
    non_covered =  @service.amount('service_no_covered')
    deductable = @service.amount('service_deductible')
    copay = @service.amount('service_co_pay')
    ppp = @service.amount('primary_payment')
    contractual = @service.amount('contractual_amount')
    case group_code
    when 'ADC'
      allowed.zero? ? ((co_insurance + paid) == charge ? charge : allowed) : allowed
    when 'ATI', 'USC'
      amount = co_insurance + deductable + paid
      (!ppp.zero? && !charge.zero?) ? charge : (amount.zero? ? '' : amount)
    when 'CCS'
      amount = charge - denied - non_covered
      allowed.zero? ? (amount <= 0 ? '' : amount  ) : allowed
    when 'CHCS'
      amount = paid + deductable + co_insurance + copay
      amount.zero? ? '' : amount
    when 'ESI'
      allowed.zero? ? (paid.zero? ? '' : paid): allowed
    when 'MAXH'
      amount = paid + deductable + co_insurance
      allowed.zero? ? (amount.zero? ? '' : amount) : allowed
    when 'MCP', 'MDQ'
      amount = paid + deductable + co_insurance
      amount.zero? ? '' : amount
    when 'NYU'
      amount = paid + deductable + co_insurance + contractual
      allowed.zero? ? (amount.zero? ? '' : amount) : allowed
    else
      allowed
    end
  end

  def trace_number
    unless @batch.index_batch_number.blank?
      site_number = @facility.sitecode.to_s[-3..-1]
      date = @batch.date
      eob_serial_number = serial_number.to_i.to_s(36).rjust(3, '0')
      date =  date.year.to_s[-1..-1] + date.month.to_s(36) +  date.day.to_s(36)
      batch_sequence_number = @batch.index_batch_number.to_i.to_s(36).rjust(2, '0')
      (site_number + date + batch_sequence_number + "0" + eob_serial_number + "0").to_s.upcase
    else
      raise "Index Batch Number missing; cannot compute Trace Number"
    end
  end

  def serial_number
    joins = "inner join check_informations c on c.id = insurance_payment_eobs.check_information_id \
              inner join jobs j on j.id = c.job_id \
              inner join batches b on b.id = j.batch_id \
              inner join facilities f on f.id = b.facility_id"
    ids_of_eobs_with_same_batch_date_and_facility = InsurancePaymentEob.find(:all,
      :joins => joins,
      :select => "insurance_payment_eobs.id",
      :conditions => ["b.date = ? and f.id = ?", batch_date, facility_id])
    ids_of_eobs_with_same_batch_date_and_facility.index(self) + 1
  end

  def service_payee_identification
    code, qual = nil, nil
    claim = @eob.claim_information
    if (claim && !claim.payee_npi.blank?)
      code = claim.payee_npi
      qual = 'XX'
    elsif (claim && !claim.payee_tin.blank?)
      code = claim.payee_tin
      qual = 'FI'
    elsif !@facility.facility_npi.blank?
      code = @facility.facility_npi
      qual = 'XX'
    elsif !@facility.facility_tin.blank?
      code = @facility.facility_tin
      qual = 'FI'
    end

    return code, qual
  end

  def format_amount(amount)
    amount = amount.to_f
    (amount == amount.truncate) ? amount.truncate : amount
  end

  
end