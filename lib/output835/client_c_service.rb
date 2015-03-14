class Output835::ClientCService < Output835::HlscService
  #The DTM segment in the SVC loop is to be used to express dates and date
  #ranges specifically related to the service identified in the SVC segment
  def service_date_reference
    service_date_elements = []
    service_date_elements << 'DTM'
    service_date_elements << '472'
    service_date_elements << service.date_of_service_from.to_s.strip.split("-").join
    service_date_elements.join(@element_seperator)
  end
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
  #supplies adjustment reason codes and amounts as needed for an entire claim
  #or for a particular service within the claim being paid
  def service_adjustments
    payer_id = service.insurance_payment_eob.check_information.payer.id
    cas_segments = []
    cas_segments << cas_without_crosswalk('coinsurance_groupcode', 'coinsurance_code', 'service_co_insurance')
    cas_segments << cas_without_crosswalk('deductuble_groupcode', 'deductuble_code', 'service_deductible')
    cas_segments << cas_without_crosswalk('copay_groupcode', 'copay_code', 'service_co_pay')
    cas_segments << cas_with_crosswalk(payer_id, 'noncovered_groupcode', 'noncovered_code', 'noncovered_code_description', 'service_no_covered')
    cas_segments << cas_with_crosswalk(payer_id, 'discount_groupcode', 'discount_code', 'discount_code_description', 'service_discount')
    cas_segments << cas_with_crosswalk(payer_id, 'denied_groupcode', 'denied_code', 'denied_code_description', 'denied')
    cas_segments << cas_with_crosswalk(payer_id, 'contractual_groupcode', 'contractual_code', 'contractual_code_description', 'contractual_amount')
    cas_segments << cas_without_crosswalk('primary_payment_groupcode', 'primary_payment_code', 'primary_payment')
    cas_segments = cas_segments.compact
    cas_segments unless cas_segments.empty?
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
    when 'denied', 'service_no_covered'
      'OA'
    end
  end
end