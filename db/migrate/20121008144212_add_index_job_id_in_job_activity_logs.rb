class AddIndexJobIdInJobActivityLogs < ActiveRecord::Migration
  def change
    add_index :job_activity_logs, :job_id
  end
end
