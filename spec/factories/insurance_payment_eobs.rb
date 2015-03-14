FactoryGirl.define do 
  factory :a_patpay, class: InsurancePaymentEob do  
     claim_type  "P"
     start_time  Time.new(2014,01,25,07,52,39)
     total_edited_fields  0
     patient_last_name  "HEAVILAND"
     facility_type_code  11
     patient_first_name  "DEBRA"
     patient_middle_initial "DF" 
     patient_account_number "06122469" 
     patient_suffix  "AS"
     subscriber_identification_code  104283689899
     place_of_service  11
     plan_type  "MC"
     subscriber_last_name  "HEAVILAND"
     subscriber_first_name  "DEBRA"
     provider_organisation  "GOODMAN CAMPBELL BRAIN AND SPINE"
     rendering_provider_first_name  "CHRISTOPHER"
     rendering_provider_middle_initial  "M"
     provider_tin  351278550
     total_submitted_charge_for_claim  10.00
     total_allowable  10.00
     total_amount_paid_for_claim  10.00
     total_non_covered  0.00
     total_discount  0.00
     total_co_insurance  0.00
     total_deductible  0.00
     total_co_pay  0.00
     total_primary_payer_amount  0.00
     total_contractual_amount  0.00
     total_service_balance  0.00
     document_classification  "EOB"
     image_page_no  1
     image_page_to_number  1  
     association :check_information, factory: :checkinfo1
  end
end
    