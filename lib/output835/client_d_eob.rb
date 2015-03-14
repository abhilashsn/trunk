class Output835::ClientDEob < Output835::HlscEob
  #supply adjustment reason codes and amounts as needed for an entire claim
  #or for a particular service within the claim being paid
  def claim_adjustment
    claim_cas_segments = []
    claim_cas_segments << cas_without_crosswalk('claim_coinsurance_groupcode', 'claim_coinsurance_reasoncode', 'total_co_insurance')
    claim_cas_segments << cas_without_crosswalk('claim_deductuble_groupcode', 'claim_deductable_reasoncode', 'total_deductible')
    claim_cas_segments << cas_without_crosswalk('claim_denied_groupcode', 'claim_denied_reasoncode', 'total_denied')
    claim_cas_segments << cas_without_crosswalk('claim_noncovered_groupcode', 'claim_noncovered_reasoncode', 'total_non_covered')
    claim_cas_segments << cas_without_crosswalk('claim_discount_groupcode', 'claim_discount_reasoncode', 'total_discount')
    claim_cas_segments << cas_without_crosswalk('claim_copay_groupcode', 'claim_copay_reasoncode', 'total_co_pay')
    claim_cas_segments << cas_without_crosswalk('claim_contractual_groupcode', 'claim_contractual_reasoncode', 'total_contractual_amount')
    claim_cas_segments << cas_without_crosswalk('claim_primary_payment_groupcode', 'claim_primary_payment_reasoncode', 'total_primary_payer_amount')
    claim_cas_segments = claim_cas_segments.compact
    claim_cas_segments
  end

  #Supplies payment and control information to a provider for a particular service
  def service_payment_info_loop
  end
  # Returns the custom group code for this client
  # by taking in the dollar amount field name in db
  def group_code(amount_column)
    case amount_column
    when 'total_co_insurance'
      'PR'
    when 'total_deductible'
      'PR'
    when 'total_co_pay'
      'PR'
    when 'total_denied'
      'OA'
    when 'total_non_covered'
      'OA'
    when 'total_discount'
      'PI'
    when 'total_contractual_amount'
      'CO'
    when 'total_primary_payer_amount'
      'OA'
    end
  end
  # To override reason codes with custom reason codes for this client
  def code(amount_column)
    case amount_column
    when 'total_co_insurance'
      '2'
    when 'total_deductible'
      '1'
    when 'total_co_pay'
      '3'
    when 'total_denied'
      '18'
    when 'total_non_covered'
      '96'
    when 'total_discount'
      '131'
    when 'total_contractual_amount'
      '45'
    when 'total_primary_payer_amount'
      '23'
    end
  end
end
