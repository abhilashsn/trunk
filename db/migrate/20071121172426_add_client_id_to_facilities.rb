# Copyright (c) 2007. RevenueMed, Inc. All rights reserved.

class AddClientIdToFacilities < ActiveRecord::Migration
  def up    
    add_column "facilities", "client_id", :integer 
    # add_foreign_key(:facilities, :client_id, :clients, :id ,:name => :fk_client_id)

    #add a foreign key
    execute <<-SQL
      ALTER TABLE facilities
        ADD CONSTRAINT fk_client_id
        FOREIGN KEY (client_id)
        REFERENCES clients(id)
    SQL

  end

  def down
    execute "ALTER TABLE facilities DROP FOREIGN KEY fk_client_id"
    # remove_foreign_key :facilities, :fk_client_id
    remove_column "facilities", "client_id"
  end
end
