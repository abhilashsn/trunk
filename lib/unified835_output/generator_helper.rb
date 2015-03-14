module Unified835Output::GeneratorHelper

  def update_isa_identifier_count(last_count)
    IsaIdentifier.first.update_attributes(:isa_number => last_count + 1)
  end
    
  #TODO : Need a compulsory Refactor
 
  def is_4010_version?
    output_version = @output_config.details[:output_version]
    !output_version || output_version == '4010'
  end

  #TODO : Need a compulsory Refactor
  def get_payer
    if @check.eob_type == 'Patient'
      eob = @check.insurance_payment_eobs.first
      patient = eob.patients.first if eob
      if patient
        Output835.log.info "\n Getting patient details from patients table"
        full_address = "#{patient.address_one}#{patient.city}#{patient.state}#{patient.zip_code}"
        if full_address.blank?
          output_payer = Patient.new(:last_name => patient.last_name, :first_name => patient.first_name, :address_one => @payer.address_one,
            :city => @payer.city, :state => @payer.state, :zip_code => @payer.zip_code)
        else
          output_payer = patient
        end
      else
        Output835.log.info "\n Getting patient details from payers table as patient record does not exist"
        output_payer = @payer
      end
      default_patient_name = @output_config.details[:default_patient_name]
      unless default_patient_name.blank?
        output_payer.first_name, output_payer.last_name =  default_patient_name.strip.upcase.split
        output_payer.last_name ||= ""
      end
      output_payer
    else
      Output835.log.info "\n Getting payer details from payers table"
      @payer
    end
  end

  def get_facility
    claim = @eobs.map(&:claim_information).compact.first
    return @facility unless claim
    if [claim.name, claim.address_one, claim.city, claim.state, claim.zip_code].detect{|d| d.blank?}
      return @facility
    end
    claim
  end

  def get_payee_name
    payee_names_list = [@check.payee_name, @output_config.details[:payee_name], @payee.name]
    payee_names_list.each do |payee_name|
      return payee_name if payee_name.present?
    end
  end

  def has_default_lockbox_identification?
    if @facility.default_lockbox_faclities
      return @facility.facility_lockbox_mappings.map(&:lockbox_number).include?(@check.batch.lockbox)
    end
    return false
  end

  def get_payee_for_address_details
    if has_default_lockbox_identification?
      facility_lockbox
    else
      @facility.details[:default_payee_details] ? @facility : @payee
    end
  end

  def facility_lockbox
    @facility.facility_lockbox_mappings.where(:lockbox_number => @check.batch.lockbox).first
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("balance_record_type asc, image_page_no, end_time asc")
  end

  def captured_or_blank_value(segment, value)
    default_value = @facility.send(segment).to_s.upcase
    return value.to_s.strip if default_value.blank?
    value.strip.upcase == default_value ? blank_segment : value.to_s.strip
  end

  def zero_formatted_amount(amount)
    return amount unless amount.to_f.zero?
    '0'
  end

  def can_print_service_date(date)
    return false if date.blank?
    if @facility.date_of_service_default_match?
      return !(date == @facility.date_of_service_default_match.strftime("%Y%m%d"))
    end
    true
  end

  def get_formatted_content(segments)
    if @output_config.details[:wrap_835_lines]
      segments = segments.join(@facility_level_details[:segment_separator]) + '~'
      segments = segments.scan(/.{1,80}/).join(@facility_level_details[:look_ahead])
    elsif @output_config.details[:content_835_no_wrap]
      segments = segments.join(@facility_level_details[:segment_separator]) + '~'
    else
      segments = segments.join(@facility_level_details[:segment_separator] + @facility_level_details[:look_ahead]) + '~'
    end
    return segments
  end
  
  def bundled_cpt_code
    @service.bundled_procedure_code.blank? ? '' : @service.bundled_procedure_code
  end

  def proc_cpt_code
    @service.service_procedure_code.blank? ? '' : @service.service_procedure_code
  end

  def revenue_code
    revenue_code = @service.revenue_code.blank? ? '' : @service.revenue_code
    revenue_code.downcase == 'none' ? '' : revenue_code
  end

  def get_service_start_date
    return nil unless @service.date_of_service_from
    @service.date_of_service_from.strftime("%Y%m%d")
  end

  def get_service_end_date
    return nil unless @service.date_of_service_to
    @service.date_of_service_to.strftime("%Y%m%d")
  end

  def is_service_ends_in_one_day?
    get_service_start_date == get_service_end_date
  end

  def can_print_dtm_472_segment
    @service_level_details[:from_date] && 
    @service_level_details[:from_date] != '20000101' &&
    (
      @service_level_details [:to_date].blank? || 
      @service_level_details[:service_in_one_day] ||
      @client.group_code.to_s.strip == 'KOD'
    )
  end

  def service_provider_information
    provider_info_order = {
      :eob_npi => [@eob.try(:provider_npi), 'XX'],
      :eob_tin => [@eob.try(:provider_tin), 'FI'],
      :claim_npi => [@claim.try(:provider_npi), 'XX'],
      :claim_tin => [@claim.try(:provider_ein), 'FI'],
      :facility_npi => [@facility.facilities_npi_and_tins.first.try(:npi), 'XX'],
      :facility_tin => [@facility.facilities_npi_and_tins.first.try(:tin), 'FI']
    }
    provider_info_order.each_pair do |type, value|
      return value if value.first.present?
    end
  end

  def get_eob_image
    job_images = @check.job.images_for_jobs
    return job_images.first if job_images.length < 2
    return job_images.detect{|image| image.image_number == @eob.image_page_no}
  end

  def image_page_name
    image_name = @check.job.images_for_jobs.first.image_file_name
    job_start_page = @check.job.starting_page_number
    "#{image_name}#{job_start_page - 1 + @eob.image_page_no.to_i}_#{job_start_page - 1 + @eob.image_page_to_number.to_i}"
  end

  def update_patient_responsibility_amount(segments)
    clp_index = segments.index{|segment| segment.match(/^(.)*PATIENT_RESPONSIBILITY_AMOUNT(.)*$/)}
    total_patient_amount = @claim_level_details[:patient_amount] + @claim_level_details[:service_patient_amount_total]
    formatted_patient_amount = (total_patient_amount >= 0 ? "%.2f" %total_patient_amount : '')
    segments[clp_index].gsub!("PATIENT_RESPONSIBILITY_AMOUNT",formatted_patient_amount)
  end

	# Basic Methods Applicable to Multiple Segments
    def segment_name(name)
    	name.to_s.strip.upcase
    end

    def blank_segment(value=nil)
    	''
    end

    def nil_segment(value=nil)
    	nil
    end

    def print_constant(value)
      value.to_s.strip.upcase
    end

    def print_fixed_empty_space(length)
      length = length.to_i
      " " * length
    end

    def print_current_time(format=nil)
      time_format = format.nil? ? '%H%M' : format
      Time.now().strftime(time_format)
    end

    def print_todays_date(format=nil)
      date_format = format.nil? ? "%Y%m%d" : format
      Date.today.strftime(date_format)
    end
  # End of basic methods

  # Conditions to print a Segment
    def verify_ref_ev_condition
      if @output_config.details[:ref_ev_batchid]
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ref_f2_condition
      Unified835Output::BenignNull.new
    end

    def verify_ref_2u_condition
      Unified835Output::BenignNull.new
    end

    def verify_per_cx_condition
      Unified835Output::BenignNull.new
    end

    def verify_per_bl_condition
      if !is_4010_version?
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_per_ic_condition
      Unified835Output::BenignNull.new
    end

    def verify_ref_tj_condition
      tax_payer_id = if has_default_lockbox_identification?
        facility_lockbox.tin
      else
        @check.payee_tin
      end
    ((@check.payee_npi.present?) && (tax_payer_id.present?)) ? yield : Unified835Output::BenignNull.new
    end

    def verify_rdm_condition
      Unified835Output::BenignNull.new
    end

    def verify_claim_loop_condition
      if !@check.interest_only_check
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ts3_condition
      if @claim_level_details[:index].eql?(1)
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ts2_condition
      Unified835Output::BenignNull.new
    end

    def verify_nm1_il_condition
      if @eob.is_patient_differ_from_subscriber? && @payer_classified_check.is_insurance_check?
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ref_1l_condition
      if @eob.insurance_policy_number? 
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_nm1_pr_condition
      if @facility.details['re_pricer_info'] && @check.alternate_payer_name.present?
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ref_ea_condition
      medical_record_number ? yield : Unified835Output::BenignNull.new
    end

    def verify_ref_zz_condition
      original_image_name ? yield : Unified835Output::BenignNull.new
    end

    def verify_ref_bb_condition
      if @facility.client.client_name.eql?('QUADAX') && authorization_number
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ref_ig_condition
      insurance_policy_number.present? ? yield : Unified835Output::BenignNull.new
    end

    def verify_ref_f8_condition
      Unified835Output::BenignNull.new
    end

    def verify_dtm_232_condition
      claim_statement_period_start ? yield : Unified835Output::BenignNull.new
    end

    def verify_dtm_233_condition
      claim_statement_period_end ? yield : Unified835Output::BenignNull.new
    end

    def verify_dtm_036_condition
      Unified835Output::BenignNull.new
    end

    def verify_dtm_050_condition
      Unified835Output::BenignNull.new
    end

    def verify_per_cx2_condition
      Unified835Output::BenignNull.new
    end

    def verify_service_payment_loop_condition
      @classified_eob.is_claim_eob? ? Unified835Output::BenignNull.new : yield
    end

    def verify_amt_i_condition
      if !@facility.details[:interest_in_service_line] && interest_amount
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_svc_condition
      @service_level_details[:is_adjustment_line] ? Unified835Output::BenignNull.new : yield
    end

    def verify_dtm_472_condition
      if can_print_dtm_472_segment
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_dtm_150_condition
      if !can_print_dtm_472_segment && can_print_service_date(@service_level_details[:from_date])
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_dtm_151_condition
      if !can_print_dtm_472_segment && can_print_service_date(@service_level_details[:to_date])
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ref_lu_condition
      Unified835Output::BenignNull.new
    end

    def verify_ref_6r_condition
      if !@service.adjustment_line_is? && @facility.details[:reference_code] && line_item_control_number.present?
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_ref_hpi_condition
      Unified835Output::BenignNull.new
    end

    def verify_ref_0k_condition
      Unified835Output::BenignNull.new
    end

    def verify_amt_au_condition
      claim_payment_amount = @eob.payment_amount_for_output(@facility, @output_config).to_f
      claim_level_supplemental_amount = @eob.claim_level_supplemental_amount.to_f
      if @output_config.details[:claim_level_allowed_amt] && !claim_payment_amount.zero? && !claim_level_supplemental_amount.zero?
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_qty_ca_condition
      Unified835Output::BenignNull.new
    end

    def verify_amt_b6_condition
      if actual_allowed_amount.present? || @service.amount('service_paid_amount').present?
        yield
      else
        Unified835Output::BenignNull.new
      end
    end

    def verify_qty_zk_condition
      Unified835Output::BenignNull.new
    end

    def verify_lq_rx_condition
      if @facility.abbr_name.eql?('RUMC')
        yield
      else
        Unified835Output::BenignNull.new
      end
    end
  # End of Segment printing conditions

  # Configurable 835 Helper Methods
    def is_discount_more?(discount)
      @facility.name.upcase.eql?('AVITA HEALTH SYSTEMS') &&
        @eob.multiple_statement_applied.eql?(false) &&
          @check.check_amount < discount &&
            @payer.payer_type.eql?('PatPay')
    end

    def can_return_static_start_date(processed_date)
      @classified_eob.is_claim_eob? && 
      @facility.client.is_quadax_client? && 
      is_static_date?(processed_date)
    end

    def can_return_static_end_date(processed_date)
      @facility.client.is_quadax_client? && 
      is_static_date?(processed_date)
    end

    def is_static_date?(date)
      ['20000101', '99990909'].include?(date)
    end
  # End of Configurable 835 Helper Methods

 def output_payid(payer)
    if payer.id
      output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(payer.id, @client.id, @facility.id)
      output_payid_record.output_payid if output_payid_record
    end
  end

    def total_submitted_charges
    @eobs.inject(0){ |sum, eob| sum + eob.amount('total_submitted_charge_for_claim')}
  end
  # End of Segment printing conditions

  # Start of Functions which are common for some group of facilities
    def identification_code_qualifier_for_optim(*options)
      return 'FI' if @facility_payee && @facility_payee.payee_tin?
    Unified835Output::BenignNull.new
    end

   def identification_code_for_optim(*options)
    return @facility_payee.payee_tin.strip.upcase if @facility_payee && @facility_payee.payee_tin?
    Unified835Output::BenignNull.new
   end

   def payment_effective_date_for_basic_facility(*options)
     date_config =  @check_level_details[:is_correspondent] ? @output_config.details[:bpr_16_correspondence] : @output_config.details[:bpr_16]
    if date_config == "Batch Date" || (@check.payment_method == 'ACH' and @check.check_date.blank?)
      @check.batch.date.strftime("%Y%m%d")
    elsif date_config == "835 Creation Date"
      Time.now.strftime("%Y%m%d")
    elsif date_config == "Check Date"
      @check.check_date.strftime("%Y%m%d")
    end
   end

    #End of Functions which are common for some group of facilities
end