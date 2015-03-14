# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateUserClientJobHistories < ActiveRecord::Migration
  def up
    create_table :user_client_job_histories do |t|
      t.column :user_id, :integer
      t.column :client_id, :integer
      t.column :job_count, :integer, :default => 0
    end
    execute "ALTER TABLE user_client_job_histories
     ADD CONSTRAINT user_client_job_histories_idfk_1 FOREIGN KEY (user_id)
     REFERENCES users(id)"
    execute "ALTER TABLE user_client_job_histories
     ADD CONSTRAINT user_client_job_histories_idfk_2 FOREIGN KEY (client_id)
     REFERENCES clients(id)"
  end

  def down
    execute "ALTER TABLE user_client_job_histories DROP FOREIGN KEY user_client_job_histories_idfk_1"
    execute "ALTER TABLE user_client_job_histories DROP FOREIGN KEY user_client_job_histories_idfk_2"
    drop_table :user_client_job_histories
  end
end
