require File.dirname(__FILE__) + '/../test_helper'

class XpeditorNumberTest < ActiveSupport::TestCase
  fixtures :insurance_payment_eobs, :check_informations,:claim_informations,:service_payment_eobs
  def test_service_line_item_control_num
    service = service_payment_eobs(:service_line_2226)
    index = service.insurance_payment_eob.service_payment_eobs.length
    service_claim = service.insurance_payment_eob.claim_information
    xpeditor_document_number = service_claim.xpeditor_document_number if service_claim
    unless xpeditor_document_number.blank? || xpeditor_document_number == "0"
      elements = []
      service_index_number = index.to_s.rjust(4 ,'0')
      elements << 'REF'
      elements << '6R'
      elements << xpeditor_document_number+service_index_number
      elements.join("~")
    end
    assert_equal ["REF","6R","12345A0001"],elements
  end
end
