FactoryGirl.define do 
  factory :facility do |fac|
    fac.sequence(:id) { |n| n + 10000 }
    name 'ANJFACI' 
    sitecode 'asdf'
    lockbox_number 0
    state 'DF'
    abbr_name 'df'
    tat 48
    address_one '23234 street'
    city 'SAVANNAH'
    batch_load_type ["C","P"]
    default_service_date 'Check Date'
    client_id Client.first
    zip_code 2345
    default_patient_name "Other"
  end
  
   factory :a_facility, class: Facility do
    
    name 'ANJFACI1' 
    sitecode 'asdaaf'
    lockbox_number 0
    state 'DF'
    abbr_name 'df'
    tat 48
    address_one '23234 street'
    city 'SAVANNAH'
    batch_load_type 'C,P'
    default_service_date 'Check Date'
    client_id Client.first
    zip_code 2345
  end
  
   factory :facility2, class: Facility do
    
    name 'ANJFACI2' 
    sitecode 'asdfff'
    lockbox_number 0
    state 'DF'
    abbr_name 'df'
    tat 48
    address_one '23234 street'
    city 'SAVANNAH'
    batch_load_type 'C,P'
    default_service_date 'Check Date'
    client_id Client.first
    zip_code 2345
  end
  
end