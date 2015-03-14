module OperationLog
  module AlbertEinsteinCollegeOfMedicineEob
    def eval_image_id
      job = check.job
      initial_image_name = job.initial_image_name unless job.initial_image_name.blank?
    end
  end
end