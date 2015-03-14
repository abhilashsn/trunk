class Output835::AscendClinicalLlcService < Output835::Service

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
    service_payment_elements << ''
    service_payment_elements << service.service_quantity.to_i
    service_payment_elements = Output835.trim_segment(service_payment_elements)
    service_payment_elements.join(@element_seperator )
  end

  def composite_med_proc_id
    delimiter = ':'
    elem = []
    proc_code = service.service_procedure_code ? ('HC' + delimiter + service.service_procedure_code) : 'HC' + delimiter
    elem = [proc_code, service.service_modifier1 , service.service_modifier2 ,
      service.service_modifier3 , service.service_modifier4]
    elem = Output835.trim_segment(elem)
    elem.join(delimiter)
  end
  
end