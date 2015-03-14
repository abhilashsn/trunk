class CreateFacilitiesUsers < ActiveRecord::Migration
  def up
    create_table :facilities_users do |t|
       t.column :facility_id, :integer
        t.column :user_id, :integer     
     end
    add_index :facilities_users, :facility_id
    add_index :facilities_users, :user_id
  end

  def down
    drop_table :facilities_users
  end
end
