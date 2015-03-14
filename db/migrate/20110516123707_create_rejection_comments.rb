class CreateRejectionComments < ActiveRecord::Migration
  def up
    create_table :rejection_comments do |t|
      t.string :name
      t.integer :client_id

      t.timestamps
    end
  end

  def down
    drop_table :rejection_comments
  end
end
