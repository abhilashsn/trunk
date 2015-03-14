class Output835::QuadaxService < Output835::Service
  
  #supplies payment and control information to a provider for a particular service
  def service_payment_information
    service_payment_elements = []
    service_payment_elements << 'SVC'
    service_payment_elements << procedure_code
    service_payment_elements << service.amount('service_procedure_charge_amount')
    service_payment_elements << service.amount('service_paid_amount')
    service_payment_elements << service_rev_code
    service_payment_elements << service.service_quantity.to_f.to_amount
    service_payment_elements << composite_med_proc_id unless service.bundled_procedure_code.blank?
    service_payment_elements = Output835.trim_segment(service_payment_elements)
    service_payment_elements.join(@element_seperator)
  end

  #The DTM segment in the SVC loop is to be used to express dates and date
  #ranges specifically related to the service identified in the SVC segment
  # If service from and to dates are same, only print one segment with qual 472
  # Else print one segment each for the two dates
  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = service.date_of_service_from.strftime("%Y%m%d") unless service.date_of_service_from.blank?
    to_date = service.date_of_service_to.strftime("%Y%m%d") unless service.date_of_service_to.blank?   
    from_eqls_to_date = (from_date == to_date)
    if !from_date.nil? && (to_date.nil? || from_eqls_to_date)
      if from_date == '20000101' || from_date == '99990909'
        from_date = '99999999'
      end
      service_date_elements << 'DTM'
      service_date_elements << '472'
      service_date_elements << from_date
      service_date_elements.join(@element_seperator)
    else
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


  # Specifies identifying information
  def service_line_item_control_num
    service_claim = service.insurance_payment_eob.claim_information
    xpeditor_document_number = service_claim.xpeditor_document_number if service_claim
    unless xpeditor_document_number.blank? || xpeditor_document_number == "0"
      elements = []
      service_index_number = (index+1).to_s.rjust(4 ,'0')
      elements << 'REF'
      elements << '6R'
      elements << xpeditor_document_number+service_index_number
      elements.join(@element_seperator)
    end
  end

  def procedure_code
    elem = []
    if !service.revenue_code.blank? and !service.service_procedure_code.blank?
      procedure_code =  'HC:' +service.service_procedure_code
    elsif service.revenue_code.blank?
      procedure_code = !service.bundled_procedure_code.blank? ? bundled_procedure_code : composite_med_proc_id
    else
      proc_code = 'NU:'+service.revenue_code
      elem = [proc_code, service.service_modifier1 , service.service_modifier2 ,
        service.service_modifier3 , service.service_modifier4]
      elem = Output835.trim_segment(elem)
      procedure_code = elem.join(@delimiter)
    end
    procedure_code
  end
  
  def bundled_procedure_code
    ('HC:' + service.bundled_procedure_code) unless service.bundled_procedure_code.blank?
  end
  
  def service_rev_code
    if (!service.service_procedure_code.blank? and !service.revenue_code.blank?)
      proc_code = service.revenue_code
    else
      proc_code = (service.revenue_code.blank? ? '' : service.service_procedure_code )
    end
    proc_code
  end
  
  def composite_med_proc_id
    elem = []
    proc_code = service.service_procedure_code ? ('HC' + @delimiter + service.service_procedure_code) : 'HC' + @delimiter
    elem = [proc_code, service.service_modifier1 , service.service_modifier2 ,
      service.service_modifier3 , service.service_modifier4]
    elem = Output835.trim_segment(elem)
    elem.join(@delimiter)
  end

end
