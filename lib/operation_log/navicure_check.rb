module OperationLog
  module NavicureCheck    
    def eval_image_id
      image_ref = check.job.client_images_to_jobs.first if check.job.client_images_to_jobs.length > 0
      image = image_ref.images_for_job if (image_ref && image_ref.images_for_job)
      image.original_file_name
    end    
  end
end
