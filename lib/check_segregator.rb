class CheckSegregator
  def initialize(ins_grouping = 'by_batch', pat_grouping = 'by_batch')
    @ins_grouping = ins_grouping
    @pat_grouping = pat_grouping
    @zip_type = []
  end

  #This method takes in an array of batchids and return a two dimentional array of checks
  #first dimension represents the object used for grouping, resulting in one output file per element
  #second dimension represents the checks in each output file
  def segregate(batch_ids)
    checks = CheckInformation.by_batch(batch_ids)
    @facility = checks.first.batch.facility
    @client = @facility.client
    @client_name = @client.name.upcase
    @zip_type = checks.collect(&:batch).collect(&:correspondence).uniq

    if FacilityOutputConfig.insurance_eob(@facility.id) &&
        FacilityOutputConfig.insurance_eob(@facility.id).length > 0
      insurance_eob_output_config = FacilityOutputConfig.insurance_eob(@facility.id).first
      if !insurance_eob_output_config.blank?
        xml_output_config_format = insurance_eob_output_config.format.to_s.upcase == 'XML'
      end
    end

    checks = checks.delete_if {|c| c.job.incomplete?}
    checks.group_by do |check|
      payer = check.payer
      job = check.job
      payer_type = job.payer_group if !job.blank?
      if insurance_eob_output_config.payment_corres_patpay_in_one_file ||
          insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
        output_config = insurance_eob_output_config
      else
        output_config = @facility.output_config(payer_type)
      end
      if !xml_output_config_format
        if output_config.payment_corres_patpay_in_one_file ||
            output_config.payment_patpay_in_one_corres_in_separate_file
          patient_pay_group_name(check, @ins_grouping)
        else
          case payer_type(check)
          when 'insurancepay'
            group_name(check, @ins_grouping)
          when 'patpay'
            if @pat_grouping
              if @client_name == "BARNABAS"
                group_name(check, @pat_grouping)
              else
                patient_pay_group_name(check, @pat_grouping)
              end
            else
              raise "Patient Pay output configuration must be present to generate Patient Pay output."
            end
          when 'notapplicable'
            if @pat_grouping
              group_name(check, @pat_grouping)
            else
              raise "Patient Pay output configuration must be present to generate Patient Pay output."
            end
          end
        end
      else
        case payer_type(check)
        when 'insurancepay' 
          group_name(check, @ins_grouping)
        when 'patpay', 'notapplicable'
          if @pat_grouping
            group_name(check, @pat_grouping)
          else
            raise "Patient Pay output configuration must be present to generate Patient Pay output."
          end
        end
      end
    end
  end

  def segregate_gcbs_checks(batch_ids)
    checks = CheckInformation.by_batch(batch_ids)
#    @facility = checks.first.batch.facility
    @zip_type = checks.collect(&:batch).collect(&:correspondence).uniq
    checks = checks.delete_if {|c| c.job.incomplete?}
    check_group = group_gcbs_checks(checks)
    output_group = []
    check_group.each_with_index do |checks, index|
      @nextgen = (index == 0)
      output_group << checks.group_by do |check|
        case payer_type(check)
        when 'insurancepay'
          group_name(check, @ins_grouping)
        when 'patpay', 'notapplicable'
          if @pat_grouping
            group_name(check, @pat_grouping)
          else
            raise "Patient Pay output configuration must be present to generate Patient Pay output."
          end
        end
      end
    end
    output_group[0].merge(output_group[1])
  end

  #This method takes in an array of batchids and return a two dimentional array of checks
  #first dimension represents the object used for grouping, resulting in one output file per element
  #second dimension represents the checks in each output file
  def segregate_supplemental_output(batch_ids)
    checks = CheckInformation.by_batch(batch_ids)
    checks = checks.delete_if {|check| check.job.not_qualified?}
  end
  # Returns the computed group name for a check
  # by applying the grouping passed to it
  # group name also depends on certain other parameters
  # configured for a facility
  def group_name(check, grouping)
    payid = check.payer ? check.payer.supply_payid : nil
    case grouping.downcase.gsub(' ','_')
    when 'by_batch_date'
      "date_#{check.batch.date}_#{correspondence_facet(check)}"
    when 'by_lockbox_cut'
      "lockbox_cut_#{check.batch.lockbox}_#{check.batch.cut}_#{correspondence_facet(check)}"
    when 'by_payer_by_batch'
      if check.payer
        "payer_#{check.batch.id}_#{check.payer.payer}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end
    when 'by_payer_id_by_batch'
      if check.payer
        "payerid_#{check.payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end

    when 'by_cut_and_payerid'
      if check.payer
        "by_cut_and_payerid_#{check.payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end

    when 'by_check'
      "check_#{check.id}_#{check.check_number}_#{correspondence_facet(check)}"
    when 'by_batch'
      "batch_#{check.batch.id }_#{check.batch.batchid}_#{correspondence_facet(check)}_#{check.payment_type}"
    when 'by_cut'
      "cut_#{check.batch.cut }_#{correspondence_facet(check)}"
    when 'by_payer_by_batch_date'
      "date_#{check.batch.date}_payer_#{check.payer.payer}#{correspondence_facet(check)}_#{check.payment_type}"
    when 'by_payer_id_by_batch_date'
      "date_#{check.batch.date}_payer_#{payid}_#{correspondence_facet(check)}_#{check.payment_type}"
    when 'by_output_payer_id_by_batch_date'
      output_payid = check.payer.output_payid(@facility)
      if @client_name == "BARNABAS" && check.job.payer_group == "PatPay"
        "date_#{check.batch.date}_payer_#{output_payid}#{correspondence_facet(check)}_"
      else
        "date_#{check.batch.date}_payer_#{output_payid}#{correspondence_facet(check)}_#{check.payment_type}"
      end
    when 'by_cut_and_extension'
      "cut_ext_#{check.batch.cut}_#{check.batch.correspondence}"
    when "nextgen_grouping"
      "payerid_#{gcbs_payid(check)}_#{correspondence_facet(check)}_#{check.payment_type}"
    end
    
  end

  # Returns the computed group name for a patpay check
  # by applying the grouping passed to it
  # group name also depends on certain other parameters
  # configured for a facility
  def patient_pay_group_name(check, grouping)
    payid = check.payer ? check.payer.supply_payid : nil
    case grouping.downcase.gsub(' ','_')
    when 'by_batch_date'
      "date_#{check.batch.date}_#{correspondence_facet(check)}"
    when 'by_lockbox_cut'
      "lockbox_cut_#{check.batch.lockbox}_#{check.batch.cut}_#{correspondence_facet(check)}"
    when 'by_payer_by_batch'
      if check.payer
        "payer_#{check.batch.id}_#{check.payer.payer}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end
    when 'by_payer_id_by_batch'
      if check.payer
        "payerid_#{check.payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end

    when 'by_cut_and_payerid'
      if check.payer
        "by_cut_and_payerid_#{check.payer.supply_payid}_#{correspondence_facet(check)}"
      else
        raise "Payer is missing for check number: #{check.check_number} id: #{check.id}"
      end

    when 'by_check'
      "check_#{check.id}_#{check.check_number}_#{correspondence_facet(check)}"
    when 'by_batch'
      "batch_#{check.batch.id }_#{check.batch.batchid}_#{correspondence_facet(check)}"
    when 'by_cut'
      "cut_#{check.batch.cut }_#{correspondence_facet(check)}"
    when 'by_payer_by_batch_date'
      "date_#{check.batch.date}_payer_#{check.payer.payer}#{correspondence_facet(check)}"
    when 'by_payer_id_by_batch_date'
      "date_#{check.batch.date}_payer_#{payid}_#{correspondence_facet(check)}"
    when 'by_output_payer_id_by_batch_date'
      output_payid = check.payer.output_payid(@facility)
      "date_#{check.batch.date}_payer_#{output_payid}#{correspondence_facet(check)}"
    when 'by_cut_and_extension'
      "cut_ext_#{check.batch.cut}_#{check.batch.correspondence}"
    when "nextgen_grouping"
      "payerid_#{gcbs_payid(check)}_#{correspondence_facet(check)}"
    end

  end

  # Returns the check type as string, if
  # Combine correspondence and payment is unchecked in FC UI
  # else returns nil.
  # Returns 'notapplicable' for nextgen checks, since those are not configured in FCUI
  def correspondence_facet(check)
    batch = check.batch
    facility = batch.facility
    @insurance_eob_output_config = FacilityOutputConfig.insurance_eob(facility.id).first
    if not check.insurance_payment_eobs.blank?
      payer = check.payer
      job = check.job
      payer_type = job.payer_group if !job.blank?
      if @insurance_eob_output_config.payment_corres_patpay_in_one_file ||
          @insurance_eob_output_config.payment_corres_in_one_patpay_in_separate_file ||
          @insurance_eob_output_config.payment_patpay_in_one_corres_in_separate_file
        output_config = @insurance_eob_output_config
      else
        output_config = facility.output_config(payer_type)
      end
      if output_config.payment_corres_patpay_in_one_file
        'payment'
      elsif output_config.payment_corres_in_one_patpay_in_separate_file
        "#{payer_type(check)}"
      elsif output_config.payment_patpay_in_one_corres_in_separate_file
        check.correspondence? ? 'correspondence' : 'payment'
      elsif !output_config.payment_corres_patpay_in_one_file &&
          !output_config.payment_corres_in_one_patpay_in_separate_file &&
          !output_config.payment_patpay_in_one_corres_in_separate_file
        if payer_type(check) == 'patpay'
          if @client_name == "BARNABAS"
            'payment'
          else
            "#{payer_type(check)}"
          end
        elsif payer_type(check) == 'insurancepay'
          check.correspondence? ? 'correspondence' : 'payment'
        end
      end
    elsif nextgen_check?(check)
      'notapplicable'
    end
  end

  def nextgen_check?(check)
    # EOBs processed in nextgen grid will have no payer
    # they will be stored in patient_pay_eobs table
    # nextgen grid is rendered only when specified so, thru FC UI
    (!check.patient_pay_eobs.blank? &&
        check.batch.facility.patient_pay_format == 'Nextgen Format')
  end

  def payer_type(check)
    if nextgen_check?(check)
      'notapplicable'
    elsif check.payer && check.job.payer_group == 'PatPay'
      'patpay'
    elsif check.payer && check.job.payer_group != 'PatPay'
      'insurancepay'
    end
  rescue NoMethodError
    Output835.log.error "Payer missing for check number : #{check.check_number}, id : #{check.id}"
    raise "Payer is missing for check : #{check.check_number} id : #{check.id}"
  end

  def payer_group_indexed_image(check)
    job = check.job
    if check.correspondence?
      'corr'
    elsif (nextgen_check?(check)) || (check.payer && job.payer_group == 'PatPay' && !check.correspondence?)
      'patpay'
    elsif check.payer && job.payer_group != 'PatPay' && !check.correspondence?
      'insurance'
    end
  rescue NoMethodError
    Output835.log.error "Payer missing for check number : #{check.check_number}, id : #{check.id}"
    raise "Payer is missing for check : #{check.check_number} id : #{check.id}"
  end



  def zip_type
    if @zip_type.count == 2
      @zip_ext_type = "ZIP"
    elsif @zip_type.count == 1 and @zip_type.include?(true)
      @zip_ext_type = "COR"
    else
      if @zip_type.count == 1 and @zip_type.include?(false)
        @zip_ext_type = "PAY"
      end
    end
  end
  # Returns the computed group name for a check to
  # be displayed in supplemental_output
  # by applying the grouping passed to it
  def group_name_supplemental_output(check, grouping)
    case grouping.downcase.gsub(' ','_')
    when 'by_payer'
      if check.micr_line_information
        "payer_#{check.micr_line_information.payer}"
      else
        "payer_#{check.payer.payer}"
      end
    when 'by_correspondence'
      "batch_#{check.correspondence?}"
    when 'by_pat_pay'
      "patpay"
    when 'by_insurance'
      "batch_#{check.batch.date}"
    when 'by_batch'
      "batch_#{check.batch.batchid}"
    end
  end

  def gcbs_payid check
    payer = check.payer
    facility = check.batch.facility
    if nextgen_check?(check)
      "notapplicable"
    elsif payer
      (@nextgen ? "goodman_nextgen_#{payer.gcbs_output_payid(facility)}" : payer.output_payid(facility))
    else
      nil
    end
  end

  def group_gcbs_checks(checks)
    nextgen_checks = checks.select do |check|
      unless check.payer_type == 'patient_pay'
        eobs = check.insurance_payment_eobs
        eobs.any?{|eob| !eob.old_eob_of_goodman?}
      end
    end

    old_checks = checks.select do |check|
      eobs = check.insurance_payment_eobs
      eobs.any?{|eob| eob.old_eob_of_goodman?} || check.nextgen_check? || check.payer_type == 'patient_pay'
    end
    [nextgen_checks, old_checks]
  end


end



