FactoryGirl.define do 
  factory :a_partner_u, class: PartnersUser do
    association :partner, factory: :a_partner
  end
end