module OperationLog
  module OptimHealthcareEobWithPlb

    def eval_plb_client_code
      eob.client_code || '-'
    end

    def eval_plb_xpeditor_document_number
      return "-" if eob.blank?
      eob.client_code || '-'
    end

  end
end