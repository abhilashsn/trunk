# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddEobPerHourRateTable < ActiveRecord::Migration
  def up
    create_table :eobrates do |t|
      t.column :high, :integer
      t.column :medium, :integer
      t.column :low, :integer
      t.column :client_id, :integer
    end 
    execute "ALTER TABLE eobrates ADD CONSTRAINT eobrates_idfk_1 FOREIGN KEY (client_id)
            REFERENCES clients(id)"
  end

  def down
    execute "ALTER TABLE eobrates DROP FOREIGN KEY eobrates_idfk_1"
    drop_table :eobrates  
  end
end
