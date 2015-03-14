class Output835::PacificDentalServicesService < Output835::Service

  def composite_med_proc_id
    @delimiter = '>'
    elem = []
    proc_code = service.service_procedure_code ? ('AD' + @delimiter + service.service_procedure_code) : 'AD' + @delimiter
    elem = [proc_code, service.service_modifier1 , service.service_modifier2 ,
      service.service_modifier3 , service.service_modifier4]
    elem = Output835.trim_segment(elem)
    elem.join(@delimiter)
  end


  def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = service.date_of_service_from.strftime("%Y%m%d") unless service.date_of_service_from.blank?
    to_date = service.date_of_service_to.strftime("%Y%m%d") unless service.date_of_service_to.blank?
    from_eqls_to_date = (from_date == to_date)
 
    if !from_date.nil? && (to_date.nil? || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      service_date_elements =  (from_date == "20000101" ? dtm_472("19700101") : dtm_472(from_date))
      service_date_elements unless service_date_elements.blank?
    else
      svc_date_segments << dtm_150(from_date) if from_date
      svc_date_segments << dtm_151(to_date) if to_date
      svc_date_segments unless svc_date_segments.join.blank?
    end
  end
 

end