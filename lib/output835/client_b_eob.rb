class Output835::ClientBEob < Output835::HlscEob
  # Used when additional reference numbers specific to the claim in the
  # CLP segment are provided to identify information used in the process of
  # adjudicating this claim
  def other_claim_related_id
    elements = []
    pat_name_with_sal = eob.patient_account_number.include?('SAL') || eob.patient_account_number.include?('sal')
    reason_codes = eob.service_payment_eobs.collect{|service| service.get_all_reason_codes}
    if pat_name_with_sal
      elements << 'G3'
      elements << reason_codes.join(';')
      elements = elements.join(@element_seperator)
    end
    elements unless elements.blank?
  end

 def claim_freq_indicator
    if eob.amount('total_amount_paid_for_claim') < 0
      8
    elsif eob.claim_information && !eob.claim_information.claim_frequency_type_code.blank?
      eob.claim_information.claim_frequency_type_code
    end
  end

  #supply adjustment reason codes and amounts as needed for an entire claim
  #or for a particular service within the claim being paid
  def claim_adjustment
  end
end