module OperationLog
  module GoodmanCampbellCheck

    # def eval_reject_reason
    #   eob = InsurancePaymentEob.find(:first,
    #                                  :conditions => ['check_information_id = ?', check.id])
    #   (eob.blank? || eob.rejection_comment.blank?) ? "-" : eob.rejection_comment
    # end

    def eval_image_id
      job = check.job
      job.initial_image_name unless job.initial_image_name.blank?
    end    

    def eval_first_payer_name
      if @checks.size > 0
        is_micr_payer_present = @checks.first.micr_line_information && @checks.first.micr_line_information.payer && facility.details[:micr_line_info]
        payer = is_micr_payer_present ? @checks.first.micr_line_information.payer : @checks.first.payer
        if payer
          payid = (@nextgen_insurance ? payer.supply_payid : payer.output_payid(facility))
        end
        if payer 
          payer_name_for_check @checks.first
        else
          ""
        end
      else
        ""
      end
    end


    def payer_name_for_check_v2 (chk)
      client_name = facility.client.name  
      check_payer = chk.payer
      payer_name = ""
      unless check_payer.nil?
        if chk.job.payer_group.downcase == "patpay" && client_name.downcase != "quadax"
          payer_name = "self pay 835 format"
        else
          micr = chk.micr_line_information
          is_micr_payer_present = micr && micr.payer && facility.details[:micr_line_info]
          payer_name = is_micr_payer_present ? micr.payer.payer : check_payer.payer
          if is_micr_payer_present && micr.payer.output_payid(facility) == "4300" && config.by_cpid
            payer_name = "MISCPAYER"
          end
        end
      end      
      payer_name.blank? ? '-' : payer_name    
    end

    def eval_payer_name
      client_name = facility.client.name
      check_payer = check.payer
      payer_name = ""
      if !check_payer.nil?
        if check.job.payer_group.downcase == "patpay" && client_name.downcase != "quadax"
          facility_output_config = facility.facility_output_configs.where("(report_type != 'Operation Log' or report_type is null) and
                            eob_type = 'Patient Payment'").first rescue nil
          default_patient_name = facility_output_config.details[:default_patient_name] rescue nil
          payer_name = default_patient_name.present? ? default_patient_name : "PATPAY"
        else
          payer_name = get_micr_associated_payer(check_payer)
        end
      elsif nextgen_check?(check)
        payer_name = "PATPAY"
      end
      payer_name.blank? ? '-' : payer_name
    end

    def eval_check_amount
      get_gcbs_insurance_eobs(check)
      eft_amount =  config.header_fields.index{|x| x.first == "Eft Amount"}
      if eft_amount && check.payment_method == 'EFT'
        check_amount = "-"
      else
        check_amount = complete_check_amount_condition ? check.check_amount.to_f : eob_amount
      end
      (check_amount.blank? || check_amount == "-") ? "-" : sprintf("%.2f", check_amount)
    end

    def eval_eft_amount
      get_gcbs_insurance_eobs(check)
      if check.payment_method == 'EFT'
        eft_amount = complete_check_amount_condition ? check.check_amount.to_f : eob_amount
      else
        eft_amount = "-"
      end
      (eft_amount.blank? || eft_amount == "-") ? "-" : sprintf("%.2f", eft_amount)
    end

    def eval_835_amount
      total_835_amt = 0
      get_gcbs_insurance_eobs(check)
      total_835_amt = complete_check_amount_condition ? check.check_amount.to_f : eob_amount
      total_835_amt.blank? ? "-" : sprintf("%.2f", total_835_amt)
    end

    def eob_amount
      payment_amount =  @eobs.collect{ |eob| eob.total_amount_paid_for_claim.to_f}.sum
      interest_amount = @eobs.collect{|eob| eob.claim_interest.to_f}.sum
      provider_adjustment_amount = check.provider_adjustment_amount
      if !check.nextgen_eobs_for_goodman.blank?
        if @nextgen_insurance
          eob_amount_value = payment_amount + interest_amount + provider_adjustment_amount
        else
          eob_amount_value = payment_amount + interest_amount
        end
      else
        eob_amount_value = payment_amount + interest_amount + provider_adjustment_amount
      end
      eob_amount_value
    end

    def nextgen_eob_amount
      patient_pay_eobs = check.patient_pay_eobs
      amount = patient_pay_eobs.collect{ |eob| eob.stub_amount.to_f}.sum
    end

  end
end


