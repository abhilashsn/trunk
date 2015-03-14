module OperationLog
  module HurleyMedicalCenterEob
     
    def eval_client_code
      get_hurley_client_code
    end

    def eval_xpeditor_document_number
      eval_client_code
    end
    
  end
end
