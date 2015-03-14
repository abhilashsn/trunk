class Unified835Output::EftCheck < CheckInformation
	
	def is_eft_check?
		true
	end

	def is_chk_check?
		false
	end

	def is_cor_check?
		false
	end

	def is_oth_check?
		false
	end

	def is_non_zero_eft_check?
		is_non_zero_amount?
	end

	def is_non_zero_chk_check?
		false
	end

	def is_non_zero_cor_check?
		false
	end

	def is_non_zero_oth_check?
		false
	end

	def get_trn_03
		return nil if facility.facility_tin.blank?
		'1' + facility.facility_tin
	end

end