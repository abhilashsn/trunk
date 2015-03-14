require 'erb'
require 'ostruct'

# A class to assist in turning a hash into a binding (for erb rendering)
class HashBinding < OpenStruct

  def get_binding
    binding
  end

  def pad_left(txt, total_length = 8)
    pad_amount = total_length - txt.length
    (' ' * pad_amount) + txt
  end

  def pad_right(txt, total_length = 41)
    pad_amount = total_length - txt.length
    txt + (' ' * pad_amount)
  end

  def center(txt, width = 80)
    margin = ' ' * ((width - txt.length)/2)
    margin + txt + margin
  end

end


template= <<eos
                              Texas, Blue Cross Comml
<%= center(title) %>


TEST FACILITY                             FPE :   /  /
<%= pad_right(facility_name) %> FPE :  <%= fpe_date %>
<%= pad_right(facility_address) %> PAID : <%= paid_date %>
BLANK, US 00000                          CLM# : 1234A5678BC
NPI:               PROV# 999999999        TOB :
================================================================================
 PATIENT: <%= pad_right('999999',20) %>    APATIENT            PCN: 11111-22222222-3333
     HIC: Z44444444             SVC FROM: 07/13/2010  MRN:
PAT STAT:    CLAIM STAT: 2          THRU: 07/13/2010  ICN: 77777777777
================================================================================
CHARGES:                       PAYMENT DATA:             <%= pad_left(ncvd_denied_amount)%>=REIM RATE
    <%= pad_left(reported_amount)%>=REPORTED         <%= pad_left(drg_amount)%>=DRG AMOUNT        <%=pad_left(msp_prim_payer)%>=MSP PRIM PAYER
    <%= pad_left(ncvd_denied_amount)%>=NCVD/DENIED          0.00=DRG/OPER/CAP          0.00=PROF COMPONENT
    <%= pad_left(ncvd_denied_amount)%>=CLAIM ADJS       <%= pad_left(ncvd_denied_amount)%>=LINE ADJ AMT      <%= pad_left(ncvd_denied_amount)%>=ESRD AMOUNT
    <%= pad_left(ncvd_denied_amount)%>=COVERED          <%= pad_left(ncvd_denied_amount)%>=OUTLIER           <%= pad_left(ncvd_denied_amount)%>=PROC CD AMOUNT
DAYS/VISITS                   <%= pad_left(ncvd_denied_amount)%>=CAP OUTLIER       <%= pad_left(ncvd_denied_amount)%>=ALLOW/REIM
    <%= pad_left(ncvd_denied_amount)%>=COST REPT        <%= pad_left(ncvd_denied_amount)%>=CASH DEDUCT       <%= pad_left(ncvd_denied_amount)%>=G/R AMOUNT
    <%= pad_left(ncvd_denied_amount)%>=COVD/UTIL        <%= pad_left(ncvd_denied_amount)%>=BLOOD DEDUCT      <%= pad_left(ncvd_denied_amount)%>=INTEREST
    <%= pad_left(ncvd_denied_amount)%>=NON-COVERED      <%= pad_left(ncvd_denied_amount)%>=COINSURANCE       <%= pad_left(ncvd_denied_amount)%>=CONTRACTUAL ADJUSTMENT
    <%= pad_left(ncvd_denied_amount)%>=COVD VISITS      <%= pad_left(ncvd_denied_amount)%>=PAT REFUND        <%= pad_left(ncvd_denied_amount)%>=PER DIEM AMT
    <%= pad_left(ncvd_denied_amount)%>=NCOV VISITS      <%= pad_left(ncvd_denied_amount)%>=MSP LIAB MET      <%= pad_left(ncvd_denied_amount)%>=NET REIM AMT
ADJ REASON CODES:
  <%= yield %>
REMARK CODES:
---------------------------------------------------------------------------------------------------------
eos

vars = {
  :title => 'Texas, Blue Cross Comml',
  :facility_name => 'TEST FACILITY',
  :facility_address => '1000 BLANK DRIVEWAY',
  :fpe_date => ' / /',
  :paid_date => '04/21/09',
  :reported_amount => '192.50',
  :ncvd_denied_amount => '7.07',
  :drg_amount => '0.00',
  :msp_prim_payer => '108.34'
}

text = ''
puts ERB.new(template,0).result(HashBinding.new(vars).get_binding { text })
