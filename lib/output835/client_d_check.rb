# Check level output customizations for Client A
class Output835::ClientDCheck < Output835::HlscCheck
  #The BPR segment indicates the beginning of a Payment Order/Remittance Advice Transaction
  #Set and total payment amount, or enables related transfer of funds and/or
  #information from payer to payee to occur
  def financial_info
    bpr_elements = []
    bpr_elements << 'BPR'
    bpr_elements << (check.correspondence? ? 'H' : 'I')
    bpr_elements << check_amount
    bpr_elements << 'C'
    bpr_elements << payment_indicator
    bpr_elements << ''
    bpr_elements << id_number_qualifier
    bpr_elements << routing_number if routing_number
    bpr_elements << account_num_indicator
    bpr_elements << account_number
    bpr_elements << (payer.supply_payid.rjust(10, '0') if payer)
    bpr_elements << "999999999"
    bpr_elements << "01"
    bpr_elements << "043000096"
    bpr_elements << "DA"
    bpr_elements << check.batch.facility.client_dda_number
    bpr_elements << check.batch.date.to_s.strip.split('-').join
    bpr_elements.join(@element_seperator)
  end
  def check_amount
    amount = check.check_amount.to_s.to_f
    amount = (amount == (amount.truncate)? amount.truncate : amount)
    amount
  end  
end
