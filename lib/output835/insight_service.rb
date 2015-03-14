class Output835::InsightService < Output835::Service
def service_date_reference
    service_date_elements, svc_date_segments = [], []
    from_date = service.date_of_service_from.strftime("%Y%m%d") unless service.date_of_service_from.blank?
    to_date = service.date_of_service_to.strftime("%Y%m%d") unless service.date_of_service_to.blank?

    if from_date == to_date || to_date.nil?
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
end
