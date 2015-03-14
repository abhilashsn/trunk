class Output835::AhnSingleStTemplate < Output835::SingleStTemplate

  # For all AHN clients value "AHN" in N1*PR
  def payer_identification(payer)
    ['N1', 'PR', 'AHN'].join(@element_seperator)
  end
  
end
