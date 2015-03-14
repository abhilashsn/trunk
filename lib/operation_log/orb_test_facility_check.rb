module OperationLog
  module OrbTestFacilityCheck

    def eval_payer_name
      payer_name = check.client_specific_payer_name(facility)
      if payer_name.blank?
        payer_name = get_payer_name
      end
      payer_name.blank? ? '-' : payer_name
    end
    
  end
end
