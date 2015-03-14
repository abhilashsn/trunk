class AlterOutputActivityLogs < ActiveRecord::Migration
  def up
    rename_column :output_activity_logs, :update_start_time, :upload_start_time
    rename_column :output_activity_logs, :update_end_time, :upload_end_time
  end

  def down
    rename_column :output_activity_logs, :upload_start_time, :update_start_time
    rename_column :output_activity_logs, :upload_end_time, :update_end_time
  end
end
