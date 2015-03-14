class AddEstimatedEndTimeToOutputActivityLogs < ActiveRecord::Migration
  def up
    add_column :output_activity_logs, :estimated_end_time, :datetime
    remove_column :output_activity_logs, :estimated_time
  end

  def down
    remove_column :output_activity_logs, :estimated_end_time
    add_column :output_activity_logs, :estimated_time, :string, :limit=>64
  end
end
