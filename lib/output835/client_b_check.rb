# Check level output customizations for Client C
class Output835::ClientBCheck < Output835::HlscCheck
  def payee_identification(payee)
    elements = []
    elements << 'N1'
    elements << 'PE'
    if @facility_config.details[:payee_name] && !@facility_config.details[:payee_name].blank?
      n1_pe_02 = @facility_config.details[:payee_name].strip.upcase
    else
      n1_pe_02 = payee.name.strip.upcase
    end
    elements << n1_pe_02
    if !payer.payer_tin.blank?
      elements << 'FI'
      elements << payer.payer_tin
    elsif !payee.facility_npi.blank?
      elements << 'XX'
      elements << payee.facility_npi
    else
      elements << 'XX'
      elements << '1801992631'
    end
    elements.join(@element_seperator)
  end
end
