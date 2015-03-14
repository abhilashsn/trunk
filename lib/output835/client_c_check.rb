# Check level output customizations for Client C
class Output835::ClientCCheck < Output835::HlscCheck


  def address(party)
    party.address_one ? party.address_one : 'FILE #55725'
    if party.address_one
      address_elements = []
      address_elements << 'N3'
      address_elements << party.address_one
      address_elements.join(@element_seperator)
    end
  end  
end