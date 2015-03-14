class Output835::ShepherdEyeSurgicenterService < Output835::Service
  
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
    service_segments << service_supplemental_amount unless (supplemental_amount.blank? || supplemental_amount.to_f.zero?)
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

  #The DTM segment in the SVC loop is to be used to express dates and date
  #ranges specifically related to the service identified in the SVC segment
  # If service from and to dates are same, only print one segment with qual 472
  # Else print one segment each for the two dates
  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = service.date_of_service_from.strftime("%Y%m%d") unless service.date_of_service_from.blank?
    to_date = service.date_of_service_to.strftime("%Y%m%d") unless service.date_of_service_to.blank?   
    if from_date
      service_date_elements << 'DTM'
      service_date_elements << '150'
      service_date_elements << from_date
      svc_date_segments << service_date_elements.join(@element_seperator)
    end
    if to_date
      service_date_elements = []
      service_date_elements << 'DTM'
      service_date_elements << '151'
      service_date_elements << to_date
      svc_date_segments << service_date_elements.join(@element_seperator)
    end
    svc_date_segments unless svc_date_segments.blank?
  end
  
end