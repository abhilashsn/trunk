module CustomException

	class FacilityLevelError < StandardError
		def initialize(facility, message)
			@facility = facility
			super(formatted_exception_message(message))
		end

		def formatted_exception_message(m)
			exception_hash = {}
			exception_hash.merge!(:message => m)
			exception_hash.merge!(:facility_details => @facility.inspect)
			return exception_hash
		end
	end

	class CheckLevelException < Exception
		def initialize(facility, check, message)
			@facility = facility
			@check = check
			super(formatted_exception_message(message))
		end

		def formatted_exception_message(m)
			exception_hash = {}
			exception_hash.merge!(:message => m)
			exception_hash.merge!(:facility_details => @facility.inspect)
			exception_hash.merge!(:check_details => @check.inspect)
			return exception_hash
		end

	end

end