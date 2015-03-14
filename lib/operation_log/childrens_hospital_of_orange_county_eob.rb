module OperationLog
  module ChildrensHospitalOfOrangeCountyEob
    def eval_835_amount
      if check.job.job_status == JobStatus::INCOMPLETED
        ""
      else
        total_835_amt = 0
        total_835_amt += eob.total_amount_paid_for_claim.to_f if eob
        total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
      end
    end

    def eval_image_id
      image_name_with_extension(job)
    end

    def eval_patient_account_number
      if check.job.job_status == JobStatus::INCOMPLETED
        ""
      else
        eob.blank? ? '-' : captured_or_blank_patient_account_number(eob.patient_account_number, "op_log")
      end
    end

    def eval_image_page_no
      if check.job.job_status == JobStatus::INCOMPLETED
        ""
      else
        eob.blank? ? '-' : eob.image_page_no
      end
    end

    def eval_patient_last_name
      if check.job.job_status == JobStatus::INCOMPLETED
        ""
      else
        eob.patient_last_name.blank? ? '-' : captured_or_blank_patient_last_name(eob.patient_last_name, "op_log")
      end
    end

    def eval_patient_first_name
      if check.job.job_status == JobStatus::INCOMPLETED
        ""
      else
        eob.patient_first_name.blank? ? '-' : captured_or_blank_patient_first_name(eob.patient_first_name, "op_log")
      end
    end

    def eval_batch_id
      batch = check.batch
      @batchid_array = batch.batchid.split('_') unless batch.batchid.blank?
      @batchid_array[2]
    end

    def eval_deposit_date
      deposit_date = Date.strptime @batchid_array[1], "%y%m%d" unless @batchid_array.blank?
      deposit_date.strftime("%m/%d/%Y")
    end

    def eval_lockbox_id
      batch = check.batch
      lockbox = batch.lockbox
      lockbox ||= '-'
    end

    def eval_sequence
      sequence_number = check.transaction_id
      if config.quote_prefixed and sequence_number
        sequence_number = "'" + sequence_number
      end
      sequence_number
    end

    def eval_account_type
      if check.job.job_status == JobStatus::INCOMPLETED
        "UNIDENTIFIED"
      else
        eob.account_type
      end
    end

  end
end