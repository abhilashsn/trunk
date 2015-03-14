class Output835::NetwrxDocument < Output835::Document

  def functional_group_trailer(batch_id)
    ge_elements = []
    ge_elements << 'GE' << checks_in_functional_group(batch_id) << '2831'
    ge_elements.join(@element_seperator)
  end
end