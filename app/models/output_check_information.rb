module OutputCheckInformation

	def get_code_type
		check_amount = formatted_check_amount.to_f
		if check_amount.zero?
			'notification_only'
		elsif (check_amount > 0 && payment_method == 'CHK')
			'payment_accompanies_remittance_advice'
		elsif (check_amount > 0 && payment_method == 'EFT')
			'remittance_information_only'
		elsif payment_method == 'OTH'
			'make_payment_only'
		end				
	end

	def get_payment_method
		check_amount = formatted_check_amount.to_f
		if ['CHK', 'OTH'].include? payment_method
			'check'
		elsif check_amount.zero?
			'non_payment_data'
		elsif check_amount > 0 && payment_method == 'EFT'
			'automated_clearing_house'
		end			
	end

	#Need to Check How this is functioning
	def formatted_check_amount
		amount = check_amount.to_f
		(amount == (amount.truncate) ? amount.truncate : amount)
	end

	def is_non_zero_amount?
		formatted_check_amount.to_f > 0
	end
	
	def is_patpay_check?
		job.payer_group == 'PatPay'
	end

	def is_insurance_check?
		job.payer_group == 'Insurance'
	end
end