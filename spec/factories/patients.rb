FactoryGirl.define do
  factory :patient1, class: Patient do
      address_one "GH YUY"
      address_two "BN HJJ"
      zip_code 89898
      city "BHJJJ"
      state "NM"
      association :insurance_payment_eob, factory: :a_patpay
  end
end