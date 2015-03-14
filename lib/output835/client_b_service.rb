class Output835::ClientBService < Output835::HlscService
  #supplies payment and control information to a provider for a particular service
  def service_payment_information
    service_payment_elements =[]
    service_payment_elements << 'SVC'
    service_payment_elements << composite_med_proc_id
    service_payment_elements << service.amount('service_procedure_charge_amount')
    service_payment_elements << service.amount('service_paid_amount')
    service_payment_elements << revenue_code
    service_payment_elements.join(@element_seperator )
  end

  def composite_med_proc_id
    'HC>'+service.service_procedure_code
  end

  def revenue_code
    revenue_code = service.revenue_code unless service.revenue_code.blank?
    if revenue_code
      revenue_code.downcase == 'none' ? '' : revenue_code
    end
  end

  # Returns the custom group code for this lockbox
  # by taking in the dollar amount field name in db
  def group_code(amount_column)
    case amount_column
    when 'denied'
      'OA'
    when 'service_no_covered'
      'OA'
    end
  end
  # Returns the reason group code for this lockbox
  # by taking in the dollar amount field name in db
  def code(amount_column)
    if amount_column == 'service_co_insurance'
      quotient_remainder_array = service.service_co_insurance.to_f.divmod(5)
      if service.service_co_insurance.to_f < 100 && quotient_remainder_array.last.to_f.zero?
        3
      else
        2
      end
    end
  end
end