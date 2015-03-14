FactoryGirl.define do
  factory :checkinfo1, class: CheckInformation do
    check_number "456465"
    check_amount 100.00
    association :job, factory: :job1
    association :payer, factory: :patpay1
  end
end