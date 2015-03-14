module OperationLog
  module HurleyMedicalCenterEobWithPlb
      
    def eval_plb_client_code
      get_hurley_client_code
    end

    def eval_plb_xpeditor_document_number
      eval_plb_client_code
    end
    
  end
end
