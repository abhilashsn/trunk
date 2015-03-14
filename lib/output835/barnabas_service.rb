class Output835::BarnabasService < Output835::Service

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
    service_segments << provider_control_number
    service_segments << service_supplemental_amount unless supplemental_amount.blank?
    service_segments << standard_industry_code_segments
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

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

  def provider_control_number
    @claim_service = ClaimServiceInformation.find(:first,:conditions=>"id = #{service.claim_service_information_id}") unless service.claim_service_information_id.blank?
    if !@claim_service.blank?
      service_provider_control_number = @claim_service.provider_control_number unless @claim_service.provider_control_number.blank?
    else
      service_provider_control_number =  service.service_provider_control_number
    end
    unless service_provider_control_number.blank?
      service_provider_elements = []
      service_provider_elements << 'REF'
      service_provider_elements << '6R'
      service_provider_elements << service_provider_control_number
      service_provider_elements = Output835.trim_segment(service_provider_elements.compact)
      service_provider_elements.join(@element_seperator)
    end
  end


  def svc_revenue_code
    if (!service.service_procedure_code.blank? and !service.revenue_code.blank?)
      rev_code = service.revenue_code
    elsif (service.revenue_code.blank?)
      rev_code = ''
    else
      rev_code = service.service_procedure_code.to_s
    end
    rev_code
  end

  def composite_med_proc_id
    elem = []
    if ((!service.revenue_code.blank? and !service.service_procedure_code.blank? )|| service.revenue_code.blank?)
      proc_code = "HC" + @delimiter + service.service_procedure_code.to_s
    else
      proc_code = "NU" + @delimiter + service.revenue_code
    end
    elem = [proc_code, service.service_modifier1 , service.service_modifier2 ,
      service.service_modifier3 , service.service_modifier4]
    elem = Output835.trim_segment(elem)
    elem.join(@delimiter)
  end
  
end