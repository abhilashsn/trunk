class Output835::HoustonMedicalCenterTemplate < Output835::QuadaxTemplate
  def payee_identification(payee,check = nil,claim = nil,eobs = nil)
    payee_identification_for_houston(payee, check, claim, eobs)
  end

  def payee_additional_identification(payee)
    payee_additional_identification_for_houston(payee)
  end
 
end
