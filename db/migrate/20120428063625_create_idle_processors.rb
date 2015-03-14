class CreateIdleProcessors < ActiveRecord::Migration
  def change
    create_table :idle_processors do |t|
      t.references :user
      t.timestamps
    end
    add_index :idle_processors, :user_id, :name => "by_user_id"
  end
end
