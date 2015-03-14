class Output835::AhnSingleStCheck < Output835::SingleStCheck
  
  # For all AHN clients value "AHN" in N1*PR
  def payer_identification(payer)
    elements = []
    elements << 'N1'
    elements << 'PR'
    elements << 'AHN'
    elements.join(@element_seperator)
  end
end
