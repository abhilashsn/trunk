module OperationLog::DataFetcherEobWithExtraPlb
  
  def eval_extra_plb_patient_last_name
      if eob
        patient_last_name = 'L6'
      end
      patient_last_name.blank? ? '-' : patient_last_name
    end

    def eval_extra_plb_patient_first_name
      if eob
        patient_first_name = 'INTEREST OWED'
      end
      patient_first_name.blank? ? '-' : patient_first_name
    end

    def eval_extra_plb_835_amount
      total_835_amt = 0
      if eob
        total_835_amt += eob.claim_interest.to_f
      end
      total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
    end

    def eval_extra_plb_xpeditor_document_number
      'OOXP'
    end

    def eval_extra_plb_client_code
      'OOXP'
    end

    def eval_extra_plb_total_charge
      "-"
    end

    def eval_extra_plb_date_of_service
      "-"
    end

    def eval_extra_plb_reject_reason
      "-"
    end

    def eval_extra_plb_statement__
      "-"
    end

    def eval_extra_plb_reason_not_processed
      "-"
    end

    def eval_extra_plb_member_id
      "-"
    end

    def eval_extra_plb_patient_date_of_birth
      "-"
    end

    def eval_extra_plb_837_file_type
      "-"
    end

    def eval_extra_plb_plb
     "Yes"
    end

    def eval_extra_plb_unique_identifier
      "-"
    end
end
