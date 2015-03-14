
FactoryGirl.define do 
  factory :admin_role, class: Role do
    name 'admin'
  end
  
  factory :processor_role, class: Role do
    name 'processor'
  end

  factory :partner_role, class: Role do
    name 'partner'
  end

  factory :client_role, class: Role do
    name 'client'
  end

  factory :facility_role, class: Role do
    name 'facility'
  end
end
