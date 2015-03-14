class OperationLogCsv::HorizonLaboratoryLlcEob < OperationLogCsv::QuadaxEob
  
  def image_id
    if operation_log_config.details[:image_id]
      client_images_to_jobs = check.job.client_images_to_jobs
      image_id = ""
      client_images_to_jobs.each do |client_images_to_job|
        images_for_jobs = ImagesForJob.find(:all, :conditions => ["id = ?", client_images_to_job.images_for_job_id])
        images_for_jobs.each do |images_for_job|
          if images_for_job.filename.include?('.tif') or images_for_job.filename.include?('.TIF')
            image_id << images_for_job.filename + ";"
          else
            image_id << images_for_job.filename + '.tif' + ";"
          end
         end
      end
      image_id_name = image_id.chop
      image_id_name.blank? ? "-" : image_id_name
    end
  end
   
end