class Output835::UniversityOfPittsburghMedicalCenterTemplate < Output835::Template

  def interchange_control_header
    @original_facilities_list = UpmcFacility.all.index_by{|f| f.name.strip.upcase}
    @uniq_transaction_count = @client.custom_fields[:transaction_count] - @checks.size
    set_transaction_reference_number
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

  def transaction_set_header
    @original_facility = @original_facilities_list[@check.payee_name.strip.upcase]
    @uniq_transaction_count += 1
    ['ST', '835' ,@uniq_transaction_count.to_s.rjust(5, '0')].join(@element_seperator)
  end

  def financial_info(facility = nil,check = nil,facility_config = nil,check_amount = nil,micr = nil,correspondence_check = nil)
    @check =  @check.nil? ? check : @check
    @facility = @facility.nil? ? facility : @facility
    @micr = @micr.nil? ? micr : @micr
    @is_correspndence_check = @is_correspndence_check.nil? ? correspondence_check : @is_correspndence_check
    @facility_output_config = @facility_output_config.nil? ? facility_config : @facility_output_config
    @check_amount = @check_amount.nil? ? check_amount : @check_amount
    bpr_elements = [ 'BPR', 'I', @check_amount.to_s, 'C', 'CHK', '', '01',
      routing_number, '', account_number, '', '', '', '', '', '', check_or_batch_date]
    bpr_elements.flatten.trim_segment.join(@element_seperator)
  end

  def check_or_batch_date
    if @check.check_date
      @check.check_date.strftime("%Y%m%d")
    elsif @batch.date
      @batch.date.strftime("%Y%m%d")
    end
  end

  def reassociation_trace
    ['TRN', '1', ref_number, get_payer_tin].join(@element_seperator)
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

  def payee_identification_loop(repeat = 1)
    payee = get_facility
    if payee
      if ( payee.name.blank? || payee.address_one.blank? || payee.city.blank? || payee.state.blank? || payee.zip_code.blank?)
        @claim = payee.clone
        payee = @facility #if any of the billing provider address details is missing get facility address
      end
      payee_segments = []
      repeat.times do
        payee_segments << payee_identification(payee)
        payee_segments << address(@original_facility)
        payee_segments << payee_geographic_location(@original_facility)
      end
      payee_segments.compact
    end
  end

  def payee_identification(payee,check = nil,claim = nil,eobs = nil)
    @check =  @check.nil?? check : @check
    @claim = @claim.nil?? claim : @claim
    ['N1', 'PE', @check.payee_name, 'FI', @check.payee_tin].join(@element_seperator)
  end

  def payee_geographic_location(payee)
    ['N4', payee.city.try(&:strip).try(&:upcase), payee.state.try(&:strip).try(&:upcase),
      payee.zip.try(&:strip).try(&:upcase)].compact.join(@element_seperator)
  end

  def reference_identification(check = nil, facility = nil)
    @check =  @check.nil?? check : @check
    @facility = @facility.nil?? facility : @facility
    batchid_list = @batch.batchid.split('_') unless @batch.batchid.blank?
    deposit_date = Date.strptime batchid_list[1], "%y%m%d" unless batchid_list.blank?
    deposit_date = (deposit_date.blank? ? '' : deposit_date.strftime("%m%d%Y"))
    bank_batch_number = (batchid_list[2].blank? ? '' : batchid_list[2].gsub(/^[0]*/,""))
    ['REF', 'ZZ', @batch.lockbox + ' ' + bank_batch_number + ' ' + @check.transaction_id + ' ' + deposit_date].join(@element_seperator)
  end
  
  def transaction_set_line_number(index)
    ['LX', index.to_s.rjust(5, '0')].join(@element_seperator)
  end

  def plan_type
    ['AM', 'WC'].include?(@eob.plan_type) ? @eob.plan_type : ''
  end

  def generate_eobs
    Output835.log.info "\n\nPatient account number : #{@eob.patient_account_number}"
    Output835.log.info "This EOB has #{@services.length} service lines"
    Output835.log.info "This is a CLAIM LEVEL EOB" if  @is_claim_eob
    claim_segments = [claim_payment_loop, repricer_info]
    claim_segments << include_claim_dates if @is_claim_eob
    claim_segments << claim_supplemental_info  unless @facility.details[:interest_in_service_line]
    claim_segments << claim_level_allowed_amount
    claim_segments << standard_industry_code_segments(@eob, @is_claim_eob) if @is_claim_eob
    claim_segments << service_payment_info_loop unless @is_claim_eob
    update_clp! claim_segments
    claim_segments.flatten.compact
  end

  #Supplies information common to all services of a claim
  def claim_payment_information
    ['CLP', captured_or_blank_patient_account_number(@eob.patient_account_number), claim_type_weight,
      @eob.amount('total_submitted_charge_for_claim'), @eob.payment_amount_for_output(@facility, @facility_output_config),
      @eob.patient_responsibility_amount, plan_type, claim_number, eob_facility_type_code, claim_freq_indicator].trim_segment.join(@element_seperator)
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

  #Specifies pertinent From date of the claim
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


  #supplies payment and control information to a provider for a particular service
  def service_payment_information(eob = nil,service = nil,check = nil,is_claim_eob = nil,payer = nil)
    @service =  @service.nil? ? service : @service
    ['SVC', composite_med_proc_id, @service.amount('service_procedure_charge_amount'), @service.amount('service_paid_amount'),
      '', @service.service_quantity.to_f.to_amount].trim_segment.join(@element_seperator )
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

  def provider_adjustment
    #get all provider adjustments for that check
    provider_adjustments = @check.job.get_all_provider_adjustments
    interest_prov_adjs_with_blank_acc_no = provider_adjustments.select{|prov_adj| prov_adj.qualifier == 'L6' && prov_adj.patient_account_number.blank?}
    prov_adj_with_blank_acc_no = provider_adjustments.select{|prov_adj| prov_adj.qualifier != 'L6' && prov_adj.patient_account_number.blank?}
    prov_adj_without_blank_interests = provider_adjustments - interest_prov_adjs_with_blank_acc_no - prov_adj_with_blank_acc_no

    # Collect all eobs for which the interest amount is non zero
    interest_eobs = @eobs.delete_if{|eob| eob.claim_interest.to_f.zero?}
    interest_eobs_with_blank_acc_no = interest_eobs.select{|eob| eob.patient_account_number.blank?}
    interest_eobs_without_blank_acc_no = interest_eobs - interest_eobs_with_blank_acc_no

    prov_adj_and_eobs_with_blank_acc_no = interest_prov_adjs_with_blank_acc_no + interest_eobs_with_blank_acc_no

    interest_exists_and_should_be_printed = (@facility.details[:interest_in_service_line] == false && interest_eobs.present?)

    if (provider_adjustments.present? || interest_exists_and_should_be_printed)
      provider_adjustment_elements = []
      plb_separator = @facility_output_config.details["plb_separator"]

      prov_adj_without_blank_interests.each do |prov_adj|
        provider_adjustment_elements << ['PLB', @original_facility.tin, "#{Date.today.year()}0630", adj_qualifier_and_account_no(plb_separator, prov_adj),
          (format_amount(prov_adj.amount.to_f) * -1).to_s.to_dollar].trim_segment.join(@element_seperator)
      end

      prov_adj_with_blank_acc_no.group_by{|prov_adj| "#{prov_adj.qualifier}"}.each do |qual, prov_adj_group|
        provider_adjustment_elements << ['PLB', @original_facility.tin, "#{Date.today.year()}0630", qual,
          (format_amount(prov_adj_group.sum{|i| i.amount * -1}.to_f)).to_s.to_dollar].trim_segment.join(@element_seperator)
      end
      
      if (interest_exists_and_should_be_printed && @facility_output_config.details[:interest_amount] == "Interest in PLB")
        interest_eobs_without_blank_acc_no.each do |eob|
          provider_adjustment_elements << ['PLB', @original_facility.tin, "#{Date.today.year()}0630", adj_qualifier_and_account_no(plb_separator, eob),
            (eob.amount('claim_interest') * -1).to_s.to_dollar].trim_segment.join(@element_seperator)
        end

        if prov_adj_and_eobs_with_blank_acc_no.present?
          provider_adjustment_elements << ['PLB', @original_facility.tin, "#{Date.today.year()}0630", 'L6',
            interest_total_in_prov_adj_and_eobs(prov_adj_and_eobs_with_blank_acc_no)].trim_segment.join(@element_seperator)
        end
      elsif interest_prov_adjs_with_blank_acc_no.present?
        provider_adjustment_elements << ['PLB', @original_facility.tin, "#{Date.today.year()}0630", 'L6',
          (format_amount(interest_prov_adjs_with_blank_acc_no.sum{|i| i.amount * -1}.to_f)).to_s.to_dollar].trim_segment.join(@element_seperator)
      end

    end

    provider_adjustment_elements

  end

  def adj_qualifier_and_account_no(plb_separator, record)
    @facility_group_code ||= @client.group_code.strip
    if record.class.name == 'ProviderAdjustment'
      record.qualifier+plb_separator+captured_or_blank_patient_account_number(record.patient_account_number)
    else
      'L6'+plb_separator+captured_or_blank_patient_account_number(record.patient_account_number)
    end
  end

  def interest_total_in_prov_adj_and_eobs(prov_adj_and_eobs)
    total_interest = 0
    prov_adj_and_eobs.each do |i|
      if i.class.name == 'ProviderAdjustment'
        total_interest += i.amount.to_f 
      else
        total_interest += i.amount('claim_interest')
      end
    end
    total_interest = total_interest * -1
    total_interest.to_s.to_dollar
  end

  def transaction_set_trailer(segment_count)
    [ 'SE', segment_count, @uniq_transaction_count.to_s.rjust(5, '0')].join(@element_seperator)
  end

  def functional_group_trailer(batch_id = nil)
    ['GE', checks_in_functional_group(batch_id), '1'].join(@element_seperator)
  end

  def service_prov_name
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0].split('*')
    @clp_05_amount += @clp_pr_amount unless @clp_pr_amount.blank?
    clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? @clp_05_amount.to_f.to_amount_for_clp : "")
    clp = Output835.trim_segment(clp).join('*')
    claim_segments[0][0] = clp
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

  def ref_number
     @is_correspndence_check ? "-#{@transaction_ref_number += 1}" : output_check_number
  end

  def payer_technical_contact(payer)
  end

  def insured_name
  end

  def service_prov_identifier
  end

  def medical_record_number
  end

  def other_claim_related_id
  end

  #Supplies the full name of an individual or organizational entity
  def patient_name
    patient_name_details = [ 'NM1', 'QC', '1', captured_or_blank_patient_last_name(@eob.patient_last_name),
      captured_or_blank_patient_first_name(@eob.patient_first_name), @eob.patient_middle_initial.to_s.strip, '',
      @eob.patient_suffix, @eob.subscriber_identification_code.present? ? 'MI' : '',
      @eob.subscriber_identification_code].trim_segment
    return nil if patient_name_details == [ 'NM1', 'QC', '1']
    patient_name_details.join(@element_seperator)
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
