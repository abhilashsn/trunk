# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class CreateCertifications < ActiveRecord::Migration
  def up
    create_table :certifications do |t|
      t.column :user_id, :integer
      t.column :client_id, :integer
      t.column :date, :date
    end
    execute "ALTER TABLE certifications ADD CONSTRAINT certifications_idfk_1 FOREIGN KEY (user_id)
            REFERENCES users(id)"
    execute "ALTER TABLE certifications ADD CONSTRAINT certifications_idfk_2 FOREIGN KEY (client_id)
            REFERENCES clients(id)"
  end

  def down
    execute "ALTER TABLE certifications DROP FOREIGN KEY certifications_idfk_1"
    execute "ALTER TABLE certifications DROP FOREIGN KEY certifications_idfk_2"
    drop_table :certifications
  end
end
