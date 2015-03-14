class OperationLogCsv::Eob < OperationLogCsv::Check
  attr_reader :eob, :check, :index, :operation_log_config, :extension, :facility, :micr
  def initialize(eob, check, facility, index, extension)
    @extension = extension
    @check = check
    @index = index + 1
    @eob = eob
    @micr = check.micr_line_information
    @facility = facility
    @operation_log_config = FacilityOutputConfig.operation_log(facility.id).first
  end
  
  def generate
    csv_content_string = ""
    csv_content_string << csv_content
  end

  def csv_content
    if extension == "csv" or extension == "txt"
      delimiter = ','
    elsif extension == "xls"
      delimiter = "\t"
    end
    if (operation_log_config.details[:sub_total] and operation_log_config.content_layout.downcase == "by payer")
     if check.batch.client.name.upcase == "QUADAX"
      csv_content_string = [batch_name,deposit_date,export_date,check_serial_number,aba_routing_number,payer_account_number,check_number,check_date,patient_account_number,page_no,check_amount,sub_total,eft_amount,payer_name,status,image_id,zip_file_name,reject_reason, onbase_name, correspondence, statement_number, harp_source,amount_835].flatten.compact.join("#{delimiter}") + "\n"
     else
      csv_content_string = [batch_name,deposit_date,export_date,check_serial_number,aba_routing_number,payer_account_number,check_number,check_date,patient_account_number,page_no,check_amount,sub_total,eft_amount,amount_835,payer_name,status,image_id,zip_file_name,reject_reason, onbase_name, correspondence, statement_number, harp_source].flatten.compact.join("#{delimiter}") + "\n"
     end
    else
     if check.batch.client.name.upcase == "QUADAX"
       csv_content_string = [batch_name,deposit_date,export_date,check_serial_number,aba_routing_number,payer_account_number,check_number,check_date,patient_account_number,page_no,check_amount,eft_amount,payer_name,status,image_id,zip_file_name,reject_reason, onbase_name, correspondence, statement_number, harp_source,amount_835].flatten.compact.join("#{delimiter}") + "\n"
     else
       csv_content_string = [batch_name,deposit_date,export_date,check_serial_number,aba_routing_number,payer_account_number,check_number,check_date,patient_account_number,page_no,check_amount,eft_amount,amount_835,payer_name,status,image_id,zip_file_name,reject_reason, onbase_name, correspondence, statement_number, harp_source].flatten.compact.join("#{delimiter}") + "\n"
     end
    end
    csv_content_string unless csv_content_string.blank?
  end

  def patient_account_number
    if operation_log_config.details[:patient_account_number]
      account_number = eob.blank? ? "-" : eob.patient_account_number
      if operation_log_config.quotes_configuration and eob.patient_account_number
        account_number = "'" + account_number
      end
      account_number
    end
  end

  def page_no
    if operation_log_config.details[:page_no]
      eob.blank? ? "-" : eob.image_page_no
    end
  end
  
  def onbase_name
    if operation_log_config.details[:onbase_name]
      "-"
    end
  end
  
  def correspondence
    if operation_log_config.details[:correspondence]
      "-"
    end
  end
  
  def sub_total
    if operation_log_config.details[:sub_total]
      ""

    end
  end

  def amount_835
    if operation_log_config.details[:amount_835]
      total_835_amt = 0
      total_835_amt += eob.late_filing_charge.to_f
      total_835_amt += eob.total_amount_paid_for_claim.to_f
      if facility.details[:interest_in_service_line].blank?
        total_835_amt += eob.claim_interest.to_f
      end
      total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
    end
  end
  
  def statement_number
    if operation_log_config.details[:statement_number]
      "-"
    end
  end
  
  def harp_source
    if operation_log_config.details[:harp_source]
      "-"
    end
  end

end