# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateHlscQas < ActiveRecord::Migration
  def up
    create_table :hlsc_qas do |t|
      t.column :batch_id, :integer
      t.column :user_id, :integer
      t.column :total_eobs, :integer
      t.column :rejected_eobs, :integer
    end
    execute "ALTER TABLE hlsc_qas ADD CONSTRAINT hlsc_qas_idfk_1 FOREIGN KEY (batch_id)
              REFERENCES batches(id)"
    execute "ALTER TABLE hlsc_qas ADD CONSTRAINT hlsc_qas_idfk_2 FOREIGN KEY (user_id)
              REFERENCES users(id)"
  end

  def down
    execute "ALTER TABLE hlsc_qas DROP FOREIGN KEY hlsc_qas_idfk_1"
    execute "ALTER TABLE hlsc_qas DROP FOREIGN KEY hlsc_qas_idfk_2"
    drop_table :hlsc_qas
  end
end
