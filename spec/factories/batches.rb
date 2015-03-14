FactoryGirl.define do 
  factory :output_ready, class: Batch do
    
    batchid 'OUTPUT12345'
    status BatchStatus::OUTPUT_READY
    association :facility, factory: :facility
    association :client, factory: :client
  end
  
  factory :batch1, class: Batch do
    
    batchid 'OUTPUT6789'
    status BatchStatus::OUTPUT_READY
    association :facility, factory: :a_facility
    association :client, factory: :a_client
  end
  
  factory :batch2, class: Batch do
    
    batchid 'OUTPUT09876'
    status BatchStatus::OUTPUT_READY
    association :facility, factory: :facility2
    association :client, factory: :client2
  end
  
end
    