class Output835::OptimHealthcareWfTemplate < Output835::QuadaxTemplate
  def payee_identification(payee,check = nil,claim = nil,eobs = nil)
    payee_identification_for_optim(payee, check, claim, eobs)
  end
 
end