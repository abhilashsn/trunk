class OperationLogCsv::MeritMountainsideCheck < OperationLogCsv::Check
  
  def image_id
    if operation_log_config.details[:image_id]
      image_ref = check.job.client_images_to_jobs.first if check.job.client_images_to_jobs.length > 0
      images_for_job_ref = image_ref.images_for_job if (image_ref && image_ref.images_for_job)
      image_file_name = images_for_job_ref.filename
      image_file_name_last_part = image_file_name.split("_").last
      original_image_file_name = image_file_name.chomp(image_file_name_last_part).chop.concat('.tif')
      original_image_file_name
    end
  end
  
end