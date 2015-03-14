module OperationLogHelper

  def get_operation_log_checks(job_status_grouping, batch_id)
    if job_status_grouping == "Completed Jobs"
      all_checks = CheckInformation.get_completed_checks(batch_id)
    elsif job_status_grouping == "Incompleted Jobs"
      all_checks = CheckInformation.get_exception_checks(batch_id)
    else
      all_checks = CheckInformation.get_qualified_checks(batch_id)
    end
    all_checks
  end

  def get_batch_ids(client, config, pivot_batch_id)
    if client.supplemental_outputs && client.supplemental_outputs.include?("Operation Log")
      if config.by_client_and_deposit_date || config.for_date
        batches = Batch.client_and_deposit_date_group_for_client_level(Batch.find(pivot_batch_id))
      else
        batches = [Batch.find(pivot_batch_id)]
      end
    else
      if config.for_date
        batches = Batch.by_batch_date(Batch.find(pivot_batch_id))
      else
        batches = [Batch.find(pivot_batch_id)]
      end
    end
    batches
  end

  def image_name_with_extension(job)
    final_image_file_name = ""
    image_file_name = job.initial_image_name unless job.initial_image_name.blank?
    if File.extname(image_file_name.upcase) == ".TIF" || File.extname(image_file_name.upcase) == ".TIFF"
      final_image_file_name = image_file_name
    else
      final_image_file_name = image_file_name + ".tiff"
    end
    final_image_file_name.blank? ? "-" : final_image_file_name
  end

  def get_hurley_client_code
    client_code =  "-"
    if (!eob.blank? && !eob.patient_account_number.blank?)
      account_number = eob.patient_account_number
      if account_number.start_with?("P")
        client_code = "7HXP"
      elsif account_number.start_with?("H")
        client_code = "HUXP"
      elsif account_number.include? "CH"
        client_code = "7HXP"
      else
        client_code = "HUXP"
      end
    end
    client_code
  end

  def get_multipage_image_name(batch, check, eob)
    batch_date = batch.date
    if !eob.account_type.blank?
      "#{batch.lockbox}_#{batch_date.strftime("%Y%m%d")}_#{check.check_number}_#{eob.account_type}.tif"
    else
      "#{batch.lockbox}_#{batch_date.strftime("%Y%m%d")}_#{check.check_number}.tif"
    end
  end

end