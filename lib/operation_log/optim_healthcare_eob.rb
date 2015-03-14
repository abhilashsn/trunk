module OperationLog
  module OptimHealthcareEob

    def eval_client_code
      eob.client_code || '-'
    end

    def eval_xpeditor_document_number
      return "-" if eob.blank?
      if eob.claim_information && eob.claim_information.xpeditor_document_number
        eob.claim_information.xpeditor_document_number || '-'
      else
        eob.client_code || '-'
      end
    end

  end
end