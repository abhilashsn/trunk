module OtherOutput
  module DataFetcherA37    
    def load_objects image_type
      @image_type  = image_type
      @insurance_payment_eob = @image_type.insurance_payment_eob 
      @images_for_job = @image_type.images_for_job 
      @service_payment_eobs = @insurance_payment_eob.service_payment_eobs  if @insurance_payment_eob
      @check_information = @insurance_payment_eob.check_information  if @insurance_payment_eob
      @job  = @check_information.job if @check_information
      @batch = @job.batch if @job
      @micr = @check_information.micr_line_information if @check_information
      @payer = @micr.payer if @micr_line_information
      @payer = @check_information.payer if ! @payer && @check_information
      @facility = @batch.facility if @batch
      @rcc = ReasonCodeCrosswalk.new(@payer, nil, @facility.client, @facility)
    end
    
    def method_missing(sym, *args, &block)
      return "#{sym.to_s} method missing .."
    end

    def eval_hcpcs_code
      #@service_payment_eobs.present? ? @service_payment_eobs.first.service_procedure_code : ""
      @service_payment_eob.present? ? @service_payment_eob.service_procedure_code : ""
    end
    
    def eval_claim_payment_amt
      ServicePaymentEob.sum_attribute("service_paid_amount", @insurance_payment_eob.id) #
    end
    
    def eval_lockbox_number
      @batch ? @batch.lockbox : ""
    end
    
    def eval_line_total_charge
      ServicePaymentEob.sum_attribute("service_procedure_charge_amount", @insurance_payment_eob.id)
    end
    
    def eval_client_data_file
      @batch.output_activity_logs.first.file_name rescue nil      
    end

    def eval_patient_first_name
      @insurance_payment_eob ? @insurance_payment_eob.patient_first_name : ""
    end
    
    def eval_patient_control_number
      @insurance_payment_eob ? @insurance_payment_eob.patient_account_number : ""
    end

    def eval_financial_class
      if @insurance_payment_eob && @insurance_payment_eob.claim_information
        @insurance_payment_eob.claim_information.business_unit_indicator
      else
        ""
      end
    end

    def eval_patient_last_name
      @insurance_payment_eob ? @insurance_payment_eob.patient_last_name : ""
    end

    def eval_payer_name
      client_name = @facility.client.name
      check_payer = @check_information.payer
      payer_name = ""
      unless check_payer.nil?
        if check_payer.payer_type && check_payer.payer_type.downcase == "patpay" && client_name && client_name.downcase != "quadax"
          payer_name = "PATPAY"
        else
          is_micr_payer_present = @micr && @micr.payer && @facility.details[:micr_line_info]
          payer_name = is_micr_payer_present ? @micr.payer.payer : check_payer.payer
        end
      end
      payer_name.blank? ? '-' : payer_name          
    end

    def eval_patient_number
      @insurance_payment_eob ? @insurance_payment_eob.patient_account_number : ""
    end


    def eval_payer_proprietary_adjustment_reason_code
      if @facility && @facility.details["claim_level_eob"] == true
        rslt = @rcc.get_all_codes_for_entity(@insurance_payment_eob, true) if @insurance_payment_eob.present?
        reason_codes = @insurance_payment_eob.present?   ?  rslt[:primary_reason_codes].join(';') : ""
      else
        rslt = @rcc.get_all_codes_for_entity(@service_payment_eob, true) if @service_payment_eob.present?
        reason_codes = @service_payment_eob.present?   ?  rslt[:primary_reason_codes].join(';') : ""
      end
      reason_codes
    end

    def eval_reason_code
      secondary_codes = ""
      if @facility && @facility.details["claim_level_eob"] == true
        rslt = @rcc.get_all_codes_for_entity(@insurance_payment_eob, true) if @insurance_payment_eob.present?
        secondary_codes = @insurance_payment_eob.present?   ?  rslt[:all_reason_codes].join(';') : ""
      else
        rslt = @rcc.get_all_codes_for_entity(@service_payment_eob, true) if @service_payment_eob.present?
        secondary_codes = @service_payment_eob.present?   ?  rslt[:all_reason_codes].join(';') : ""
      end
      secondary_codes
    end


    def eval_check_number
      @check_information ? @check_information.check_number : ""
    end

    def eval_hlsc_check_number
      eval_check_number
    end

    
    def eval_provider_adjustment
      @insurance_payment_eob.provider_adjustment_amount #rescue nil
    end


    def eval_bank_acct_number
      @micr ? @micr.payer_account_number  : ""
    end

    def eval_hlsc_gateway
      @payer ?  @payer.gateway : ""      
    end

    def eval_service_date
      #@service_payment_eobs.present? ? @service_payment_eobs.first.date_of_service_from : ""
      @service_payment_eob.present? ? @service_payment_eob.date_of_service_from : ""
    end


    def eval_bank_routing_number
      @micr ? @micr.aba_routing_number : ""
    end


    def eval_hlsc_payer_id
      @payer ? @payer.supply_payid : ""
    end

    
    def eval_source_file
      @batch ? @batch.src_file_name : ""
    end


    def eval_captured_provider_adjustments
      #@service_payment_eobs.present? ? @service_payment_eobs.first.date_of_service_to : ""
      ""
    end

    def eval_image_reference_number
      @images_for_job ? @images_for_job.filename : ""
    end

    def eval_thru_date
      #@service_payment_eobs.present? ? @service_payment_eobs.first.date_of_service_to : ""
      @service_payment_eob.present? ? @service_payment_eob.date_of_service_to : ""
    end
    
    def eval_carrier_code_or_insurance_plan
      @insurance_payment_eob ? @insurance_payment_eob.plan_type : ""
    end

    def eval_invoice_number
      " "
    end

    def eval_transmit_date
      @batch && @batch.arrival_time ? @batch.arrival_time.to_s(:db) : ""
    end

    def eval_batch_date
      @batch ? @batch.date : ""
    end
    
    def eval_check_batch_date
      eval_batch_date
    end

    def eval_line_total_payment
      ServicePaymentEob.sum_attribute("service_paid_amount", @insurance_payment_eob.id) 
    end
    
    def eval_batch_id
      @batch ? @batch.index_batch_number : ""
    end
    
    def eval_claim_coins_amt
      ServicePaymentEob.sum_attribute("service_co_insurance", @insurance_payment_eob.id)      
    end
    
    def eval_lockbox_batch_cut
      @batch ? @batch.cut : ""
    end

    def eval_claim_deductible_amt
       ServicePaymentEob.sum_attribute("service_deductible", @insurance_payment_eob.id)
    end

    def eval_lockbox_batch_id
      eval_batch_id
    end    

    def eval_dummy
      ""
    end
    
  end
  
end
