module OutputFacility

	def use_barnabas_parser?
		self.index_file_parser_type == 'Barnabas'
	end
	
	def custom_check_or_eft_trace_facilities
		['AHN', 'SUBURBAN HEALTH', 'UWL', 'ANTHEM']
	end

	def default_lockbox_faclities
		['AVITA HEALTH SYSTEMS', 'METROHEALTH SYSTEM'].include?(self.name.strip.upcase)
	end
	
end
