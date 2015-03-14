class Unified835Output::OthCheck < CheckInformation
	
	def is_chk_check?
		false
	end

	def is_eft_check?
		false
	end

	def is_cor_check?
		false
	end

	def is_oth_check?
		true
	end

	def is_non_zero_eft_check?
		false
	end

	def is_non_zero_chk_check?
		false
	end

	def is_non_zero_cor_check?
		false
	end

	def is_non_zero_oth_check?
		is_non_zero_amount?
	end

end