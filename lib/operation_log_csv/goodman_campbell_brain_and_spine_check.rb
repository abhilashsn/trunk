class OperationLogCsv::GoodmanCampbellBrainAndSpineCheck < OperationLogCsv::Check
  
  def image_id
    if operation_log_config.details[:image_id]
      client_images_to_job = check.job.client_images_to_jobs.first if check.job.client_images_to_jobs.length > 0
      image = client_images_to_job.images_for_job if (client_images_to_job && client_images_to_job.images_for_job)
      image.filename
    end
  end
  
end