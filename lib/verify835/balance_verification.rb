class Verify835::BalanceVerification

  def initialize(track_number)
    @track_number = track_number
    @total_claim_payment = 0
  end

	def set_provider_payment_values(line, delimiter)
		@actual_provider_payment = line.delete('~').chop.split(delimiter)[2].to_f
	end

	def set_claim_values(line, delimiter)
		@balanced = @claim.check_balance if @claim
    charge, payment = line.delete('~').chop.split(delimiter).select.with_index{|x, i| [3,4].include?(i)}.map(&:to_f)
		@total_claim_payment = payment + @total_claim_payment
    @claim = Verify835::ClaimInfoVerification.new({:charge => charge, :payment => payment, :services => [], :cas_amounts => []})
    @reference_obj = @claim
	end

	def set_service_values(line, delimiter)
    charge, payment = line.delete('~').chop.split(delimiter).select.with_index{|x, i| [2,3].include?(i)}.map(&:to_f)
    service = Verify835::ServiceInfoVerification.new(:charge => charge, :payment => payment, :cas_amounts => 0)
    @claim.services << service
    @reference_obj = service
	end

	def set_claim_service_cas_amounts(line, delimiter)
		cas_amount = line.delete('~').chop.split(delimiter).drop(1).select.with_index{|x, i| (i+1) %3 == 0}.map(&:to_f).inject(:+)
    @reference_obj.send(:set_cas_amounts, cas_amount)
	end

	def set_provider_adjustment_values(line, delimiter)
		adjustment_amounts = line.delete('~').chop.split(delimiter).drop(1).select.with_index{|x, i| (i+1) %2 == 0}.map(&:to_f)
    @adjustment_total = adjustment_amounts.drop(1).inject(:+)
	end

	def check_transaction_balance
    unless @balanced == false
      @balanced = @claim.check_balance
      @balanced = (@actual_provider_payment == (@adjustment_total ? (@total_claim_payment.round(2) - @adjustment_total) : @total_claim_payment.round(2)) ? true : false) if @balanced
    end
		[@track_number, @balanced]
	end
end