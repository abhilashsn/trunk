class Output835::MeritMountainsideSingleStTemplate < Output835::SingleStTemplate

  # giving batch date instead of file generating date
 def group_date
   @batch.date.strftime("%Y%m%d")
 end

  #Supplies information common to all services of a claim
  def claim_payment_information
    claim_weight = @eob.claim_type_weight
    ['CLP', patient_account_number, claim_weight, @eob.amount('total_submitted_charge_for_claim'), @eob.payment_amount_for_output(@facility, @facility_output_config), ( claim_weight == 22 ? "" : @eob.patient_responsibility_amount),
      plan_type, claim_number, eob_facility_type_code, claim_freq_indicator, nil,
      (@eob.drg_code if @eob.drg_code.present?)].trim_segment.join(@element_seperator)
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

  # For Merit Mountain side CLP07 should be Check number_Claim Number
  def claim_number
    @eob.claim_number.present? ?  "#{@check.check_number}_#{@eob.claim_number}" : "#{@check.check_number}"
  end

end