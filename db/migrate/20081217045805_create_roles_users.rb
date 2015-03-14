class CreateRolesUsers < ActiveRecord::Migration
  def up
     create_table "roles_users", :force => true do |t|
        t.column :role_id, :integer
        t.column :user_id, :integer        
    end
    add_index :roles_users, :role_id
    add_index :roles_users, :user_id
    
  end

  def down
     drop_table "roles_users"
  end
end
