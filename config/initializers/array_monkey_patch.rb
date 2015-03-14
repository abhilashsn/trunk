class Array
  alias_method :original_to_s, :to_s
  def to_s
    if self.size == 1
      self.join
    else
      original_to_s
    end
  end
end
