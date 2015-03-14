# EOB level output customizations for Client C
class Output835::ClientCEob < Output835::HlscEob
  #supply adjustment reason codes and amounts as needed for an entire claim
  #or for a particular service within the claim being paid
  def claim_adjustment
  end
end