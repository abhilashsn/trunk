module OperationLog
  module PartnersInInternalMedicineCheck
    def eval_image_id
      if check.correspondence?
        job = check.job
        image_file_name = job.initial_image_name unless job.initial_image_name.blank?
      else
        images_for_jobs = check.job.images_for_jobs
        unless images_for_jobs.blank?
          images_for_job =  images_for_jobs.select{|images_for_job|
            images_for_job.image_file_name = images_for_job.exact_file_name
            images_for_job.is_check_image_type?}.map(&:image_file_name)
          image_file_name = images_for_job[0]
        end
      end
      image_file_name.blank? ? '-' : image_file_name
    end
  end
end


