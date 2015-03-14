class RemoveUnwantedTables < ActiveRecord::Migration
  def up
     drop_table :payerwise_check_informations
     drop_table :user_client_job_histories
     drop_table :user_payer_job_histories
     drop_table :client_status_histories
     drop_table :certifications
  end

  def down
  end
end
