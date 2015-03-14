class Verify835::ServiceInfoVerification < Verify835::ClaimInfoVerification
  attr_accessor :charge, :payment, :cas_amounts
  
  def initialize(init_hash)
    init_hash.each_pair do |key, value|
			self.send("#{key.to_s}=", value)
		end
  end

  def set_cas_amounts(amount)
    @cas_amounts += amount
  end

end
