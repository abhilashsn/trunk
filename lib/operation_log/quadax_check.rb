module OperationLog
  module QuadaxCheck

    def eval_image_id
      final_image_file_name = ""
      job = check.job
      image_file_name = job.initial_image_name unless job.initial_image_name.blank?
      if File.extname(image_file_name.upcase) == ".TIF" || File.extname(image_file_name.upcase) == ".TIFF"
        final_image_file_name = image_file_name
      else
        final_image_file_name = image_file_name + ".tiff"
      end
      final_image_file_name.blank? ? "-" : final_image_file_name
    end

    def eval_837_file_type
      if eob && eob.claim_information && eob.claim_information.claim_file_information
        claim_file_type = eob.claim_information.claim_file_information.claim_file_type
      end
      claim_file_type.blank? ? '-' : claim_file_type
    end

  end
end
