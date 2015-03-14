class Output835::MeritMountainsideTemplate < Output835::Template

  #Supplies information common to all services of a claim
  def claim_payment_information
    claim_weight = @eob.claim_type_weight
    ['CLP', patient_account_number, claim_weight, @eob.amount('total_submitted_charge_for_claim'),
         @eob.amount('total_amount_paid_for_claim'),(claim_weight == 22 ? "" : @eob.patient_responsibility_amount),
         plan_type, @eob.claim_number, eob_facility_type_code, claim_freq_indicator,
         nil, (@eob.drg_code unless @eob.drg_code.blank?) ].trim_segment.join(@element_seperator)
  end

  def patient_account_number
    patient_account_number = captured_or_blank_patient_account_number(@eob.patient_account_number)
    if patient_account_number.length < 9
      number_of_zeros = 9 - patient_account_number.length
      patient_account_number + '0'*number_of_zeros
    else
      patient_account_number
    end
  end
  
end