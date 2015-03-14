# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateJobs < ActiveRecord::Migration
  def up
    create_table :jobs do |t|
      t.column :batch_id, :integer
      t.column :check_number, :string
      t.column :tiff_number, :string
      t.column :count, :integer
      t.column :status, :string, :default => ProcessorStatus::NEW
      t.column :user_id, :integer
      t.column :processor_flag_time, :datetime
      t.column :processor_target_time, :datetime
      t.column :qa_flag_time, :datetime
      t.column :qa_target_time, :datetime
      t.column :deleted_at,  :datetime
      t.column :details, :text
    end
    execute "ALTER TABLE jobs ADD CONSTRAINT jobs_idfk_1  FOREIGN KEY (batch_id)
           REFERENCES batches(id)"
  end

  def down
     execute "ALTER TABLE jobs DROP FOREIGN KEY jobs_idfk_1"
    drop_table :jobs
  end
end
