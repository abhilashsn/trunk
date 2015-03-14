FactoryGirl.define do
  factory :job1, class: Job do
      processor_id     4
      tiff_number      20080403678
      qa_id            5
      count            3
      estimated_eob    20
      job_status       "COMPLETED"
      pages_to         5
      check_number 456465
      association :batch, factory: :batch1
   end

end