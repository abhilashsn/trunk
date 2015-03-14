module Output835Helper

  def isa_08
    if @facility_name == "SOLUTIONS 4 MDS"
      "4108           "
    elsif @config_835[:payee_name].present?
      @config_835[:payee_name].justify(15)
    else
      @facility_name.justify(15)
    end
  end

  def gs_03
    if @facility_name == "SOLUTIONS 4 MDS"
      "4108"
    elsif @facility_config.details[:payee_name].present?
      @facility_config.details[:payee_name]
    else
      @facility_name.slice(0,15)
    end
  end

  def group_date
    (@facility.index_file_parser_type == 'Barnabas' ? @batch.date.strftime("%Y%m%d") : Time.now().strftime("%Y%m%d"))
  end

  def checks_in_functional_group(batch_id = nil)
    if batch_id
      checks_in_batch = @checks.collect {|check| check.batch.id == batch_id}
      checks_in_batch.length
    else
      @checks.length
    end
  end

  def new_batch?
    batchid = @batch.batchid
    if batchid != @prev_batchid
      @prev_batchid = batchid
      true
    else
      false
    end
  end

  def supplemental_amount
    if @eob_type == 'Patient'
      unless @service.service_paid_amount.to_f.zero?
        amount = @service.amount('service_paid_amount')
      end
    else
      unless @service.service_allowable.to_f.zero?
        amount = @service.amount('service_allowable')
      end
    end
    amount
  end

  def svc_revenue_code
    ((proc_cpt_code.present? || bundled_cpt_code.present?) and revenue_code.present?) ? revenue_code : ''
  end

  def composite_med_proc_id
    qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
    if bundled_cpt_code.present?
      elem = ["#{qualifier}:#{bundled_cpt_code}"]
    elsif proc_cpt_code.present?
      elem = ["#{qualifier}:#{captured_or_blank_proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
    elsif revenue_code.present?
      elem = ["NU:#{revenue_code}"]
    else
      elem = ["#{qualifier}:"]
    end
    elem = Output835.trim_segment(elem)
    elem.join(':')
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

  def svc_procedure_cpt_code
    if bundled_cpt_code.present? and proc_cpt_code.present?     
      qualifier = !@service.service_cdt_qualifier.blank? ? @service.service_cdt_qualifier.upcase : 'HC'
      elem = ["#{qualifier}:#{captured_or_blank_proc_cpt_code}", @service.service_modifier1, @service.service_modifier2, @service.service_modifier3, @service.service_modifier4]
      elem = Output835.trim_segment(elem)
      elem.join(':')
    end
  end
  
  def service_line_item_control_num
  end

  def standard_industry_code_segments(entity, claim_level_eob = false)
    if claim_level_eob
      if @facility.details[:rc_crosswalk_done_by_client]
        Output835.standard_industry_code_segments(entity, @client, @facility, @payer, @element_seperator)
      end
    else
      Output835.standard_industry_code_segments(entity, @client, @facility, @payer, @element_seperator)
    end
  end

  def update_clp! claim_segments
    clp =  claim_segments[0][0]
    clp = clp.split('*')
    unless @clp_pr_amount.blank?
      @clp_05_amount += @clp_pr_amount
    end
    clp[5] = ((@clp_05_amount && @clp_05_amount >= 0) ? "%.2f" %@clp_05_amount : "")
    clp = Output835.trim_segment(clp)
    clp = clp.join('*')
    claim_segments[0][0] = clp
  end

  def patient_account_number
    @eob.patient_account_number
  end

  def image_page_name
  end

  def prov_last_name_or_org
    if @eob.rendering_provider_last_name.present?
      @eob.rendering_provider_last_name.upcase
    elsif @eob.provider_organisation.present?
      @eob.provider_organisation.upcase
    else
      @facility_name
    end
  end

  def provider_summary_info
  end

  def claim_start_date
    if @claim && @claim.claim_statement_period_start_date
      @claim.claim_statement_period_start_date
    end
  end

  def claim_end_date
    if @claim && @claim.claim_statement_period_end_date
      @claim.claim_statement_period_end_date
    end
  end

  def claim_type_weight
    @eob.claim_type_weight
  end

  def eob_facility_type_code
    if (@client_name == 'ORBOGRAPH' || @client_name == 'ORB TEST FACILITY')
      return ((@eob.place_of_service.blank?)? '11' : @eob.place_of_service)
    else
      if @claim && @claim.facility_type_code.present?
        @claim.facility_type_code
      end
    end
  end

  def claim_freq_indicator
    if @claim && @claim.claim_frequency_type_code.present?
      @claim.claim_frequency_type_code
    end
  end

  def plan_type
    @eob.plan_type
  end

  # Returns the following in that precedence.
  # i. Payee NPI from 837   ii. If not, Payee TIN from 837   iii. If not NPI from FC UI   iv. If not TIN from FC UI
  # Returns qualifier 'XX' for NPI and 'FI' for TIN
  def service_payee_identification
    if (@claim && @claim.payee_npi.present?)
      code = @claim.payee_npi
      qual = 'XX'
      Output835.log.info "Payee NPI from the 837 is chosen"
    elsif (@claim && @claim.payee_tin.present?)
      code = @claim.payee_tin
      qual = 'FI'
      Output835.log.info "Payee TIN from 837 is chosen"
    elsif @facility.facility_npi.present?
      code = @facility.facility_npi
      qual = 'XX'
      Output835.log.info "facility NPI from FC is chosen"
    elsif @facility.facility_tin.present?
      code = @facility.facility_tin
      qual = 'FI'
      Output835.log.info "facility TIN from FC is chosen"
    end

    return code, qual
  end


  def service_payee_identification_choc
    code, qual = nil, nil
    if (@claim && @claim.payee_tin.present?)
      code = @claim.payee_tin
      qual = 'FI'
      Output835.log.info "Payee TIN from 837 is chosen"
    elsif @facility.facility_tin.present?
      code = @facility.facility_tin
      qual = 'FI'
      Output835.log.info "facility TIN from FC is chosen"
    end
    return code, qual
  end

  # Returns the following in that precedence.
  # i. User entered Provider NPI   ii. If not, Provider NPI from 837  iii.If not, Provider NPI from 837 iv. If not NPI from FC UI   v. If not TIN from FC UI
  # Returns qualifier 'XX' for NPI and 'FI' for TIN
  def service_prov_identification
    if @eob && @eob.provider_npi.present?
      code = @eob.provider_npi
      qual = 'XX'
      Output835.log.info "User entered Provider NPI is chosen"
    elsif @eob && @eob.provider_tin.present?
      code = @eob.provider_tin
      qual = 'FI'
      Output835.log.info "User entered Provider tin is chosen"
    elsif (@claim && @claim.provider_npi.present?)
      code = @claim.provider_npi
      qual = 'XX'
      Output835.log.info "Provider NPI from the 837 is chosen"
    elsif (@claim && @claim.provider_ein.present?)
      code = @claim.provider_ein
      qual = 'FI'
      Output835.log.info "Provider TIN from 837 is chosen"
    elsif @facility.facilities_npi_and_tins.present?
      facility_npi_and_tin = @facility.facilities_npi_and_tins.first
      if facility_npi_and_tin.npi.present?
        code = facility_npi_and_tin.npi
        qual = 'XX'
        Output835.log.info "facility NPI from FC is chosen"
      elsif facility_npi_and_tin.tin.present?
        code = facility_npi_and_tin.tin
        qual = 'FI'
        Output835.log.info "facility TIN from FC is chosen"
      end
    end
    return code, qual
  end

  def output_check_number
    check_num = @check.check_number
    (check_num ? check_num.to_s : "0")
  end

  def total_submitted_charges
    @eobs.inject(0){ |sum, eob| sum + eob.amount('total_submitted_charge_for_claim')}
  end

  # Formats a dollar amount that is to be printed in the output
  # returns the amount if present else returns 0
  def format_amount(amount)
    amount = amount.to_f
    (amount == amount.truncate) ? amount.truncate : amount
  end

  #TODO: need a look
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
      default_patient_name = @facility_output_config.details[:default_patient_name]
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

  #Identify the first eob having an associated claim record, then fetch the claim
  #Give precedence to payee details stored in claim, over the payee details entered in the app.
  def get_facility
    claim = @eobs.collect {|eob| eob.claim_information}.compact.first
    claim.facility = @facility if claim
    claim || @facility
  end

  def effective_payment_date
    date_config =  @is_correspndence_check ? @facility_output_config.details[:bpr_16_correspondence] : @facility_output_config.details[:bpr_16]
    if date_config == "Batch Date" || @check.check_date.blank?
      @batch.date.strftime("%Y%m%d")
    elsif date_config == "835 Creation Date"
      Time.now.strftime("%Y%m%d")
    elsif date_config == "Check Date"
      @check.check_date.strftime("%Y%m%d")
    end
  end

  def get_ordered_insurance_payment_eobs(object)
    object.insurance_payment_eobs.order("balance_record_type asc, image_page_no, end_time asc")
  end

  def get_ordered_patient_payment_eobs(object)
    object.patient_pay_eobs.order(:image_page_no, :end_time)
  end

  def account_number
    @is_correspndence_check ? '' : (@micr.payer_account_number.to_s.strip if @micr)
  end

  def account_num_indicator
    @is_correspndence_check ? '' : 'DA'
  end

  def routing_number
    (@micr &&  !@is_correspndence_check) ? @micr.aba_routing_number.to_s.strip : ''
  end

  def id_number_qualifier
    @is_correspndence_check ? '' : '01'
  end

  def payment_indicator
    payment_method = @check.payment_method
    if payment_method == "CHK" || payment_method == "OTH"
      "CHK"
    elsif @check_amount.to_f.zero?
      "NON"
    elsif (@check_amount.to_f > 0 && payment_method == "EFT")
      "ACH"
    end
  end

  # TRN02 segment value
  def ref_number
    if ['AHN', 'SUBURBAN HEALTH', 'UWL', 'ANTHEM'].include?(@facility_name)
      file_number = @batch.file_name.split('_')[0][3..-1] rescue "0"
      date = @batch.date.strftime("%Y%m%d")
      "#{date}_#{file_number}"
    else
      output_check_number
    end
  end


  def check_amount
    amount = @check.check_amount.to_f
    (amount == (amount.truncate)? amount.truncate : amount)
  end

  def facility_type_code
    @eobs.first.facility_type_code || '13'
  end

  def provider_adjustment_grouping(provider_adjustments)
    provider_adjustments.group_by{|prov_adj| "#{prov_adj.qualifier}_#{prov_adj.patient_account_number}"}
  end

  def output_payid(payer)
    if payer.id
      output_payid_record = FacilitiesPayersInformation.get_client_or_site_specific_output_payid_record(payer.id, @client.id, @facility.id)
      output_payid_record.output_payid if output_payid_record
    end
  end


  def write_provider_adjustment_excel provider_adjustments
    @excel_index = @plb_excel_sheet.last_row_index + 1
    provider_adjustments.each do |prov_adj|
      current_job = prov_adj.job
      current_job = Job.find(current_job.parent_job_id) if current_job.parent_job_id
      prov_adj_patient_account_number = prov_adj.patient_account_number
      if prov_adj_patient_account_number.blank? and (@client_name == 'ORBOGRAPH' || @client_name == 'ORB TEST FACILITY')
        prov_adj_patient_account_number = "-"
      end
      excel_row = [current_job.batch.date.strftime("%m/%d/%Y"), current_job.batch.batchid, current_job.check_number, prov_adj.qualifier,
        prov_adj_patient_account_number, format_amount(prov_adj.amount).to_s.to_dollar
      ]
      @plb_excel_sheet.row(@excel_index).replace excel_row.flatten
      @excel_index += 1
    end
  end

  #supplies provider-level control information
  def transaction_statistics(eobs)
  end

  def reciever_id
  end

  def bpr_01
    if (@check_amount.to_f > 0 && @check.payment_method == "CHK")
      "C"
    elsif (@check_amount.to_f.zero?)
      "H"
    elsif (@check_amount.to_f > 0 && @check.payment_method == "EFT")
      "I"
    elsif (@check.payment_method == "OTH")
      "D"
    end
  end

  def get_orbo_payer_id(check)
    if check.eob_type == 'Patient'
      payid = 'P9998'
    else
      payid= @payer.payid.to_s if @payer
    end
    payid
  end

  
  def payer_id
    @payid = @config_835[:isa_06]
    payer = @first_check.payer
    if @payid == 'Predefined Payer ID'
      if @facility.index_file_parser_type == 'Barnabas'
        @payid = payer.output_payid(@facility) if payer
      elsif @client_name == "PACIFIC DENTAL SERVICES"
        @payid = payer.gcbs_output_payid(@facility)
      else
        @payid = payer.supply_payid if payer
      end
    else
      @payid.to_s
    end
  end

  def payer_additional_identification(payer)
  end

  def claim_level_eob?
    @eob.category.upcase == "CLAIM"
  end

  def service_prov_identifier
    if @facility.details['re_pricer_info'] && @check.alternate_payer_name.present?
      ['NM1', 'PR', '2', @check.alternate_payer_name.to_s.strip].join(@element_seperator)
    end
  end

  def trim(string, size)
    if string
      if string.strip.length > size
        string.strip.slice(0,size)
      else
        string.strip.ljust(size)
      end
    end
  end

  def reference_identification
  end

  def captured_or_blank_patient_account_number(captured_ac_number, output_type = nil)
    default_ac_number = @facility.patient_account_number_default_match.to_s.upcase
    return captured_ac_number.to_s.strip if default_ac_number.blank?
    captured_ac_number.strip.upcase == default_ac_number ? blank_output_format(output_type) : captured_ac_number.to_s.strip
  end

  def captured_or_blank_patient_first_name(captured_first_name, output_type = nil)
    default_first_name = @facility.patient_first_name_default_match.to_s.upcase
    return captured_first_name.to_s.strip if default_first_name.blank?
    captured_first_name.strip.upcase == default_first_name ? blank_output_format(output_type) : captured_first_name.to_s.strip
  end

  def captured_or_blank_patient_last_name(captured_last_name, output_type = nil)
    default_last_name = @facility.patient_last_name_default_match.to_s.upcase
    return captured_last_name.to_s.strip if default_last_name.blank?
    captured_last_name.strip.upcase == default_last_name ? blank_output_format(output_type) : captured_last_name.to_s.strip
  end

  def can_print_service_date(date)
    return false if date.blank?
    if @facility.date_of_service_default_match?
      return !(date == @facility.date_of_service_default_match.strftime("%Y%m%d"))
    end
    true
  end

  def captured_or_blank_proc_cpt_code
    default_proc_cpt_code = @facility.cpt_code_default_match
    return proc_cpt_code if default_proc_cpt_code.blank?
    proc_cpt_code.strip.upcase == default_proc_cpt_code.strip.upcase ? '' : proc_cpt_code
  end

  def blank_output_format(output_type)
    output_type.present? ? '-' : ''
  end

  def payee_identification_for_optim(payee,check = nil,claim = nil,eobs = nil)
    @check =  @check.nil?? check : @check
    @claim = @claim.nil?? claim : @claim
    @eobs = @eobs.nil?? eobs : @eobs
    elements = ['N1', 'PE', payee_name(payee,@eobs)]
    if @facility_payee && @facility_payee.payee_tin?
      elements << 'FI'
      elements << @facility_payee.payee_tin.strip.upcase
    end
    elements.join(@element_seperator)
  end

  def payee_identification_for_houston(payee,check = nil,claim = nil,eobs = nil)
    @check =  @check.nil?? check : @check
    @claim = @claim.nil?? claim : @claim
    @eobs = @eobs.nil?? eobs : @eobs
    elements = ['N1', 'PE', payee_name(payee,@eobs)]
    if @facility_payee && @facility_payee.payee_npi?
      elements << 'XX'
      elements << @facility_payee.payee_npi.strip.upcase
    end
    elements.join(@element_seperator)
  end

  def payee_additional_identification_for_houston(payee)
    if @facility_payee && @facility_payee.payee_npi?
      [ 'REF', 'TJ', @facility_payee.payee_tin].join(@element_seperator)
    end
  end

  def get_exact_account_number(eob, acc_num_str, account_nos)
    duplicate_acc_num = []
    patient_acc_no = eob.patient_account_number
    duplicate_acc_num = account_nos.select {|num| num == patient_acc_no}
    if !duplicate_acc_num.blank? and duplicate_acc_num.length > 1
      acc_num_str << patient_acc_no
    else
      acc_num_str = []
    end
    if acc_num_str.length > 1
      actual_acc_num = "#{patient_acc_no}_#{acc_num_str.length - 1}"
    else
      actual_acc_num = patient_acc_no
    end

    return actual_acc_num
  end

  def get_parent_job_id_from_eob_reason_codes(level_type, eob)
    if level_type == "eob_level"
      eob_reason_codes = EobReasonCode.where(["insurance_payment_eob_id = ? and active = ?" , eob.id, "1"])
      unless eob_reason_codes.blank?
        rc_job_id = eob_reason_codes.first.job_id
        parent_job_id = Job.find_by_id(rc_job_id).parent_job_id
      end
      parent_job_id
    end
  end

  def merge_and_split_images_for_medassets(check, eob, batch_path, actual_acc_num, unidentified_acc_no_of_facility, medasset_eobs, level_type)
    @check = check
    @batch = check.batch
    job = check.job
    @job = job
    FileUtils.mkdir_p(batch_path)
    image_path = batch_path + "/image"
    FileUtils.mkdir_p(image_path)
    all_jobs = Job.find(:all, :conditions => ["batch_id =?", @batch.id])
    image_names_for_job = []
    images = @job.images_for_jobs
    client_images = @job.client_images_to_jobs
    parent_job_id = get_parent_job_id_from_eob_reason_codes(level_type, eob)

    if parent_job_id.nil?
      images.each do |image|
        image_names_for_job = get_original_images(image, image_path, image_names_for_job)
      end
      rc_image_names_for_job = image_names_for_job
      create_multi_page_image_for_medassets(eob, batch_path, image_names_for_job, rc_image_names_for_job, image_path, actual_acc_num, unidentified_acc_no_of_facility, medasset_eobs, level_type)
    else
      all_jobs.each do |single_job|
        if single_job.parent_job_id == job.id
          images.each_with_index do |image, index|
            image_names_for_job = get_original_images(image, image_path, image_names_for_job)
            image_names_for_job = image_names_for_job.uniq
            rc_image_names_for_job = image_names_for_job

            if client_images[index].sub_job_id == single_job.id
              image_names_for_job = get_original_images(image, image_path, image_names_for_job)
              image_names_for_job = image_names_for_job.uniq
            end
          end
          create_multi_page_image_for_medassets(eob, batch_path, image_names_for_job, rc_image_names_for_job, image_path, actual_acc_num, unidentified_acc_no_of_facility, medasset_eobs, level_type)
        end
      end
    end
    system("rm -r #{image_path}")
  end

  def get_original_images(image, image_path, image_names_for_job)
    image_name = File.basename(image.public_filename_url())
    original_path =  image.public_filename_url()
    system("cd #{image_path};cp #{original_path} #{image_path}")
    image_names_for_job << image_name
    return image_names_for_job
  end

  def get_eob_and_rc_images(eob, images_with_spanning_eobs, image_path, image_names_for_job, rc_image_names_for_job)
    page_from = eob.image_page_no - 1
    page_to = eob.image_page_to_number - 1

    page_from.upto(page_to) { |i|
      images_with_spanning_eobs << image_path + "/"+ image_names_for_job[i]
    }
    eob_reason_codes = EobReasonCode.where(["insurance_payment_eob_id = ? and active = ?" , eob.id, "1"])
    unless eob_reason_codes.blank?
      eob_reason_codes.each do |eob_reason_code|
        rc_page = eob_reason_code.page_no - 1
        images_with_spanning_eobs << image_path + "/"+ rc_image_names_for_job[rc_page]
      end
    end
    images_with_spanning_eobs
  end

  def create_multi_page_image_for_medassets(eob, batch_path, image_names_for_job, rc_image_names_for_job, image_path, actual_acc_num, unidentified_acc_no_of_facility, medasset_eobs, level_type)
    single_page_files = Dir.glob("#{image_path}/*.tif").sort
    unless image_names_for_job.nil?
      first_image_name = image_names_for_job[0]
      images_with_spanning_eobs = []
      unidentified_eobs = []
      unless unidentified_acc_no_of_facility.blank?
        unidentified_eobs = medasset_eobs.select {|medasset_eob| unidentified_acc_no_of_facility.include?(medasset_eob.patient_account_number)}
      end
      if(level_type == "eob_level" || (level_type == "check_level" && unidentified_eobs.length > 0 ))
        if !@check.correspondence?
          images_with_spanning_eobs << image_path + "/"+ first_image_name
        end
      end
      
      if level_type == "eob_level"
        images_with_spanning_eobs = get_eob_and_rc_images(eob, images_with_spanning_eobs, image_path, image_names_for_job, rc_image_names_for_job)
      elsif level_type == "check_level"
        if unidentified_eobs.length > 0
          unidentified_eobs.each do |eob|
            images_with_spanning_eobs = get_eob_and_rc_images(eob, images_with_spanning_eobs, image_path, image_names_for_job, rc_image_names_for_job)
          end
        end
      end
      images_with_spanning_eobs = images_with_spanning_eobs.uniq
      
      if images_with_spanning_eobs.length > 0
        multipage_image_name = "#{@batch.lockbox}_#{@batch.date.strftime("%Y%m%d")}_#{@check.check_number}"
        if level_type == "check_level"
          resultant_image_name = "#{multipage_image_name}.tif"
        else
          resultant_image_name = "#{multipage_image_name}_#{actual_acc_num}.tif"
        end
        system("cd #{batch_path}; tiffcp #{images_with_spanning_eobs.join(' ')} #{batch_path}/#{resultant_image_name}")
      end

    end
  end

end