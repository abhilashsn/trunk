# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateUserPayerJobHistories < ActiveRecord::Migration
  def up
    create_table :user_payer_job_histories do |t|
      t.column :user_id, :integer
      t.column :payer_id, :integer
      t.column :job_count, :integer, :default => 0
    end
    execute "ALTER TABLE user_payer_job_histories ADD CONSTRAINT user_payer_job_histories_idfk_1 FOREIGN KEY (user_id)
           REFERENCES users(id)"
    execute "ALTER TABLE user_payer_job_histories ADD CONSTRAINT user_payer_job_histories_idfk_2 FOREIGN KEY (payer_id)
           REFERENCES payers(id)"
  end

  def down
   execute "ALTER TABLE user_payer_job_histories DROP FOREIGN KEY user_payer_job_histories_idfk_1"
   execute "ALTER TABLE user_payer_job_histories DROP FOREIGN KEY user_payer_job_histories_idfk_2"
    drop_table :user_payer_job_histories
  end
end
