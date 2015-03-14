class CreateClientsUsers < ActiveRecord::Migration
  def up
    create_table :clients_users do |t|
      t.column :client_id, :integer
      t.column :user_id, :integer     
    end
    execute "ALTER TABLE clients_users ADD CONSTRAINT clients_users_idfk_1 FOREIGN KEY (client_id)
        REFERENCES clients(id)"
    execute "ALTER TABLE clients_users ADD CONSTRAINT clients_users_idfk_2 FOREIGN KEY (user_id)
        REFERENCES users(id)"
  end

  def down
    execute "ALTER TABLE clients_users DROP FOREIGN KEY clients_users_idfk_1"
    execute "ALTER TABLE clients_users DROP FOREIGN KEY clients_users_idfk_2"
    drop_table :clients_users
  end
end
