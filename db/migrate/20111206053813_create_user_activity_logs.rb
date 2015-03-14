class CreateUserActivityLogs < ActiveRecord::Migration
  def change
    create_table :user_activity_logs do |t|
      t.references :user
      t.column :role, :string, :limit => 45
      t.column :activity, :string, :limit => 45
      t.column :entity_id, :integer
      t.column :entity_name, :string, :limit => 45
      t.timestamps
    end
  end
end
