class CreatePartnersUsers < ActiveRecord::Migration
  def up
    create_table :partners_users do |t|
      t.column :partner_id, :integer
      t.column :user_id, :integer     
    end
    execute "ALTER TABLE partners_users ADD CONSTRAINT partners_users_idfk_1 FOREIGN KEY (partner_id)
          REFERENCES partners(id)"
    execute "ALTER TABLE partners_users ADD CONSTRAINT partners_users_idfk_2 FOREIGN KEY (user_id)
          REFERENCES users(id)"
  end

  def down
    execute "ALTER TABLE partners_users DROP FOREIGN KEY partners_users_idfk_1"
    execute "ALTER TABLE partners_users DROP FOREIGN KEY partners_users_idfk_2"
    drop_table :partners_users
  end
end

