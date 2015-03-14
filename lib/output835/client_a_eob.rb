 class Output835::ClientAEob < Output835::HlscEob
 #Supplies information common to all services of a claim
  def claim_payment_information
    clp_elements = []
    clp_elements << 'CLP'
    clp_elements << eob.patient_account_number.sub(/\A0+/,'') #replaces leading zeros with spaces
    clp_elements << claim_type
    clp_elements << eob.amount('total_submitted_charge_for_claim')
    clp_elements << eob.amount('total_amount_paid_for_claim')
    clp_elements << (clp_elements[2] == 22 ? "" : eob.patient_responsibility_amount)
    clp_elements << "MC"
    clp_elements << eob.claim_number
    clp_elements << (facility_type_code.blank? ? '13' :  facility_type_code)
    clp_elements << claim_freq_indicator
    clp_elements.join(@element_seperator)
  end

  #Supplies the full name of an individual or organizational entity
  #Required when the insured or subscriber is different from the patient
  def service_prov_name
    service_prov_name_elements = []
    service_prov_name_elements << 'NM1'
    service_prov_name_elements << '82'
    service_prov_name_elements << '1'
    service_prov_name_elements << eob.patient_last_name
    service_prov_name_elements << eob.patient_first_name
    service_prov_name_elements << eob.patient_middle_initial
    service_prov_name_elements << ''
    service_prov_name_elements << ''
    service_prov_name_elements << 'PC'
    service_prov_name_elements << "#{eob.check_information.batch.facility.lockbox_number}-#{eob.check_information.check_number}"
    service_prov_name_elements.join(@element_seperator)
  end

   def claim_supplemental_info
   end

  def claim_type
    payment = eob.amount('total_amount_paid_for_claim')
    denied = eob.amount('total_denied')
    non_covered = eob.amount('total_non_covered')
    iplan = eob.claim_information.iplan if eob.claim_information
    if iplan == 'MCR'
      2
    elsif payment == denied
      4
    elsif (!payment && (denied || non_covered))
      4
    elsif !payment
      4
    elsif payment && denied
      2
    else
      eob.claim_type_weight || 1
    end
  end
 end