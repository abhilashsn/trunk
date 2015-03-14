class CreateOldPasswords < ActiveRecord::Migration
  def up
    create_table :old_passwords do |t|
      t.integer :user_id, :null => false
      t.string :password_hash, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :old_passwords
  end
end
