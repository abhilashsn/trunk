class Unified835Output::PatientCheck < CheckInformation
	
	def is_patient_check?
		true
	end

	def is_insurance_check?
		false
	end 

	def get_supplemental_amount(service)
		service.amount('service_paid_amount') unless service.service_paid_amount.to_f.zero?
	end
end