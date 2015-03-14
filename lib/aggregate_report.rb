require 'csv'
class AggregateReport
  require 'logger'
  attr_reader :batch, :client, :facility, :claim_level_eob_condition, :check, :eob, :payer,
    :svc, :report_layout, :eob_wise_layout_condition, :svc_wise_layout_condition, :index,
    :orbograph_correspondence_condition

  def initialize(current_user = nil)
    @current_user = (current_user || User.find(1))
  end

  def generate_aggregate_835_report(checks, report_layout)
    @report_layout = report_layout
    adjustment_reasons = ['coinsurance', 'contractual', 'copay', 'deductible', 'denied', 'discount',
      'miscellaneous_one', 'miscellaneous_two', 'noncovered', 'primary_payment', 'pr', 'prepaid']
    if checks.length > 0
      begin
        csv_string = CSV.generate do |csv|
          csv << report_header(checks.first.batch.client).join("\t").split(",")
          checks.each do |check|
            job = check.job
            @batch = check.batch
            @client = @batch.client
            @facility = @batch.facility
            @orbograph_correspondence_condition = job.orbograph_correspondence?(@client.name)
            unless check.insurance_payment_eobs.blank?
              @check = check
              @payer = check.payer
                       
              check.insurance_payment_eobs.each do |eob|
                @claim_level_eob_condition = (eob.category == "claim")
                @eob_wise_layout_condition = (report_layout == "eob_wise")
                @svc_wise_layout_condition = (report_layout == "service_line_wise")
                @eob = eob
                if !@orbograph_correspondence_condition
                  reason_code_crosswalk = ReasonCodeCrosswalk.new(@payer, eob, @client, facility)
                  adjustment_reasons.each do |adjustment_reason|
                    codes = reason_code_crosswalk.get_all_codes(adjustment_reason)
                    self.instance_variable_set("@#{adjustment_reason}_crosswalked_codes_for_eob", codes)
                  end
                
                  @svc = nil
                end
                if claim_level_eob_condition || eob_wise_layout_condition || @orbograph_correspondence_condition
                  csv << report_content(facility).join("\t").split(",")
                end
                if (!@orbograph_correspondence_condition) && (svc_wise_layout_condition)
                  service_payment_eobs = eob.service_payment_eobs
                  service_payment_eobs = service_payment_eobs.delete_if {|svc| svc.interest_service_line? && facility.details[:interest_in_service_line]}
                  service_payment_eobs.each_with_index do |svc, index|
                    @svc = svc
                    @index = index + 1
                    reason_code_crosswalk = ReasonCodeCrosswalk.new(@payer, svc, @client, facility)
                    adjustment_reasons.each do |adjustment_reason|
                      codes = reason_code_crosswalk.get_all_codes(adjustment_reason)
                      self.instance_variable_set("@#{adjustment_reason}_crosswalked_codes_for_service", codes)
                    end
                    csv << report_content(facility).join("\t").split(",")
                  end
                end
              end
            end
          end
        end
        return csv_string
      rescue Exception => e
        log = Logger.new('output_logs/Aggregate_835_report.log', 'daily')
        log.error "Exception  => " + e.message
        log.error e.backtrace.join("\n")
        puts "Exception  => " + e.message
        puts e.backtrace.join("\n")
      end
    else
      puts "Unable to generate aggregate_835_report as no checks are eligible."
    end

  end

  def report_header(client)
    header = ["Deposit Date", "Facility Name", "Payer type", "Payer ID",
      "Output Payid", "Payer Name", "Footnote Indicator", "Onbase Name",
      "Check Number", "Payment Method", "Check Date", "ABA Routing #",
      "Payer Account #", "Check Amount", "Image Page No.", "Image To",
      "Image Name", "Image Type", "Payment Type", "Patient Account Number",
      "Patient Last Name", "Patient First Name", "Subscriber Last Name",
      "Subscriber First Name", "Claim Type", "Claim Number", "Policy Number",
      "Member Id", "Patient ID - Qualifier", "Patient Id",
      "Provider Organization Name", "Rendering provider Last Name",
      "Rendering provider First Name", "Provider NPI", "Provider TIN",
      "Service FromDate", "Service ToDate", "Claim level From date",
      "Claim level To date", "Reference Code", "RevenueCode",
      "Bundled CPT code", "CPT Code", "Modifier1", "Modifier2", "Modifier3",
      "Modifier4", "Stand Alone Remark Code", "Charge Amount", "Paid Amount", "Allowed Amount",
      "Non covered", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Discount", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      denied_label(client), "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Coinsurance", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Copay", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Deductible", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Patient Responsibility", "Medicare Paid",
      "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Contractual Adjustment", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Miscellaneous One", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Miscellaneous Two", "Reason code", "Reason code description", "Group code", "HIPAA code", "ANSI Remark code",
      "Miscellaneous Balance", "Interest", "Plan type", "Patient Type", "Payment Code", "Allowance Code", "Capitation Code",
      "Carrier Code", "HCRA", "DRG Code", "Late Filing Charge", "Reject Reason",
      "Document Classification", "Tooth Number", "Processor Name",
      "MPI applied (Yes/No)", "QA staff name", "Job Status",
      "Class of Contract/Re-pricer info", "Place of Service (POS)"]
    header
  end
  
  def denied_label(client)
    if client.name.upcase.strip == 'UNIVERSITY OF PITTSBURGH MEDICAL CENTER'
      'Sequestration'
    else
      'Denied'
    end
  end

  def report_content(facility)
    @micr_line_information = check.micr_line_information unless facility.details[:micr_line_info].blank?
    job = check.job
    job_payer_group = job.payer_group
    get_default_groupcode(facility)

    content = [deposit_date, facility.name, check.get_actual_payer_type(job_payer_group),
      check.get_actual_payid(facility, job_payer_group, orbograph_correspondence_condition), get_output_payid,
      print_payer, get_footnote_indicator, get_onbase_name, check.check_number,
      check.payment_method, get_check_date, get_aba_routing_number,
      get_payer_account_number, check.check_amount.to_f, eob.image_page_no, eob.image_page_to_number,
      check.job.initial_image_name, job.retrieve_transaction_type(eob), check.payment_type, eob.patient_account_number,
      eob.patient_last_name, eob.patient_first_name, eob.subscriber_last_name,
      eob.subscriber_first_name, eob.claim_type, eob.claim_number,
      eob.insurance_policy_number, eob.subscriber_identification_code,
      eob.patient_identification_code_qualifier, eob.patient_identification_code,
      eob.provider_organisation, eob.rendering_provider_last_name, eob.rendering_provider_first_name,
      eob.provider_npi, eob.provider_tin, service_from_date,
      service_to_date, claim_from_date, claim_to_date,
      provider_control_number, revenue_code, bundled_procedure_code,
      procedure_code, modifier1, modifier2, modifier3,
      modifier4, stand_alone_remark_codes, charge_amount,
      paid_amount, allowable_amount, noncovered_amount,
      noncovered_code, noncovered_code_description, noncovered_group_code,
      noncovered_hipaa_code, noncovered_remark_codes,
      discount_amount, discount_code, discount_code_description, discount_group_code, discount_hipaa_code,
      discount_remark_codes, denied_amount, denied_code, denied_code_description, denied_group_code, denied_hipaa_code,
      denied_remark_codes, coinsurance_amount, coinsurance_code, coinsurance_code_description, coinsurance_group_code,
      coinsurance_hipaa_code, coinsurance_remark_codes,
      copay_amount, copay_code, copay_code_description, copay_group_code, copay_hipaa_code,
      copay_remark_codes, deductible_amount, deductuble_code, deductuble_code_description,
      deductible_group_code, deductuble_hipaa_code,
      deductible_remark_codes, pat_resposibility, primary_payment_amount, primary_payment_code,
      primary_payment_code_description, primary_payment_group_code, primary_payment_hipaa_code, primary_payment_remark_codes,
      contractual_amount, contractual_code, contractual_code_description, contractual_group_code,
      contractual_hipaa_code, contractual_remark_codes,

      miscellaneous_one_amount, miscellaneous_one_code, miscellaneous_one_code_description, miscellaneous_one_group_code,
      miscellaneous_one_hipaa_code, miscellaneous_one_remark_codes,
      miscellaneous_two_amount, miscellaneous_two_code, miscellaneous_two_code_description, miscellaneous_two_group_code,
      miscellaneous_two_hipaa_code, miscellaneous_two_remark_codes,
      miscellaneous_balance, claim_interest, eob.plan_type, eob.patient_type, get_payment_code,
      patient_type_code("in_patient_allowance_code", "out_patient_allowance_code", "1"),
      patient_type_code("capitation_code", "capitation_code", "2"),
      eob.carrier_code, eob.hcra, eob.drg_code, eob.late_filing_charge, get_reject_reason, eob.document_classification,
      tooth_number_details, processor, eob.mpi_applied_status, qa, job.job_status,
      eob.alternate_payer_name, eob.place_of_service
    ]
    content
  end

  def deposit_date
    batch.bank_deposit_date.strftime("%Y/%m/%d")
  end

  def processor
    check.job.processor.blank? ? "-" : check.job.processor.name
  end

  def qa
    check.job.qa.blank? ? "-" : check.job.qa.name
  end

  def service_from_date
    if svc_wise_layout_condition && !claim_level_eob_condition && !orbograph_correspondence_condition
      svc.date_of_service_from
    else
      ""
    end
  end

  def service_to_date
    if svc_wise_layout_condition && !claim_level_eob_condition && !orbograph_correspondence_condition
      svc.date_of_service_to
    else
      ""
    end
  end

  def claim_from_date
    if claim_level_eob_condition || orbograph_correspondence_condition
      eob.claim_from_date
    else
      ""
    end
  end

  def claim_to_date
    if claim_level_eob_condition || orbograph_correspondence_condition
      eob.claim_to_date
    else
      ""
    end
  end

  def claim_interest
    if svc_wise_layout_condition and index == 1
      eob.claim_interest
    elsif condition_to_obtain_values_from_eob_object
      eob.claim_interest
    else
      ""
    end
  end

  def get_payment_code
    if check.eob_type == 'Patient'
      "202614"
    else
      payer = check.payer
      facility_payer_information = FacilitiesPayersInformation.find_by_payer_id_and_facility_id(payer.id, facility.id) if payer
      patient_type = eob.patient_type
      if !patient_type.blank?
        unless facility_payer_information.blank?
          case patient_type
          when 'INPATIENT'
            facility_payer_information.in_patient_payment_code
          when 'OUTPATIENT'
            facility_payer_information.out_patient_payment_code
          end
        end
      else
        ""
      end
    end
  end

  def patient_type_code(in_patient_type_code, out_patient_type_code, code)
    if condition_to_obtain_values_from_eob_object
      ""
    elsif check.eob_type == 'Patient'
      ""
    else
      payer = check.payer
      facility_payer_information = FacilitiesPayersInformation.find_by_payer_id_and_facility_id(payer.id, facility.id) if payer
      if !svc.inpatient_code.blank? and svc.inpatient_code.include?(code)       
        unless facility_payer_information.blank?
          case in_patient_type_code
          when 'in_patient_allowance_code'
            facility_payer_information.in_patient_allowance_code
          when 'capitation_code'
            facility_payer_information.capitation_code
          end
        end
      elsif !svc.outpatient_code.blank? and svc.outpatient_code.include?(code)
        unless facility_payer_information.blank?
          case out_patient_type_code
          when 'out_patient_allowance_code'
            facility_payer_information.out_patient_allowance_code
          when 'capitation_code'
            facility_payer_information.capitation_code
          end
        end
      else
        ""
      end
    end
  end

  def provider_control_number
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.service_provider_control_number
    end
  end

  def revenue_code
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.revenue_code
    end
  end

  def bundled_procedure_code
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.bundled_procedure_code
    end
  end

  def procedure_code
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.service_procedure_code
    end
  end

  def modifier1
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.service_modifier1
    end
  end

  def modifier2
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.service_modifier2
    end
  end

  def modifier3
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.service_modifier3
    end
  end

  def modifier4
    if condition_to_obtain_values_from_eob_object
      ""
    else
      svc.service_modifier4
    end
  end

  def stand_alone_remark_codes
    remark_codes = []
    if condition_to_obtain_values_from_eob_object
      remark_codes = eob.get_remark_codes     
    else
      remark_codes = svc.get_remark_codes
    end
    remark_codes.join(':') unless remark_codes.blank?
  end

  def charge_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_submitted_charge_for_claim.to_f
    else
      svc.service_procedure_charge_amount.to_f
    end
  end

  def paid_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_amount_paid_for_claim.to_f
    else
      svc.service_paid_amount.to_f
    end
  end

  def allowable_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_allowable.to_f
    else
      svc.service_allowable.to_f
    end
  end

  def noncovered_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_non_covered.to_f
    else
      svc.service_no_covered.to_f
    end
  end

  def noncovered_code
    get_reason_code('noncovered')    
  end

  def noncovered_code_description
    get_reason_code_description('noncovered')
  end

  def discount_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_discount.to_f
    else
      svc.service_discount.to_f
    end
  end

  def discount_code
    get_reason_code('discount')
  end

  def discount_code_description
    get_reason_code_description('discount')
  end

  def denied_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_denied.to_f
    else
      svc.denied.to_f
    end
  end

  def denied_code
    get_reason_code('denied')
  end

  def denied_code_description
    get_reason_code_description('denied')
  end

  def coinsurance_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_co_insurance.to_f
    else
      svc.service_co_insurance.to_f
    end
  end

  def coinsurance_code
    get_reason_code('coinsurance')
  end

  def coinsurance_code_description
    get_reason_code_description('coinsurance')
  end

  def copay_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_co_pay.to_f
    else
      svc.service_co_pay.to_f
    end
  end

  def copay_code
    get_reason_code('copay')
  end

  def copay_code_description
    get_reason_code_description('copay')
  end

  def deductible_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_deductible.to_f
    else
      svc.service_deductible.to_f
    end
  end

  def deductuble_code
    get_reason_code('deductible')
  end

  def deductuble_code_description
    get_reason_code_description('deductible')
  end

  def pat_resposibility
    coinsurance_amount + copay_amount + deductible_amount
  end

  def primary_payment_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_primary_payer_amount.to_f
    else
      svc.primary_payment.to_f
    end
  end

  def primary_payment_code
    get_reason_code('primary_payment')
  end

  def primary_payment_code_description
    get_reason_code_description('primary_payment')
  end

  def contractual_amount
    if condition_to_obtain_values_from_eob_object
      eob.total_contractual_amount.to_f
    else
      svc.contractual_amount.to_f
    end
  end

  def contractual_code
    get_reason_code('contractual')
  end

  def contractual_code_description
    get_reason_code_description('contractual')
  end

  def miscellaneous_one_amount
    if condition_to_obtain_values_from_eob_object
      eob.miscellaneous_one_adjustment_amount.to_f
    else
      svc.miscellaneous_one_adjustment_amount.to_f
    end
  end

  def miscellaneous_one_code
    get_reason_code('miscellaneous_one')
  end

  def miscellaneous_one_code_description
    get_reason_code_description('miscellaneous_one')
  end

  def miscellaneous_two_amount
    if condition_to_obtain_values_from_eob_object
      eob.miscellaneous_two_adjustment_amount.to_f
    else
      svc.miscellaneous_two_adjustment_amount.to_f
    end
  end

  def miscellaneous_two_code
    get_reason_code('miscellaneous_two')
  end

  def miscellaneous_two_code_description
    get_reason_code_description('miscellaneous_two')
  end
  ###################################

  def miscellaneous_balance
    if condition_to_obtain_values_from_eob_object
      eob.miscellaneous_balance.to_f
    else
      svc.miscellaneous_balance.to_f
    end
  end

  def noncovered_hipaa_code
    get_hipaa_code('noncovered')
  end

  def discount_hipaa_code
    get_hipaa_code('discount')
  end

  def denied_hipaa_code
    get_hipaa_code('denied')
  end

  def coinsurance_hipaa_code
    get_hipaa_code('coinsurance')
  end

  def copay_hipaa_code
    get_hipaa_code('copay')
  end

  def deductuble_hipaa_code
    get_hipaa_code('deductible')
  end

  def primary_payment_hipaa_code
    get_hipaa_code('primary_payment')
  end

  def contractual_hipaa_code
    get_hipaa_code('contractual')
  end

  def miscellaneous_one_hipaa_code
    get_hipaa_code('miscellaneous_one')
  end

  def miscellaneous_two_hipaa_code
    get_hipaa_code('miscellaneous_two')
  end


  def noncovered_remark_codes
    get_remark_codes('noncovered')
  end

  def discount_remark_codes
    get_remark_codes('discount')
  end

  def denied_remark_codes
    get_remark_codes('denied')
  end

  def coinsurance_remark_codes
    get_remark_codes('coinsurance')
  end

  def copay_remark_codes
    get_remark_codes('copay')
  end

  def deductible_remark_codes
    get_remark_codes('deductible')
  end

  def primary_payment_remark_codes
    get_remark_codes('primary_payment')
  end

  def contractual_remark_codes
    get_remark_codes('contractual')
  end

  def miscellaneous_one_remark_codes
    get_remark_codes('miscellaneous_one')
  end

  def miscellaneous_two_remark_codes
    get_remark_codes('miscellaneous_two')
  end

  def get_aba_routing_number
    unless @micr_line_information.blank?
      @micr_line_information.aba_routing_number
    else
      ""
    end
  end

  def get_payer_account_number
    unless @micr_line_information.blank?
      @micr_line_information.payer_account_number
    else
      ""
    end
  end

  def get_check_date
    check_date = check .check_date
    check_date.blank? ? "" : check_date.strftime("%m/%d/%Y")
  end

  def get_onbase_name
    micr_line_information = check.micr_line_information
    if micr_line_information && micr_line_information.payer
      onbase_name_record = FacilitiesMicrInformation.get_client_or_site_specific_onbase_name_record(micr_line_information.id, @client.id, facility.id)
      onbase_name = onbase_name_record.onbase_name if onbase_name_record
    end
    onbase_name.blank? ? "" : onbase_name
  end

  def get_output_payid
    micr_line_information = check.micr_line_information
    if micr_line_information
      check_payer = micr_line_information.payer
    end
    if check_payer.blank?
      check_payer = check.payer
    end
    check_payer ? check_payer.output_payid_for_aggregate_report(facility.id, @client.id) : ""
  end

  def print_payer
    if orbograph_correspondence_condition
      eob.details['payer_name']
    else
      check.payer.payer
    end
  end

  def get_default_groupcode(facility)
    default_codes = facility.default_codes_for_adjustment_reasons
    unless default_codes.blank?
      default_codes.each do |default_code|
        adjustment_reason = default_code.adjustment_reason
        unless adjustment_reason.blank?
          eval("@#{adjustment_reason}_group_code = default_code")
        end
      end
    end
  end

  
  def noncovered_group_code
    get_group_code('service_no_covered', 'noncovered')
  end

  def denied_group_code
    get_group_code('denied', 'denied')
  end

  def discount_group_code
    get_group_code('service_discount', 'discount')
  end

  def coinsurance_group_code
    get_group_code('service_co_insurance', 'coinsurance')
  end

  def deductible_group_code
    get_group_code('service_deductible', 'deductible')
  end

  def copay_group_code
    get_group_code('service_co_pay', 'copay')
  end

  def primary_payment_group_code
    get_group_code('primary_payment', 'primary_payment')
  end
  
  def contractual_group_code
    get_group_code('contractual_amount', 'contractual')
  end

  def miscellaneous_one_group_code
    get_group_code('miscellaneous_one_adjustment_amount', 'miscellaneous_one')
  end

  def miscellaneous_two_group_code
    get_group_code('miscellaneous_two_adjustment_amount', 'miscellaneous_two')
  end

  def total_amount(service_adjustment_amount_column_name)
    total_amount = eob.service_payment_eobs.each do |svc|
      unless svc.send("#{service_adjustment_amount_column_name}").nil?
        total_amount = total_amount.to_i if total_amount.nil?
        total_amount += svc.send("#{service_adjustment_amount_column_name}")
      end
    end
  end

  def get_reject_reason
    return "" if eob.blank?
    if orbograph_correspondence_condition
      eob.details['reason'].to_s.strip
    else
      eob.rejection_comment.blank? ? "" : eob.rejection_comment
    end
  end

  def get_footnote_indicator
    footnote_indicator = "Non Footnote"
    check_payer = check.payer
    if check_payer
      footnote_indicator_frm_db = check_payer.footnote_indicator
      unless footnote_indicator_frm_db.blank?
        footnote_indicator = footnote_indicator_frm_db == true ? "Footnote" : "Non Footnote"
      end
    end
    footnote_indicator
  end

  def tooth_number_details
    if condition_to_obtain_values_from_eob_object
      eob.claim_tooth_number.gsub(',',':') if eob.claim_tooth_number
    else
      svc.tooth_number.gsub(',',':') if svc.tooth_number
    end
  end

  def get_codes(adjustment_reason)
    crosswalked_codes = {}
    if condition_to_obtain_values_from_eob_object
      crosswalked_codes = eval("@#{adjustment_reason}_crosswalked_codes_for_eob")
    else
      crosswalked_codes = eval("@#{adjustment_reason}_crosswalked_codes_for_service")
    end
    crosswalked_codes
  end

  def get_normalized_code(adjustment_reason, code)
    all_codes = get_codes(adjustment_reason)
    codes = []
    if all_codes
      all_codes.each do |code_hash|
        code_hash.each do |code_name, value|
          if code_name == code.to_sym
            codes << value
          end
        end
      end
    end
    if codes.present?
      codes = codes.flatten
      codes.pop if codes.length == 1 && codes[0].blank?
    end
    codes.join(':')
  end

  def get_reason_code(adjustment_reason)
    get_normalized_code(adjustment_reason, 'reason_code')
  end

  def get_reason_code_description(adjustment_reason)
    get_normalized_code(adjustment_reason, 'reason_code_description')
  end

  def get_hipaa_code(adjustment_reason)
    get_normalized_code(adjustment_reason, 'hipaa_code')
  end

  def get_group_code(service_adjustment_column_name, adjustment_reason)
    group_codes, reason_codes = '', ''
    codes = get_normalized_code(adjustment_reason, 'group_code')
    rc_codes = get_normalized_code(adjustment_reason, 'reason_code')
    reason_codes = rc_codes if rc_codes && rc_codes.split(':').length > 0
    group_codes = codes if codes.present?
    if condition_to_obtain_values_from_eob_object
      amount = total_amount(service_adjustment_column_name)
    else
      amount = svc.send("#{service_adjustment_column_name}")
    end
    
    amount.nil? ? nil : (amount.to_s.to_f.zero? ? (reason_codes.blank? ? nil : group_codes) : group_codes)
  end

  def get_remark_codes(adjustment_reason)
    get_normalized_code(adjustment_reason, 'remark_codes')
  end

  def condition_to_obtain_values_from_eob_object
    claim_level_eob_condition || eob_wise_layout_condition || orbograph_correspondence_condition
  end

end
