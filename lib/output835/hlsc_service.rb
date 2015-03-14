class Output835::HlscService < Output835::Service
  #supplies payment and control information to a provider for a particular service
  def service_payment_information
    service_payment_elements =[]
    service_payment_elements << 'SVC'
    service_payment_elements << composite_med_proc_id
    service_payment_elements << service.amount('service_procedure_charge_amount')
    service_payment_elements << service.amount('service_paid_amount')
    service_payment_elements.join(@element_seperator )
  end
  def composite_med_proc_id
    proc_code =  ((service.service_procedure_code if !service.service_procedure_code.blank?) || 
                  (service.revenue_code if !service.revenue_code.blank?) || 'E01')
    proc_code != 'E01' ? 'HC>'+proc_code : 'ZZ>E01'
  end

end