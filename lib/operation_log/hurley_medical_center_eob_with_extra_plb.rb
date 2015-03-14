module OperationLog
  module HurleyMedicalCenterEobWithExtraPlb
      
    def eval_extra_plb_client_code
      get_hurley_client_code
    end

    def eval_extra_plb_xpeditor_document_number
      eval_extra_plb_client_code
    end

  end
end
