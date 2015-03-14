#Holds all service line level customizations for Client E of HLSC
class Output835::ClientEService < Output835::HlscService
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

  def service_supplemental_amount
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
    when 'service_co_insurance'
      'PR'
    when 'service_deductible'
      'PR'
    when 'service_co_pay'
      'PR'
    when 'service_discount'
      'PI'
    when 'denied'
      'OA'
    when 'service_no_covered'
      'OA'
    when 'contractual_amount'
      'OA'
    when 'primary_payment'
      'OA'
    end
  end
  # To override reason codes with custom reason codes for Client A
  def code(amount_column)
    case amount_column
    when 'service_co_insurance'
      '2'
    when 'service_deductible'
      quotient_remainder_array = service.service_co_insurance.to_f.divmod(5)
      if service.service_co_insurance.to_f < 50 && quotient_remainder_array.last.to_f.zero?
        '3'
      else
        '1'
      end
    when 'service_co_pay'
      '3'
    when 'service_discount'
      '137'
    when 'primary_payment'
      '23'
    end
  end
end