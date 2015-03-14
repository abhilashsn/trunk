module OutputFacilityOutputConfig

	def get_receiver_id
    return "4108           " if self.facility.name == "SOLUTIONS 4 MDS"
    return self.details[:payee_name].justify(15) if self.details[:payee_name].present?
    facility.name.justify(15)
	end
	
end