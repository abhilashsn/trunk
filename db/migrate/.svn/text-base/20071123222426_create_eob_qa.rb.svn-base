# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateEobQa < ActiveRecord::Migration
  def up
    create_table :eob_qas do |t|
      t.column :processor_id, :integer
      t.column :qa_id, :integer
      t.column :job_id, :integer
      t.column :time_of_rejection, :datetime
      t.column :account_number, :string
      t.column :total_fields, :integer
      t.column :total_incorrect_fields, :integer
      t.column :status, :string
      t.column :total_qa_checked, :integer
      t.column :comment, :string
    end
    execute "ALTER TABLE eob_qas ADD CONSTRAINT eob_qas_idfk_1 FOREIGN KEY (job_id)
              REFERENCES jobs(id)"
  end

  def down
    execute "ALTER TABLE eob_qas DROP FOREIGN KEY eob_qas_idfk_1"
    drop_table :eob_qas
  end
end
