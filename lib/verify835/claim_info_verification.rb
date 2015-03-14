class Verify835::ClaimInfoVerification < Verify835::BalanceVerification
  attr_accessor :charge, :payment, :services, :cas_amounts, :service_count

  def initialize(init_hash)
    init_hash.each_pair do |key, value|
			self.send("#{key.to_s}=", value)
		end
  end

  def set_cas_amounts(amount)
    @cas_amounts << amount
  end

  def check_balance
    total_service_charge = 0
    if @cas_amounts.present?
      return (@charge - @cas_amounts.flatten.map(&:to_f).inject(:+)).round(2) == @payment
    else
      @services.each do |service|
        service.payment == ((service.charge - service.cas_amounts).round(2)) ? (total_service_charge += service.charge) : (return false)
      end
      return false if total_service_charge.round(2) != @charge
    end
    true
  end
  
end
