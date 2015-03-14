# To change this template, choose Tools | Templates
# and open the template in the editor.

class Output835::OrbTestFacilityService< Output835::Service
  def generate
    Output835.log.info "\n\nService Line id : #{service.id}"
    Output835.log.info "Service Line charges: #{service.amount('service_procedure_charge_amount')}, payment : #{service.amount('service_paid_amount')}"
    service_segments = []
    service_segments << service_payment_information unless service.adjustment_line_is?
    service_segments << service_date_reference
    unless service.adjustment_line_is?
      cas_segments, pr_amount = Output835.cas_adjustment_segments(service, client, facility, payer, @element_seperator)
    else
      cas_segments, pr_amount = nil,0.0
    end
    service_segments << cas_segments unless service.adjustment_line_is?
    service_segments << provider_control_number
     if (service.amount('service_paid_amount') != 0)
      service_segments << service_supplemental_amount unless supplemental_amount.blank?
    end
    service_segments << Output835.standard_industry_code_segments(service,
      client, facility, payer, @element_seperator)
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

  # Adding logic to print NU for RUMC. NU should be printed in SVC01-1
  # only when Revenue Code is present. In this case, Revenue Code
  # should be printed in SVC01-2 segment and CPT Code should be printed
  # in SVC04 segment. If Reveunue Code is absent we should print HC
  # in SVC01-1 segment, CPT Code in SVC01-2 and print blank in SVC04 segment.
  def service_payment_information
    service_payment_elements =[]
    service_payment_elements << 'SVC'
    service_payment_elements << composite_med_proc_id
    service_payment_elements << service.amount('service_procedure_charge_amount')
    service_payment_elements << service.amount('service_paid_amount')
    service_payment_elements << svc_revenue_code #service.revenue_code
    if (service.service_quantity.to_f.to_amount > 0)
      service_payment_elements << service.service_quantity.to_f.to_amount
    else
      service_payment_elements << '1'
    end
    service_payment_elements = Output835.trim_segment(service_payment_elements)
    service_payment_elements.join(@element_seperator )
  end

  



  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = service.date_of_service_from.strftime("%Y%m%d") unless service.date_of_service_from.blank?
    to_date = service.date_of_service_to.strftime("%Y%m%d") unless service.date_of_service_to.blank?   
    from_eqls_to_date = (from_date == to_date)

    if !from_date.nil? && (to_date.nil? || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      if from_date == '20000101'
        from_date = '19990101'
      end
      service_date_elements = dtm_472(from_date)
      service_date_elements unless service_date_elements.blank?
    else
      if from_date
        svc_date_segments << dtm_150(from_date)
      end
      if to_date
        svc_date_segments << dtm_151(to_date)
      end
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end


  def service_supplemental_amount
    unless service.insurance_payment_eob.claim_type_weight.to_s == "4"
      elements = []
      elements << "AMT"
      elements << "B6"
      elements << supplemental_amount
      elements = elements.join(@element_seperator)
      elements
    end
  end

  def dtm_472(date)
    ['DTM', '472', date].join(@element_seperator)
  end


  def svc_revenue_code
    if (!cpt_code.blank? and !revenue_code.blank?)
      rev_code = revenue_code
    elsif (revenue_code.blank?)
      rev_code = ''
    else
      rev_code = cpt_code
    end
    rev_code
  end
  # Gives SVC01 segment. Adding logic to print NU for RUMC. NU should be printed
  # in SVC01-1 only when Revenue Code is present. In this case, Revenue Code
  # should be printed in SVC01-2 segment. If Reveunue Code is absent we should
  # print HC in SVC01-1 segment, CPT Code in SVC01-2
  def composite_med_proc_id
    elem = []
    if (cpt_code.blank? and revenue_code.blank?)
      proc_code = "HC:XXXXX"
    elsif ((!cpt_code.blank? and !revenue_code.blank?)|| revenue_code.blank?)
      proc_code = "HC:#{cpt_code}"
    else
      proc_code = "NU:#{revenue_code}"
    end

    # proc_code = ((!cpt_code.blank? and !revenue_code.blank?) || revenue_code.blank?) ? "HC:#{cpt_code}" : "NU:#{revenue_code}"
    elem = [proc_code, service.service_modifier1 , service.service_modifier2 ,
      service.service_modifier3 , service.service_modifier4]
    elem = Output835.trim_segment(elem)
    elem.join(':')
  end

  def cpt_code
    service.service_procedure_code.blank? ? '' : service.service_procedure_code
  end

  def revenue_code
    revenue_code = service.revenue_code.blank? ? '' : service.revenue_code
    revenue_code.downcase == 'none' ? '' : revenue_code
  end

 
  # Gives the payer of the service line. First preference is given to Micr Payer.
  # If Micr payer is nil then it returns Payer associated with the service line's check
  def payer
    check = service.insurance_payment_eob.check_information
    micr = check.micr_line_information
    (micr and micr.payer) ? micr.payer : check.payer
  end

  def patpay_specific_lq_segment
    
  end
end
