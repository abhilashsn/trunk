#Represents an 835 document with single ST/SE loop
class Output835::SingleStDocument < Output835::Document
  # Wrapper for each check in this 835
  def transactions
    segments = []
    check_nums = checks.collect{|check| check.check_number}
    check_klass = Output835.class_for("SingleStCheck", facility)
    Output835.log.info "Applying class #{check_klass}"
    check = check_klass.new(checks, facility, nil, @element_seperator,check_nums)
    check.instance_variable_set("@plb_excel_sheet", @plb_excel_sheet)
    segments += check.generate
    segments
  end

  #  If grouping is 'By Check',returns Payer id from Payer table
  #  If grouping is 'By Payer',returns Payer id from Payer table for Insurance eobs
  #  and Patpay payer Id from FC UI for PatPay eobs.
  #  If grouping is 'By Batch', 'By Batch Date',returns commercial payer Id from FC UI
  #  for Insurance eobs and Patpay payer Id from FC UI for PatPay eobs.
  def payer_id
    payer_of_first_check = checks.first.payer
    job = checks.first.job
    payer_type = job.payer_group if !job.blank?
    output_config = facility.output_config(payer_type)
    case output_config.grouping
    when 'By Check'
      payer_of_first_check.supply_payid if payer_of_first_check
    when 'By Payer','By Payer Id'
      payer_wise_payer_id(output_config)
    when 'By Batch', 'By Batch Date', 'By Cut'
      generic_payer_id(output_config)
    end
  end

  # The use of identical data interchange control numbers in the associated
  # functional group header and trailer is designed to maximize functional
  # group integrity. The control number is the same as that used in the
  # corresponding header.
  def functional_group_trailer(batch_id)
    ge_elements = []
    ge_elements << 'GE'
    ge_elements << '0001'
    ge_elements << '2831'
    ge_elements.join(@element_seperator)
  end

  protected

  def generic_payer_id(output_config)
    case output_config.eob_type
    when 'Insurance EOB'
      if facility.commercial_payerid
        facility.commercial_payerid
      else
        raise "Commercial Payer ID must be configured to generate Single ST 835 for Insurance EOBs"
      end
    when 'Patient Payment'
      if facility.patient_payerid
        facility.patient_payerid
      else
        raise "Patient Payer ID must be configured to generate Single ST 835 for Patient EOBs"
      end
    end
  end

  def payer_wise_payer_id(output_config)
    case output_config.eob_type
    when 'Insurance EOB'
      checks.first.payer.supply_payid if checks.first.payer
    when 'Patient Payment'
      if facility.patient_payerid
        facility.patient_payerid
      else
        raise "Patient Payer ID must be configured to generate Single ST 835 for Patient EOBs"
      end
    end
  end

end