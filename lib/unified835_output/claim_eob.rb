class Unified835Output::ClaimEob < InsurancePaymentEob
	def is_claim_eob?
		true
	end

	def get_start_date(claim)
		claim_from_date.strftime("%Y%m%d") if claim_from_date.present?
	end

	def get_end_date(claim)
		claim_to_date.strftime("%Y%m%d") if claim_to_date.present?
	end

	def get_start_date_for_netwrx(date_type, claim)
		date = date_type.eql?(:start_date) ? get_start_date(claim) : get_end_date(claim)
		return nil if date.nil?
		return '00000000' if date.eql?('20000101')
		date
	end
end