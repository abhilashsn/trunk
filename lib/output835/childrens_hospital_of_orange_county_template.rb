class Output835::ChildrensHospitalOfOrangeCountyTemplate < Output835::Template

  def interchange_control_header
    sort_checks_on_new_jobs
      ['ISA', '00', (' ' * 10), '00', (' ' * 10), 'ZZ', 'BNY'.justify(15),
      'ZZ', @facility.facilities_npi_and_tins.first.tin.justify(15), Time.now().strftime("%y%m%d"), Time.now().strftime("%H%M"),
      ((!@output_version || @output_version == '4010') ? 'U' : '^'),
      ((!@output_version || @output_version == '4010') ? '00401' : '00501'),
      (@isa_record.isa_number.to_s.justify(9, '0') if @isa_record), '0', 'P', ':'].join(@element_seperator)
  end

  def functional_group_header
    ['GS', 'HP', 'BNY', @facility.facilities_npi_and_tins.first.tin.slice(0,12), group_date, Time.now().strftime("%H%M"), '1', 'X',
      ((!@output_version || @output_version == '4010') ? '004010X091A1' : '005010X221A1')].join(@element_seperator)
  end

  def generate_check
    Output835.log.info "\n\nCheck number : #{@check.check_number} undergoing processing"
    transaction_segments =[ transaction_set_header, financial_info, reassociation_trace,]

    transaction_segments << ref_ev_loop
    transaction_segments += [date_time_reference, payer_identification_loop,
      payee_identification_loop, reference_identification]
    transaction_segments << claim_loop if !@check.interest_only_check
    transaction_segments << provider_adjustment


    transaction_segments = transaction_segments.flatten.compact
    @se01[0] =  transaction_segments.length + 1 if @se01
    transaction_segments << transaction_set_trailer(transaction_segments.length + 1)
    transaction_segments
  end


  def financial_info(facility = nil,check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
    @check =  @check.nil? ? check : @check
    @facility = @facility.nil? ? facility : @facility
    @micr = @micr.nil? ? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil? ? correspondence_check : @is_correspndence_check
    @facility_output_config = @facility_output_config.nil? ? facility_config : @facility_output_config
    @check_amount = @check_amount.nil? ? check_amount : @check_amount
    bpr_05 =  payment_indicator == "ACH" ? 'CCP': ''
    bpr_elements = [ 'BPR', bpr_01, @check_amount.to_s, 'C', payment_indicator,bpr_05, '01',
      routing_number, 'DA', account_number, '', '', '', '', '', '', check_or_batch_date]
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

   def reference_identification(check = nil, facility = nil)
    @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
    batchid_list = @batch.batchid.split('_') unless @batch.batchid.blank?
    deposit_date = Date.strptime batchid_list[1], "%y%m%d" unless batchid_list.blank?
    deposit_date = (deposit_date.blank? ? '' : deposit_date.strftime("%m%d%Y"))
    bank_batch_number = (batchid_list[2].blank? ? '' : batchid_list[2].gsub(/^[0]*/,""))
    ['REF', 'ZZ', @batch.lockbox.to_s + ' ' + bank_batch_number.to_s+ ' ' + @check.transaction_id.to_s + ' ' + deposit_date.to_s].join(@element_seperator)
  end

   def transaction_set_line_number(index)
    ['LX', index.to_s.rjust(5, '0')].join(@element_seperator)
  end

   def patient_name
    member_id, qualifier = nil,nil
    member_id = @eob.subscriber_identification_code
    qualifier = 'MI' unless member_id.blank?
    patient_name_details = [ 'NM1', 'QC', '1', captured_or_blank_patient_last_name(@eob.patient_last_name),
      captured_or_blank_patient_first_name(@eob.patient_first_name), @eob.patient_middle_initial.to_s.strip,
      '', @eob.patient_suffix, qualifier, member_id].trim_segment
    return nil if patient_name_details == [ 'NM1', 'QC', '1']
    patient_name_details.join(@element_seperator)
  end
  

   def ref_ev_loop
     batchid_list = @batch.batchid.split('_') unless @batch.batchid.blank?
     deposit_date = Date.strptime batchid_list[1], "%y%m%d" unless batchid_list.blank?
     deposit_date = (deposit_date.blank? ? '' : deposit_date.strftime("%Y%m%d"))
     bank_batch_number = (batchid_list[2].blank? ? '' : batchid_list[2].gsub(/^[0]*/,""))
     ref_ev_img_name = @batch.lockbox.to_s + deposit_date.to_s+ bank_batch_number.to_s+ @check.transaction_id.to_s
     img_ext = @check.job.initial_image_name.split(".").last
     [ 'REF', 'EV', ref_ev_img_name+"."+img_ext].join(@element_seperator)
   end

   def reassociation_trace
    trn_elements = ['TRN', '1', output_check_number]
    if @payer.payid.present?
       trn_elements <<  '10000'+ @payer.payid.to_s.rjust(5, '0')
#    else
#       trn_elements << '1000000009'
    end
     trn_elements.trim_segment.join(@element_seperator)
  end

  def get_payer_tin
    if @payer.payer_tin.present?
        ('1' + @payer.payer_tin)
    elsif @job.payer_tin
      ('1' + @job.payer_tin)
    else
      '1         '
    end
  end

 def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
    claim_segments = [claim_payment_loop, include_claim_dates]  #,'' ,repricer_info]
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
   # claim_segments << claim_level_allowed_amount
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments << service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

  def claim_payment_information
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_type_weight,
      @eob.amount('total_submitted_charge_for_claim'), @eob.payment_amount_for_output(@facility, @facility_output_config),
      @eob.patient_responsibility_amount, plan_type, claim_number, eob_facility_type_code, claim_freq_indicator].trim_segment.join(@element_seperator)
  end


  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
    unless @clp_pr_amount.blank?
      @clp_05_amount += @clp_pr_amount
    end
    clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? @clp_05_amount.to_f.to_amount_for_clp : "")
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end

   def service_payment_information(eob = nil,service = nil,check = nil,is_claim_eob = nil,payer = nil)
    @service =  @service.nil? ? service : @service
    ['SVC', composite_med_proc_id, @service.amount('service_procedure_charge_amount'), @service.amount('service_paid_amount'),
      '', @service.service_quantity.to_f.to_amount].trim_segment.join(@element_seperator )
  end

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

  def composite_med_proc_id
    if proc_cpt_code.present?
     if captured_or_blank_proc_cpt_code.blank?
       if revenue_code.present?
      ["NU:#{revenue_code}"]
       else
         ['']
       end
     else
       ["HC:#{proc_cpt_code}"]
     end
    elsif revenue_code.present?
      ["NU:#{revenue_code}"]
    else
      ['']
    end
  end

  def insured_name
   
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
    end
    elements.join(@element_seperator)
  end


    def service_prov_name(eob = nil,claim = nil )
    @eob =  @eob.nil?? eob : @eob
    prov_id, qualifier = service_prov_identification
    ['NM1', '82', (@eob.rendering_provider_last_name.to_s.strip.blank? ? '2': '1'),
      prov_last_name_or_org, @eob.rendering_provider_first_name,
      @eob.rendering_provider_middle_initial, '', '',
      qualifier, prov_id].trim_segment.join(@element_seperator)
  end


     def service_date_reference
    svc_date_segments = []
    from_date = @service.date_of_service_from.strftime("%Y%m%d") unless @service.date_of_service_from.blank?
    to_date = @service.date_of_service_to.strftime("%Y%m%d") unless @service.date_of_service_to.blank?
    from_eqls_to_date = (from_date == to_date)
     if from_date && (!to_date || from_eqls_to_date )
       svc_date_segments = dtm_472(from_date) if can_print_service_date(from_date)
    else
      svc_date_segments << dtm_150(from_date) if (!from_date.blank?  &&   from_date != "20000112")
      svc_date_segments << dtm_151(to_date)  if (!to_date.blank?  &&  from_date != "20000112")
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end


  def repricer_info
   if @eob.alternate_payer_name.present?
    alternate_payer_name = @eob.alternate_payer_name
    alternate_payer_name_hash.each do |key,value|
      if alternate_payer_name == key
        alternate_payer_name = value
      end
    end
    
    ['REF', 'ZZ', alternate_payer_name.try(:strip)].join(@element_seperator)
    end
    end
  
   def alternate_payer_name_hash
    alternate_payer_name_hash = {'--' => '',
      'Beech Street' => 'BEECH STREET',
      'Beech Street Directly Contracted Payers' => 'BEECH STREET DCP',
      'Beech Street Intergroup' => 'BEECH STREET PPO',
      'Beech Street Multiplan' => 'BEECH STREET MULTIPLAN',
      'Beech Street PPO' => 'BEECH STREET PPO',
      'Crawford' => 'CRAWFORD',
      'Crawford Health Plan' => 'CRAWFORD',
      'Devon' => 'DEVON',
      'Devon Health' => 'DEVON',
      'Flora' => 'FLORA',
      'Flora Health Network' => 'FLORA',
      'Great West' => 'GREAT WEST',
      'Health Coalition Partners'=> 'HCP',
      'Health Coalition Partners Directly Contracted Payers' =>  'HCP DCP',
      'Health Coalition Partners Intergroup' => 'HCP PPO',
      'Health Coalition Partners PPO' => 'HCP PPO',
      'HPOUV'=> 'HPOUV',
      'Health Plan of Upper Ohio Valley' => 'HPOUV',
      'Humana Choice'=> 'HUMANA',
      'Intergroup Directly contracted Payers' => 'INTERGROUP DCP',
      'Intergroup PPO' => 'INTERGROUP PPO',
      'Intergroup' => 'INTERGROUP',
      'Kaiser' => 'KAISER',
      'Kaiser Permanente' => 'KAISER',
      'Multiplan' => 'MULTIPLAN',
      'National Provider Network' => 'NPN',
      'One Health Plan/Great West' => 'ONE HEALTH',
      'Penn Highlands Health Plan'  => 'PHHP',
      'Preferred Health Care System' => 'PREFERRED HCS',
      'Prime Net' => 'PRIME NET',
      'Private Health Care System' => 'PRIVATE HCS',
      'MISC' => 'MISC'
      }
  end

  def set_transaction_reference_number
     corres_check_count = 0
     @checks.each {|check| corres_check_count += 1 if check.correspondence?}
     @transaction_ref_number = Sequence.find('UPMC_REF_NUMBER').value - corres_check_count
   end

  def check_or_batch_date
    if @check.check_date
      @check.check_date.strftime("%Y%m%d")
    elsif @batch.date
      @batch.date.strftime("%Y%m%d")
    end
  end

  def ref_number
     @is_correspndence_check ? "-#{@transaction_ref_number += 1}" : output_check_number
   end

#  def payer_technical_contact(payer)
#  end

  def insured_name
  end

  def service_prov_identifier
  end

  def medical_record_number
  end

  def other_claim_related_id
  end

  #Will return empty string if patient name is captured as NONE in DC Grid
  def check_blank_patient_name(value)
    value.upcase.eql?('NONE') ? '' : value
  end

  #Sort checks based on the image names created while creating new jobs
  def sort_checks_on_new_jobs
    @total_jobs_hash = @total_jobs.index_by(&:id)
    @checks.sort_by! do |check|
      if check.job.split_parent_job_id.present? || check.job.parent_job_id.present?
        split_image_values =  check.job.initial_image_name.split('.').first.split('_').from(1)
        @compare_job = check.job
        split_image_values.length.times do |t|
          if check.job.split_parent_job_id.present?
            @compare_job = @total_jobs_hash[@compare_job.split_parent_job_id]
          elsif check.job.parent_job_id.present?
            @compare_job = @total_jobs_hash[@compare_job.parent_job_id]
          end
        end
        "#{@compare_job.id}.#{split_image_values.present? ? split_image_values.join() : '0'}".to_f
      else
        check.job_id.to_f
      end
    end
  end

end
