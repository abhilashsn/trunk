# EOB level output customizations for Merit Mountainside
class Output835::MeritMountainsideEob < Output835::Eob

  #Supplies information common to all services of a claim
  def claim_payment_information
    clp_elements = []
    clp_elements << 'CLP'
    clp_elements << patient_account_number
    clp_elements << claim_type_weight
    clp_elements << eob.amount('total_submitted_charge_for_claim')
    clp_elements << eob.amount('total_amount_paid_for_claim')
    clp_elements << (clp_elements[2] == 22 ? "" : eob.patient_responsibility_amount)
    clp_elements << plan_type
    clp_elements << eob.claim_number
    clp_elements << facility_type_code
    clp_elements << claim_freq_indicator
    clp_elements << nil
    clp_elements << eob.drg_code unless eob.drg_code.blank?
    clp_elements = Output835.trim_segment(clp_elements)
    clp_elements.join(@element_seperator)
  end

  protected ######################## PROTECTED METHODS ########################
  
  def patient_account_number
    if eob.patient_account_number.length == 7
      eob.patient_account_number + '00'
    else
      eob.patient_account_number
    end
  end
end