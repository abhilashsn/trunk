require 'csv'

class OperationLogCsv::Document
  attr_reader :operation_log_config, :batch_ids, :checks, :extension, :facility
  def initialize(facility, batch_ids, checks, extension)
    @extension = extension
    @batch_ids = batch_ids
    @checks = checks
    @facility = facility
    @operation_log_config = FacilityOutputConfig.operation_log(facility.id).first
  end

  # Generate method for CSV creation
  def generate
    csv_string = ""
    is_payer_content_layout = operation_log_config.content_layout.downcase == "by payer"
    is_eob_content_layout = operation_log_config.content_layout.downcase == "by eob"
    csv_string << csv_summary if is_payer_content_layout
    csv_string << csv_header
    csv_string << transactions
    csv_string << csv_summary if is_eob_content_layout
    csv_string unless csv_string.blank?
  end
  def csv_summary
    summary_check_amount = total_check_amount_trailer(checks)
    csv_string = ""
    csv_string << "Summary :" + "\n"
    csv_string << "Total Deposit Amount :" + summary_check_amount.to_s + "\n"
    csv_string << "Total Accepted Amount :" + summary_check_amount(JobStatus::COMPLETED) + "\n"
    csv_string << "Total Rejected Amount :" + summary_check_amount(JobStatus::INCOMPLETED) + "\n\n"
    csv_string unless csv_string.blank?
  end
  
  def summary_check_amount(job_status)
    total_chk_amt = 0
    if operation_log_config.details[:check_amount]
      checks.each do |check|
        if check.job.job_status == job_status
          total_chk_amt += check.check_amount.to_f
        end
      end
      total_chk_amt.to_s
    end
  end

  def csv_sub_total_trailer(check_group, total_type)
    #CSV file column trailers
    type = "trailer"
    if extension == "csv" or extension == "txt"
      delimiter = ','
    elsif extension == "xls"
      delimiter = "\t"
    end
    if (operation_log_config.details[:sub_total] and operation_log_config.content_layout.downcase == "by payer")
      csv_string = [sub_total_trailer(check_group, total_type),deposit_date(type),export_date(type),check_serial_number(type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),check_amount(type),total_check_amount_trailer(check_group),total_eft_amount_trailer(check_group),total_835_amount_trailer(check_group),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type)].flatten.compact.join("#{delimiter}") + "\n"
    else
      csv_string = [sub_total_trailer(check_group, total_type),deposit_date(type),export_date(type),check_serial_number(type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),total_check_amount_trailer(check_group),total_eft_amount_trailer(check_group),total_835_amount_trailer(check_group),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type)].flatten.compact.join("#{delimiter}") + "\n"
    end
    csv_string unless csv_string.blank?
  end

  def sub_total_trailer(check_group,total_type)
    proc_comment = check_group.first.job.processor_comments
    ( era = proc_comment.include?("ERA") ) if !proc_comment.blank?
    if operation_log_config.details[:check_amount]
      if (total_type == "sub total" && check_group.first.payer && check_group.first.payer.payer_type == "PatPay")
        "Total for Self pay : 835 format"
      elsif (total_type == "sub total" && check_group.first.payer.blank? && check_group.first.patient_pay_eobs)
        "Total for Self pay : NextGen format"
      elsif total_type == "sub total" && era
        "Total for #{check_group.first.payer.payer}(ERA Available)"
      elsif total_type == "sub total"
        "Total for #{check_group.first.payer.payer}"
      end
    end
  end

  def csv_header
    type = "header"
    if extension == "csv" or extension == "txt"
      delimiter = ','
    elsif extension == "xls"
      delimiter = "\t"
    end
    if (operation_log_config.details[:sub_total] and operation_log_config.content_layout.downcase == "by payer")
     if checks.first.batch.client.name.upcase == "QUADAX"
       csv_header_string = [batch_name(type),deposit_date(type),export_date(type),check_serial_number(type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),check_amount(type),sub_total(type),eft_amount(type),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type),amount_835(type)].flatten.compact.join("#{delimiter}") + "\n"
     else
       csv_header_string = [batch_name(type),deposit_date(type),export_date(type),check_serial_number(type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),check_amount(type),sub_total(type),eft_amount(type),amount_835(type),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type)].flatten.compact.join("#{delimiter}") + "\n"
     end
    else
     if checks.first.batch.client.name.upcase == "QUADAX"
       csv_header_string = [batch_name(type),deposit_date(type),export_date(type),check_serial_number(type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),check_amount(type),eft_amount(type),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type),amount_835(type)].flatten.compact.join("#{delimiter}") + "\n"
     else
       csv_header_string = [batch_name(type),deposit_date(type),export_date(type),check_serial_number(type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),check_amount(type),eft_amount(type),amount_835(type),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type)].flatten.compact.join("#{delimiter}") + "\n"
     end
    end
    csv_header_string unless csv_header_string.blank?
  end

  def batch_name(type)
    if operation_log_config.details[:batch_name]
      type == "header" ? "Batch Name" : ""
    end
  end

  def export_date(type)
    if operation_log_config.details[:export_date]
      type == "header" ? "Export Date" : ""
    end
  end

  def check_serial_number(type)
    if operation_log_config.details[:check_serial_number]
      type == "header" ? "Check" : ""
    end
  end

  def check_number(type)
    if operation_log_config.details[:check_number]
      type == "header" ? "Check Number" : ""
    end
  end

  def check_amount(type)
    if operation_log_config.details[:check_amount]
      type == "header" ? "Check Amount" : ""
    end
  end

  def eft_amount(type)
    if operation_log_config.details[:eft_amount]
      type == "header" ? "Eft Amount" : ""
    end
  end

  def payer_name(type)
    if operation_log_config.details[:payer_name]
      type == "header" ? "Payer Name" : ""
    end
  end

  def status(type)
    if operation_log_config.details[:status]
      type == "header" ? "Status" : ""
    end
  end

  def image_id(type)
    if operation_log_config.details[:image_id]
      type == "header" ? "Image Id" : ""
    end
  end

  def reject_reason(type)
    if operation_log_config.details[:reject_reason]
      type == "header" ? "Reject Reason" : ""
    end
  end

  def amount_835(type)
    if operation_log_config.details[:amount_835]
      type == "header" ? "835 Amount" : ""
    end
  end

  def deposit_date(type)
    if operation_log_config.details[:deposit_date]
      type == "header" ? "Deposit Date" : ""
    end
  end

  def aba_routing_number(type)
    if operation_log_config.details[:aba_routing_number]
      type == "header" ? "Aba Routing Number" : ""
    end
  end

  def payer_account_number(type)
    if operation_log_config.details[:payer_account_number]
      type == "header" ? "Payer Account Number" : ""
    end
  end
  def sub_total(type)
    if operation_log_config.details[:sub_total]
      type == "header" ? "Sub Total" : ""
    end
  end
 
  def check_date(type)
    if operation_log_config.details[:check_date]
      type == "header" ? "Check Date" : ""
    end
  end

  def zip_file_name(type)
    if operation_log_config.details[:file_zip_name]
      type == "header" ? "Zip File Name" : ""
    end
  end

  def patient_account_number(type)
    if operation_log_config.details[:patient_account_number]
      type == "header" ? "Patient Account Number" : ""
    end
  end

  def page_no(type)
    if operation_log_config.details[:page_no]
      type == "header" ? "Image Page No" : ""
    end
  end  

  def onbase_name(type)
    if operation_log_config.details[:onbase_name]
      type == "header" ? "OnBase Name" : ""
    end
  end 
  
  def correspondence(type)
    if operation_log_config.details[:correspondence]
      type == "header" ? "Correspondence" : ""
    end
  end

  def statement_number(type)
     if operation_log_config.details[:statement_number]
      type == "header" ? "Statement #" : ""
     end
  end
  
  def harp_source(type)
    if operation_log_config.details[:harp_source]
      type == "header" ? "Harp Source" : ""
    end
  end  
  
  # Method to create the Trailer for CSV file
  def csv_trailer(batch_wise_checks, total_type)
    #CSV file column trailers
    type = "trailer"
    if extension == "csv" or extension == "txt"
      delimiter = ','
    elsif extension == "xls"
      delimiter = "\t"
    end
    if @checks.first.batch.client.name.upcase == "QUADAX"
      csv_string = [batch_name(type),deposit_date(type),export_date(type),total_trailer(batch_wise_checks, total_type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),total_check_amount_trailer(batch_wise_checks),total_eft_amount_trailer(batch_wise_checks),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type),total_835_amount_trailer(batch_wise_checks)].flatten.compact.join("#{delimiter}") + "\n"
    else
      csv_string = [batch_name(type),deposit_date(type),export_date(type),total_trailer(batch_wise_checks, total_type),aba_routing_number(type),payer_account_number(type),check_number(type),check_date(type),patient_account_number(type),page_no(type),total_check_amount_trailer(batch_wise_checks),total_eft_amount_trailer(batch_wise_checks),total_835_amount_trailer(batch_wise_checks),payer_name(type),status(type),image_id(type),zip_file_name(type),reject_reason(type),onbase_name(type),correspondence(type), statement_number(type), harp_source(type)].flatten.compact.join("#{delimiter}") + "\n"
    end
    csv_string unless csv_string.blank?
  end
  
  def total_trailer(batch_wise_checks, total_type)
    if operation_log_config.details[:check_amount]
      facility_array = ["ATLANTA AESTHETIC SURGERY CENTER","PEACHTREE SURGICAL AND BARIATRICS","REAL RESULTS WEIGHT LOSS SOLUTIONS"]
      check = batch_wise_checks.first
      unless check.nil?
        if facility_array.include?(facility.name.upcase)
          total_type == "grand total" ? "GRAND TOTAL FOR BATCH - #{batch_wise_checks.first.batch.batchid}" : "SUB TOTAL"
        else
          total_type == "grand total" ? "GRAND TOTAL FOR BATCH - #{batch_wise_checks.first.batch.batchid.split("_")[0..-2].join("_")}" : "SUB TOTAL"
        end
      end
    end
  end

  def total_check_amount_trailer(checks)
    if operation_log_config.details[:check_amount]
      total_chk_amt = 0
      checks.each do |check|
        check.check_amount.to_f
        total_chk_amt += check.check_amount.to_f
      end
      total_chk_amt 
    end
  end

  def total_eft_amount_trailer(checks)
    total_eft_amt = 0
    if operation_log_config.details[:eft_amount]
      checks.each do |check|
        if check.check_number == "0"
          total_eft_amt += check.check_amount.to_f
        end
      end
      total_eft_amt
    end
  end

  def total_835_amount_trailer(checks)
    net_835_amt = 0
    if operation_log_config.details[:amount_835]
      checks.each do |check|
        total_835_amt = 0
        check.insurance_payment_eobs.each do |ins_pay_eob|
          total_835_amt += ins_pay_eob.total_amount_paid_for_claim.to_f
          total_835_amt += ins_pay_eob.late_filing_charge.to_f
          if facility.details[:interest_in_service_line].blank?
            total_835_amt += ins_pay_eob.claim_interest.to_f
          end
        end
        unless operation_log_config.content_layout.downcase == "by eob"
          total_835_amt += check.provider_adjustment_amount.to_f
        end        
        net_835_amt += total_835_amt.to_f
      end
      sprintf("%.2f", net_835_amt)
    end
  end


  # Wrapper for each record in the supplemental output file.
  def transactions
    index = 0
    csv_string = ""
    check_segregator = CheckSegregator.new('', '')
    content_layout = operation_log_config.content_layout.downcase
    if content_layout == "by check"
      batch_ids.each do |batch_id|
        checks = check_segregator.segregate_supplemental_output(batch_id)
        checks.each_with_index do |check, index|
          index += 1
          check_klass = OperationLogCsv.class_for("Check", facility)
          check_obj = check_klass.new(check, facility, index, extension)
          csv_string += check_obj.generate
        end
        csv_string << csv_trailer(checks, "grand total")
      end
    elsif content_layout == "by payer"
      batch_ids.each do |batch_id|
        checks = check_segregator.segregate_supplemental_output(batch_id)
        check_groups = group_checks(checks)
        puts "Grouping successful, returned #{check_groups.length} distinct group/s"
        check_groups.each do |group, check_group|
          check_group.each do |check|
            index += 1
            check_klass = OperationLogCsv.class_for("Check", facility)
            check_obj = check_klass.new(check, facility, index, extension)
            csv_string += check_obj.generate
          end
          csv_string << csv_sub_total_trailer(check_group, "sub total")
        end
        csv_string << csv_trailer(checks, "grand total")
      end
      
    elsif content_layout == "by eob"
      batch_ids.each do |batch_id|
        checks = check_segregator.segregate_supplemental_output(batch_id)
        checks.each_with_index do |check, index|
          insurance_payment_eobs = check.insurance_payment_eobs
          insurance_payment_eobs_sorted = insurance_payment_eobs.sort_by {|ins_payment_eob| ins_payment_eob.image_page_no}
          insurance_payment_eobs_sorted.each do |eob|
            eob_klass = OperationLogCsv.class_for("Eob", facility)
            eob_obj = eob_klass.new(eob, check, facility, index, extension)
            csv_string += eob_obj.generate
          end
        end
        csv_string << csv_trailer(checks, "grand total")
      end
    end
    csv_string unless csv_string.blank?
  end
  
  # Returns checkgroups of the checks to 
  # be displayed in supplemental_output
  # by applying the group_name.
  def group_checks(checks)
    check_segregator = CheckSegregator.new('by_payer', 'by_payer_type')
    checks.group_by do |check|
      if check_segregator.payer_type(check) == 'insurancepay'
        check_segregator.group_name_supplemental_output(check, 'by_payer')
      elsif check_segregator.payer_type(check) == 'patpay'
        check_segregator.group_name_supplemental_output(check, 'by_payer_type')
      elsif check.patient_pay_eobs
        check_segregator.group_name_supplemental_output(check, 'by_next_gen')
      end
    end
  end
end
