class ChangedTheTimeStampColumnOfUserActivityLogs < ActiveRecord::Migration
  def up
    remove_column :user_activity_logs, :created_at
    remove_column :user_activity_logs, :updated_at
    add_column :user_activity_logs, :performed_at, :datetime

    execute <<-SQL
      ALTER TABLE user_activity_logs
        ADD CONSTRAINT fk_user_id
        FOREIGN KEY (user_id)
        REFERENCES users(id)
      SQL
    
  end

  def down    
    execute "ALTER TABLE user_activity_logs DROP FOREIGN KEY fk_user_id"
    add_column :user_activity_logs, :created_at, :datetime
    add_column :user_activity_logs, :updated_at, :datetime
    remove_column :user_activity_logs, :performed_at
  end
  
end
