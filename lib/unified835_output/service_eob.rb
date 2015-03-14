class Unified835Output::ServiceEob < InsurancePaymentEob
	def is_claim_eob?
		false
	end

	def get_start_date(claim)
		return nil if claim.nil?
		claim.claim_statement_period_start_date.strftime("%Y%m%d") if claim.claim_statement_period_start_date
	end

	def get_end_date(claim)
	end

	def get_start_date_for_netwrx(date_type, claim)
		date_type.eql?(:start_date) ? get_start_date(claim) : get_end_date(claim)
	end

end