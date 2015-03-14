FactoryGirl.define do
  factory :patpay1 , class:Payer do
    id 443
    payer   "Payer43"  
    status   "New"  
    payer_type   "PatPay"  
     payid      4300  
     pay_address_one      "SADSSAD"  
     payer_city      "ELK GROVE VILLAGE"  
     payer_state      "IL"  
     payer_zip      60007  
  end
end