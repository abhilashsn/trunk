class Output835::AscendClinicalLlcCheck < Output835::Check

  def financial_info
    bpr_elements = []
    bpr_elements << "BPR"
    if (@check_amount.to_f > 0 && check.payment_method == "CHK")
      bpr_elements << "C"
    elsif (@check_amount.to_f.zero?)
      bpr_elements << "H"
    elsif (@check_amount.to_f > 0 && check.payment_method == "EFT")
      bpr_elements << "I"
    elsif (check.payment_method == "OTH")
      bpr_elements << "D"
    end
    bpr_elements << @check_amount
    bpr_elements << 'C'
    bpr_elements << payment_indicator
    if @check_amount.to_f > 0 && check.payment_method == "EFT"
      bpr_elements << "CCP"
      bpr_elements << "01"
      bpr_elements << "999999999"
      bpr_elements << "DA"
      bpr_elements << "999999999"
      bpr_elements << "9999999999"
      bpr_elements << "199999999"
      bpr_elements << "01"
      bpr_elements << "999999999"
      bpr_elements << "DA"
      bpr_elements << "999999999"
    else
      bpr_elements << ['', '', '', '','', '', '', '', '', '','']
    end
    bpr_elements << effective_payment_date
    bpr_elements = bpr_elements.flatten
    bpr_elements = Output835.trim_segment(bpr_elements)
    bpr_elements.join(@element_seperator)
  end

  def payer_additional_identification_bac(payer)
    payid = nil
    if payer.class == Payer
      claim_information = @check.insurance_payment_eobs.find(:all,:conditions=>"claim_payid is not null",:group=>"claim_payid",:order=>"COUNT(claim_payid) DESC,id ASC")
      if claim_information && !claim_information[0].blank?
        payid = claim_information[0].claim_payid.to_s
      else
        if check.micr_line_information && check.micr_line_information.payer && facility.details[:micr_line_info]
          check_payer = check.micr_line_information.payer
        else
          check_payer = check.payer
        end
        payid= output_payid(check_payer)
      end
      ["REF", "2U", payid].join(@element_seperator) unless payid.blank?
    end
  end
  
  def ref_ev_loop
    ['REF','EV', @check.job.images_for_jobs.first.exact_file_name.to_s[0...50]].join(@element_seperator)
  end

  def payer_identification(payer)
    ['N1', 'PR', payer.name.strip.upcase[0...60].strip].join(@element_seperator)
  end
  
end
