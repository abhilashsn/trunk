class Output835::MeritMountainsideSingleStEob < Output835::SingleStEob
  def patient_account_number
    if eob.patient_account_number.length == 7
      eob.patient_account_number + '00'
    else
      eob.patient_account_number
    end
  end
  
  # For Merit Mountain side CLP07 should be Check number_Claim Number
  def claim_number
    str = eob.check_information.check_number.to_s if eob.check_information
    (str += '_' + eob.claim_number) if !eob.claim_number.blank?
    str
  end
  
end