FactoryGirl.define do 
  factory :client do
    
    name 'ANJ' 
    tat   1234
    group_code 'AJC'
    internal_tat   5678
    partener_bank_group_code 'AJN'
    max_eobs_per_job  10
    max_jobs_per_user_client_wise 5
    max_jobs_per_user_payer_wise 6

  end
  factory :a_client, class: Client do
    
    name 'ANJ1' 
    tat   1234
    group_code 'AJ1'
    internal_tat   5678
    partener_bank_group_code 'AJN'
    max_eobs_per_job  10
    max_jobs_per_user_client_wise 5
    max_jobs_per_user_payer_wise 6

  end
  
  factory :client2, class: Client do
    
    name 'ANJ2' 
    tat   1234
    group_code 'AJ2'
    internal_tat   5678
    partener_bank_group_code 'AJN'
    max_eobs_per_job  10
    max_jobs_per_user_client_wise 5
    max_jobs_per_user_payer_wise 6

  end
  
end