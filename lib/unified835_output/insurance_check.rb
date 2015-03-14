class Unified835Output::InsuranceCheck < CheckInformation

	def is_patient_check?
		false
	end

	def is_insurance_check?
		true
	end 

	def get_supplemental_amount(service)
		service.amount('service_allowable') unless service.service_allowable.to_f.zero?
	end
end