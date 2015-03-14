class AddAckLatestCountToOutputActivityLogs < ActiveRecord::Migration
  def change
    add_column :output_activity_logs, :ack_latest_count, :integer
  end
end
