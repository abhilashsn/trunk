class RichmondUniversityMedicalCenterGenerator < Unified835Output::Generator

	def transaction_sets
		@facility_level_details.merge!(:check_nums => @checks.map(&:check_number))
		super
	end

	#Start of ISA Segment Details
	#End of ISA Segment Details

  #Start of GS Segment Details
  	def group_date(*options)
  		@checks.first.batch.date.strftime("%Y%m%d")
  	end
  #End of GS Segment Details

end