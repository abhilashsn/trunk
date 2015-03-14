class OperationLogCsv::Check
  attr_reader :check, :index, :operation_log_config, :extension, :facility, :micr
  
  def initialize(check, facility, index, extension)
    @extension = extension
    @check = check
    @index = index
    @micr = check.micr_line_information
    @facility = facility
    @operation_log_config = FacilityOutputConfig.operation_log(facility.id).first
  end

  # Generate Method to invoke the Content for CSV file
  def generate
    csv_string =""
    csv_string << csv_content
    csv_string unless csv_string.blank?
  end

  # Method to create the content for CSV file
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

  def batch_name
    if operation_log_config.details[:batch_name]
      batch = check.batch
      batch.batchid.blank? ? "-" : batch.real_batch_id
    end
  end

  def export_date
    if operation_log_config.details[:export_date]
      Time.now.strftime('%m/%d/%Y')
    end
  end

  def check_serial_number
    if operation_log_config.details[:check_serial_number]
      index
    end
  end

  def check_number
    if operation_log_config.details[:check_number]
      chk_number = check.check_number.blank? ? "-" : check.check_number
      if operation_log_config.quotes_configuration and check.check_number
        chk_number = "'"+chk_number
      end
      chk_number
    end
  end

  def check_amount
    if operation_log_config.details[:check_amount]
      if operation_log_config.details[:eft_amount]
        if check.check_number == "0"
          check_amount = "-"
        else
          check_amount = check.check_amount
        end
      else
        check_amount = check.check_amount
      end
      check_amount.blank? ? "-" : check_amount
    end
  end

  def eft_amount
    if operation_log_config.details[:eft_amount]
      if check.check_number == "0"
        eft_amount = check.check_amount
      else
        eft_amount = "-"
      end
      eft_amount.blank? ? "-" : eft_amount
    end
  end

  def payer_name
    if operation_log_config.details[:payer_name]
      client_name = facility.client.name
      check_payer = check.payer
      unless check_payer.nil?
        if check_payer.payer_type.downcase == "patpay" && client_name.downcase != "quadax"
          payer_name = "PATPAY"
        else
          is_micr_payer_present = micr && micr.payer && facility.details[:micr_line_info]
          payer_name = is_micr_payer_present ? micr.payer.payer : check_payer.payer
        end
      end
      payer_name.blank? ? '-' : payer_name
    end
  end

  def status
    if operation_log_config.details[:status]
      if check.job.job_status == JobStatus::COMPLETED
        status = "Accept"
      elsif check.job.job_status == JobStatus::INCOMPLETED
        status = "Reject"
      else
        status = "-"
      end
      status
    end
  end

  def image_id
    if operation_log_config.details[:image_id]
      client_images_to_jobs = check.job.client_images_to_jobs
      image_id = ""
      client_images_to_jobs.each do |client_images_to_job|
        images_for_jobs = ImagesForJob.find(:all, :conditions => ["id = ?", client_images_to_job.images_for_job_id])
        images_for_jobs.each do |images_for_job|
          image_id << images_for_job.filename + ";"
        end
      end
      image_id_name = image_id.chop
      image_id_name.blank? ? "-" : image_id_name
    end
  end

  def reject_reason
    if operation_log_config.details[:reject_reason]
      if check.job.processor_comments != "null" and !check.job.processor_comments.blank? and (check.job.job_status == JobStatus::INCOMPLETED or check.job.job_status == JobStatus::COMPLETED)
        reject_reason = check.job.processor_comments.strip
      else
        reject_reason = "-"
      end
      reject_reason
    end
  end

  def amount_835
    if operation_log_config.details[:amount_835]
      total_835_amt = 0
      check.insurance_payment_eobs.each do |ins_pay_eob|
        total_835_amt += ins_pay_eob.total_amount_paid_for_claim.to_f
        total_835_amt += ins_pay_eob.late_filing_charge.to_f
        if facility.details[:interest_in_service_line].blank?
          total_835_amt += ins_pay_eob.claim_interest.to_f
        end
      end
      total_835_amt += check.provider_adjustment_amount.to_f
      total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
    end
  end

  def deposit_date
    if operation_log_config.details[:deposit_date]
      check.batch.bank_deposit_date.blank? ? "-" : check.batch.bank_deposit_date.strftime("%m/%d/%Y")
    end
  end

  def aba_routing_number
    if operation_log_config.details[:aba_routing_number]
      unless micr.blank?
        routing_number = micr.aba_routing_number.blank? ? "-" : micr.aba_routing_number
        if operation_log_config.quotes_configuration and micr.aba_routing_number
          routing_number = "'" + routing_number
        end
        routing_number
      else
        "-"
      end
    end
  end

  def payer_account_number
    if operation_log_config.details[:payer_account_number]
      unless micr.blank?
        account_number = micr.payer_account_number.blank? ? "-" : micr.payer_account_number
        if operation_log_config.quotes_configuration and micr.payer_account_number
          account_number = "'" + account_number
        end
        account_number
      else
        "-"
      end
    end
  end

  def check_date
    if operation_log_config.details[:check_date]
      check.check_date.blank? ? "-" : check.check_date.strftime("%m/%d/%Y")
    end
  end

  def zip_file_name
    if operation_log_config.details[:file_zip_name]
      check.batch.file_name.blank? ? "-" : check.batch.file_name
    end
  end

  def patient_account_number
    if operation_log_config.details[:patient_account_number]
      "-"
    end
  end

  def page_no
    if operation_log_config.details[:page_no]
      "-"
    end
  end

  def sub_total
    if operation_log_config.details[:sub_total]
      ""
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