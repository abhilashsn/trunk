require File.dirname(__FILE__)+'/../test_helper'

class Output835::ClaimPaymentInformationTest < ActiveSupport::TestCase
  fixtures :facilities, :batches, :jobs, :check_informations,  \
       :insurance_payment_eobs 
  
  def setup
    payer = Payer.new
    facility1 = facilities(:facility_merit_mountain)
    facility2 = facilities(:facility_rumc)
    @eob1 = Output835::Eob.new(insurance_payment_eobs(:merit_mountain), facility1, payer, 1, '*')
    @eob2 = Output835::Eob.new(insurance_payment_eobs(:rumc), facility2, payer, 1, '*')
   
    @clp_segment1 = "CLP*#{insurance_payment_eobs(:merit_mountain).patient_account_number}*#{insurance_payment_eobs(:merit_mountain).\
    claim_type_weight}*#{insurance_payment_eobs(:merit_mountain).total_submitted_charge_for_claim}*#{insurance_payment_eobs(:merit_mountain).\
    total_amount_paid_for_claim}*#{merit_mountain_patient_responsibilty_amount}**#{insurance_payment_eobs(:merit_mountain).claim_number}***#{insurance_payment_eobs(:merit_mountain).drg_code}"
    
    
     @clp_segment2 = "CLP*#{insurance_payment_eobs(:rumc).patient_account_number}*#{insurance_payment_eobs(:rumc).\
    claim_type_weight}*#{insurance_payment_eobs(:rumc).total_submitted_charge_for_claim}*#{insurance_payment_eobs(:rumc).\
    total_amount_paid_for_claim}*#{rumc_patient_responsibilty_amount}**#{insurance_payment_eobs(:rumc).claim_number}***#{insurance_payment_eobs(:rumc).drg_code}"
 

  end
 
  def test_service_prov_name
   assert_equal(@clp_segment1, @eob1.claim_payment_information)
   assert_equal(@clp_segment2, @eob2.claim_payment_information)
  end
  
  private
  
  def merit_mountain_patient_responsibilty_amount
  
   tot =  insurance_payment_eobs(:merit_mountain).total_co_insurance + insurance_payment_eobs(:merit_mountain).total_co_pay + insurance_payment_eobs(:merit_mountain).total_deductible
   
    return tot
  end
  
   def rumc_patient_responsibilty_amount
   
     tot =  insurance_payment_eobs(:rumc).total_co_insurance + insurance_payment_eobs(:rumc).total_co_pay + insurance_payment_eobs(:rumc).total_deductible

     return tot
  end
  
end