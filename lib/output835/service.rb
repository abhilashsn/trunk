class Output835::Service
  attr_reader :service, :index, :facility, :payer, :client
  def initialize(service, facility, payer, index, element_seperator)
    @service = service
    @facility = facility
    @client = facility.client
    @facility_config = facility.facility_output_configs.first
    @payer = payer
    @index = index
    @crosswalked_reason_codes = []
    @crosswalked_reason_code_objects = []
    @element_seperator = element_seperator
    @delimiter = ':'
  end

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
    service_segments << provider_control_number if $IS_PARTNER_BAC 
    service_segments << service_supplemental_amount unless supplemental_amount.blank?
    service_segments << standard_industry_code_segments
    service_segments = service_segments.compact
    [service_segments.flatten, pr_amount]
  end

  #supplies payment and control information to a provider for a particular service
  def service_payment_information
    service_payment_elements =[]
    service_payment_elements << 'SVC'
    service_payment_elements << composite_med_proc_id
    service_payment_elements << service.amount('service_procedure_charge_amount')
    service_payment_elements << service.amount('service_paid_amount')
    service_payment_elements << svc_revenue_code
    service_payment_elements << service.service_quantity.to_f.to_amount
    service_payment_elements << svc_procedure_cpt_code
    service_payment_elements = Output835.trim_segment(service_payment_elements)
    service_payment_elements.join(@element_seperator )
  end

  #SVC01 Segment
  def composite_med_proc_id
    elem = []
    proc_code = if bundled_cpt_code.present?
      "HC:#{bundled_cpt_code}"
    elsif proc_cpt_code.present?
      "HC:#{proc_cpt_code}"
    elsif revenue_code.present?
      "NU:#{revenue_code}"
    else
      "HC:"
    end

    elem = [proc_code, service.service_modifier1, service.service_modifier2, service.service_modifier3, service.service_modifier4]
    elem = Output835.trim_segment(elem)
    elem.join(':')
  end

  #SVC04 Segment
  def svc_revenue_code
    (proc_cpt_code.present? and revenue_code.present?) ? revenue_code : ''
  end

  #SVC06 Segment. This segment will append when both service and bundled procedure code is present in service_payment_eob.
  def svc_procedure_cpt_code
    "HC:#{proc_cpt_code}" if (bundled_cpt_code.present? and proc_cpt_code.present?)
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
    
    if !from_date.nil? && (to_date.nil? || from_eqls_to_date || @client.group_code.to_s.strip == 'KOD')
      if @client.name.strip.upcase == "ISTREAMS" and from_date == "20000101"
        service_date_elements = dtm_472("00000000")
      else
        service_date_elements = dtm_472(from_date)
      end
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

  def dtm_472(date)
    ['DTM', '472', date].join(@element_seperator)
  end

  def dtm_150 date
    ['DTM', '150', date].join(@element_seperator)
  end

  def dtm_151 date
    ['DTM', '151', date].join(@element_seperator)
  end

  # Specifies identifying information
  def service_line_item_control_num    
  end

  def proc_cpt_code
    service.service_procedure_code.blank? ? '' : service.service_procedure_code
  end

  def revenue_code
    revenue_code = service.revenue_code.blank? ? '' : service.revenue_code
    revenue_code.downcase == 'none' ? '' : revenue_code
  end

  def bundled_cpt_code
    service.bundled_procedure_code.blank? ? '' : service.bundled_procedure_code
  end

  def service_supplemental_amount
    elements = []
    elements << "AMT"
    elements << "B6"
    elements << supplemental_amount
    elements = elements.join(@element_seperator)
    elements
  end
  
  def supplemental_amount
    amount = nil
    check = service.insurance_payment_eob.check_information
    if check.eob_type == 'Patient'
      unless service.service_paid_amount.blank? || service.service_paid_amount.to_f.zero?
        amount = service.amount('service_paid_amount')
      end
    else
      unless service.service_allowable.blank? || service.service_allowable.to_f.zero?
        amount = service.amount('service_allowable')
      end
    end
    amount
  end

  def provider_control_number
    unless service.service_provider_control_number.blank?
      service_provider_elements = []
      service_provider_elements << 'REF'
      service_provider_elements << '6R'
      service_provider_elements << service.service_provider_control_number
      service_provider_elements = Output835.trim_segment(service_provider_elements.compact)
      service_provider_elements.join(@element_seperator)
    end
  end

  def standard_industry_code_segments
    Output835.standard_industry_code_segments(service, client, facility, payer, @element_seperator)
  end
  
end
