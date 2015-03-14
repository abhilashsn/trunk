class Unified835Output::BenignNull
	def method_missing(*args, &block)
		self
	end

	def nil?
		true
	end

	def to_ary
		[]
	end
end