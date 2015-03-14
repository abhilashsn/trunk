module OperationLog
  module NlfhOutreachLaboratoryCheck
    def eval_image_id
      check.get_actual_image_file_name_with_extn
    end
  end
end
