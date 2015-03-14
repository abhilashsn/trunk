# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateBatches < ActiveRecord::Migration
  def up
    create_table :batches do |t|
      t.column :batchid, :integer
      t.column :date, :date
      t.column :facility_id, :integer
      t.column :check_volume, :integer
      t.column :arrival_time, :datetime
      t.column :target_time, :datetime
      t.column :status, :string, :default => BatchStatus::NEW
      t.column :eob, :integer
      t.column :deleted_at,  :datetime
      t.column :details, :text
    end
    execute "ALTER TABLE batches ADD CONSTRAINT batches_idfk_1 FOREIGN KEY (facility_id)
              REFERENCES facilities(id)"
  end

  def down
    execute "ALTER TABLE batches DROP FOREIGN KEY batches_idfk_1"
    drop_table :batches
  end
end
