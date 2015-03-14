# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateTat < ActiveRecord::Migration
  def up
    create_table :tats do |t|
      t.column :expected_time, :datetime
      t.column :comments, :string
      t.column :batch_id, :integer
    end
    execute "ALTER TABLE tats ADD CONSTRAINT tats_idfk_1  FOREIGN KEY (batch_id)
           REFERENCES batches(id)"
  end

  def down
    execute "ALTER TABLE tats DROP FOREIGN KEY tats_idfk_1"
    drop_table :tats
  end
end
