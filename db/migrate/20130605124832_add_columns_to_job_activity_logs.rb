class AddColumnsToJobActivityLogs < ActiveRecord::Migration
  def change
    add_column :job_activity_logs, :object_name, :string, :limit => 30
    add_column :job_activity_logs, :object_id, :integer
    add_column :job_activity_logs, :field_name, :string, :limit => 30
    add_column :job_activity_logs, :old_value, :string
    add_column :job_activity_logs, :new_value, :string
  end
end
