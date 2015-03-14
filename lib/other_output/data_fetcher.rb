module OtherOutput
  
  module DataFetcher
    
    def load_objects image_type
      @image_type  = image_type
      @check_information = image_type.insurance_payment_eob.check_information rescue nil
      @job  = @check_information.job rescue nil
      @batch = @job.batch rescue nil
      @micr = @check_information.check_information rescue nil
      @facility = @batch.facility rescue nil
    end
    
     def method_missing(sym, *args, &block)
       return "#{sym.to_s} method missing .."
     end

    def eval_aba_routing_number 
      @image_type.insurance_payment_eob.check_information.micr_line_information.aba_routing_number rescue nil
    end

     def eval_batch_id
       result = @batch.batchid rescue nil
       result ? result : ""
     end
    
    # # ["ABA Routing Number", "HSCPCS Code", "Image Type", "Line Allowed Amount", "Line Coinsurance Amount", "Line Contractual Amount", "Line Deductible Amount", "Line Denined Amount", "Line Non-Covered Charge", "Line Service Date", "Line Total Charge", "Batch Date", "Lockbox #", "Patient Control Number", "Patient Name", "Payer Name", "Payer Proprietary Adjustment Reason Code", "Raw TIF Image File Name", "Source Batch File Name", "Trace Number", "Batch ID", "Batch Time", "Batch Total Payment Amount", "Batch Type", "Check Account Number", "Check Number", "HIC #"]

    # # {"patient_first_name"=>nil, "insurance_payment_eob_id"=>nil, "patient_account_number"=>nil, "image_type"=>nil, "image_page_number"=>nil, "created_at"=>nil, "updated_at"=>nil, "patient_last_name"=>nil, "images_for_job_id"=>nil}
    
     def eval_hscpcs_code
       "eval_hscps_code"
     end


    def eval_image_type
      result = @image_type.send("image_type") rescue nil
      result ? result : ""
    end
    

    def eval_line_allowed_amount
      "eval_line_allowed_amount"
    end
    
    def eval_line_coinsurance_amount
      "eval_line_coinsurance_amount"
    end

    def eval_line_deductible_amount
      "eval_line_deductible_amount"
    end
    def eval_line_denied_amount
      "eval_line_denied_amount"
    end
    
    def eval_line_noncovered_charge
      "eval_line_noncovered_charge"
    end

    def eval_line_service_date
      "eval_line_service_date"
    end

    def eval_line_total_charge
      "eval_line_total_charge"
    end

    def eval_batch_date
      result = @batch.date rescue nil
      result ? result : ""
    end

    def eval_lockbox
      "eval_lockbox"
    end
    
    def eval_patient_control_number
      "eval_patient_control_number"
    end
    
    def eval_patient_name
      result = ( @image_type.patient_last_name + " " + @image_type.patient_first_name ) rescue nil
      result ? result : ""
    end

    def eval_payer_name
      client_name = @facility.client.name
      check_payer = @check_information.payer
      payer_name = ""
      unless check_payer.nil?
        if check_payer.payer_type.downcase == "patpay" && client_name.downcase != "quadax"
          payer_name = "PATPAY"
        else
          is_micr_payer_present = @micr && @micr.payer && @facility.details[:micr_line_info]
          payer_name = is_micr_payer_present ? @micr.payer.payer : check_payer.payer
        end
      end
      payer_name.blank? ? '-' : payer_name          
    end

    def eval_payer_proprietary_adjustment_reason_code
      "eval_payer_proprietary_adjustment_reason_code"
    end
    
    def eval_raw_tif_image_file_name
      "eval_raw_tif_image_file_name"
    end

    def eval_source_batch_file_name
      "eval_source_batch_file_name"
    end

    def eval_trace_number
      "eval_trace_number"
    end


    def eval_batch_time
      "eval_batch_time"
    end

    def eval_batch_total_payment_amount
      "eval_batch_total_payment_amount"
    end
    
    def eval_batch_type
      "eval_batch_type"
    end
    
    # def eval_check_account_number
    #   result = @micr.payer_account_number rescue nil
    #   result ? result : ""
    # end
    
    def eval_check_number
      @check_information.check_number rescue nil      
    end

    def eval_hic
      "eval_hic"      
    end
    
  end
  
end
