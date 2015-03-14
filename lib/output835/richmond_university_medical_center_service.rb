class Output835::RichmondUniversityMedicalCenterService < Output835::Service
  
  # Adding health remark code segment for RUMC i.e. LQ*RX segment
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
    service_segments << service_line_item_control_num
    service_segments << health_remark_code_segments
    service_segments << service_supplemental_amount unless supplemental_amount.blank?
    service_segments << patpay_specific_lq_segment
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
    service_payment_elements << svc_revenue_code
    service_payment_elements << service.service_quantity.to_f.to_amount
    service_payment_elements = Output835.trim_segment(service_payment_elements)
    service_payment_elements.join(@element_seperator )
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
    if ((!cpt_code.blank? and !revenue_code.blank?)|| revenue_code.blank?)
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
  
  # Computing Health Remark Code segments
  def health_remark_code_segments
    @eob = service.insurance_payment_eob
    facility = @eob.check_information.job.batch.facility
    health_remark_code_segments = []
    health_remark_code_segments << compute_lq("in")
    health_remark_code_segments << compute_lq("out")        
    if facility.details[:interest_in_service_line] && service.interest_service_line?
      health_remark_code_segments << lq_rx_segments("109975") if @eob.claim_interest.to_f > 0.0 
    end       
    health_remark_code_segments << lq_rx_segments("109702") if @eob.hcra.to_f > 0.0
    health_remark_code_segments.compact!
    health_remark_code_segments.flatten
  end
  
  # Computing LQ*RX segments according to the Patient Type(InPatient or OutPatient)
  def compute_lq(patient_type)
    segments = []
    patient_code = service.send("#{patient_type}patient_code")
    facility_payer_information = FacilitiesPayersInformation.find_by_payer_id_and_facility_id(payer.id, facility.id) if payer
    if facility_payer_information
      capitation_code = facility_payer_information.capitation_code
      if(patient_type == "in")
        allowance_code = facility_payer_information.in_patient_allowance_code
        payment_code = facility_payer_information.in_patient_payment_code
      else
        allowance_code = facility_payer_information.out_patient_allowance_code
        payment_code = facility_payer_information.out_patient_payment_code
      end
    
    end
    unless patient_code.blank?
      patient_code_array = patient_code.split(",")
      segments << (lq_rx_segments(allowance_code) if patient_code_array.include?("1") and !allowance_code.blank?)
      segments << (lq_rx_segments(capitation_code) if patient_code_array.include?("2") and !capitation_code.blank?)
    end
    serv_amt = service.service_paid_amount.to_f
    pat_type = @eob.patient_type.downcase rescue nil
    
    if serv_amt > 0 and pat_type == "#{patient_type}patient"
      segments << (lq_rx_segments(payment_code) unless payment_code.blank?)
    end
    segments
  end
  
  # Returns one LQ*RX line for the corresponding code(allowance, capitation, payment etc.)
  def lq_rx_segments(code)
    lq_rx_segments = []
    lq_rx_segments << 'LQ'
    lq_rx_segments << 'RX'
    lq_rx_segments << (code.blank? ? '' : code.strip)
    Output835.trim_segment(lq_rx_segments)
    lq_rx_segments.join(@element_seperator)
  end
  
  # Gives the payer of the service line. First preference is given to Micr Payer. 
  # If Micr payer is nil then it returns Payer associated with the service line's check 
  def payer
    check = service.insurance_payment_eob.check_information
    micr = check.micr_line_information
    (micr and micr.payer) ? micr.payer : check.payer
  end

  def patpay_specific_lq_segment
    check = service.insurance_payment_eob.check_information
    if check.eob_type == 'Patient'
      elements = []
      elements << "LQ"
      elements << "RX"
      elements << "202614"
      elements.join(@element_seperator)
    end
  end
end