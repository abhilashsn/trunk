module DcGrid
  def upcase_grid_data(exempted_columns = [])
    self.attributes.each_pair do |k,v|
      eval("self.#{k}.upcase!") if v.is_a?(String) && !exempted_columns.include?(k)
    end
  end
end
