# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateClientStatusHistories < ActiveRecord::Migration
  def up
    create_table :client_status_histories do |t|
      t.column :batch_id, :integer
      t.column :time, :datetime
      t.column :status, :string
      t.column :user, :string
    end
    execute "ALTER TABLE client_status_histories ADD CONSTRAINT client_status_histories_idfk_1 FOREIGN KEY (batch_id)
            REFERENCES batches(id)"
  end

  def down
    execute "ALTER TABLE client_status_histories DROP FOREIGN KEY client_status_histories_idfk_1"
    drop_table :client_status_histories
  end
end
