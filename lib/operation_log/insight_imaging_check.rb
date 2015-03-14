module OperationLog
  module InsightImagingCheck

    def eval_batch_name
      check.batch.batchid.blank? ? "-" : check.batch.batchid.split("_")[0..-2].join("_")  
    end

    def eval_payer_name
      is_micr_payer_present = check.micr_line_information && check.micr_line_information.payer && check.batch.facility.details[:micr_line_info]
      if (is_micr_payer_present && check.patient_pay_eobs.size == 0)
        payer = check.micr_line_information.payer
      elsif (check.micr_line_information.blank? && check.patient_pay_eobs.blank?) || (check.micr_line_information.present? && check.micr_line_information.payer.blank? && check.patient_pay_eobs.blank?)
        payer = check.payer
      elsif check.patient_pay_eobs.size > 0
        if check.patient_pay_eobs.first.patient_middle_initial.blank?
          payer = check.patient_pay_eobs.first.patient_first_name + " " + check.patient_pay_eobs.first.patient_last_name
        else
          payer = check.patient_pay_eobs.first.patient_first_name + " " + check.patient_pay_eobs.first.patient_middle_initial + " " + check.patient_pay_eobs.first.patient_last_name
        end
      end
      payer.blank? ? "-" : payer
    end    
    
  end
end
