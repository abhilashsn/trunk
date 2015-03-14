
FactoryGirl.define do 
  factory :an_admin, class: User do
    login 'an_admin'
    email  'admin@anadministrator.com'
    name  'Administrator'
    employee_id '000000'
    password 'testTEST@1234'
    after(:create) do |user|
      user.roles << FactoryGirl.create(:admin_role)
    end
  
  end
  
 factory :a_proc_user, class: User do
    login 'a_processor'
    email  'a_processor@ssdd.com'
    name  'A_Processor'
    employee_id '000000'
    password 'testTEST@1234'
    
    after(:create) do |user|
      user.roles << FactoryGirl.build_list(:processor_role, 200)
    end
  
  end
  
  factory :a_partner_user, class: User do
    login 'a_partner'
    email  'a_partner@ssdd.com'
    name  'A_Partner'
    employee_id '000000'
    password 'testTEST@1234'
    
    after(:create) do |user|
      user.roles << FactoryGirl.build_list(:partner_role, 99)
    end
  
  end
  
  factory :a_client_user, class: User do
    login 'a_client'
    email  'a_client@sssdd.com'
    name  'A_Client'
    employee_id '000000'
    password 'testTEST@1234'
    after(:create) do |user|
      user.roles << FactoryGirl.build_list(:client_role,100)
    end    
    
  end
  
  factory :a_facility_user, class: User do
    login 'a_facility'
    email  'a_facility@ssAdd.com'
    name  'A_Facility'
    employee_id '000000'
    password 'testTEST@1234'
    
    after(:create) do |user|
      user.roles << FactoryGirl.build_list(:facility_role,100)
    end    
  end
  
  
end
