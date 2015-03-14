module Unified835Output::ExtendedBaseClass
end

class Array

	def remove_empty_segments
		self.select{|segment| segment.present?}
	end

	def trim_empty_segments_in_end
		return self if self.empty?
    while self.last.blank?
      self.pop
    end
    self.collect {|element| element.to_s}
	# 	return self if self.empty?
	# 	value_array = self.reverse
	# 	value_array.each_with_index do |value, index|
	# 		break if value.present?
	# 		value_array.delete_at(index) if value.nil?
	# 	end
	# 	value_array.reverse
	end

end

class String

	def convert_to_method
		self.downcase.gsub(' ','_')
	end

end

class Date

	def output_date_format
		self.strftime("%Y%m%d")
	end

end

class Time

	def output_date_format
		self.strftime("%Y%m%d")
	end

end