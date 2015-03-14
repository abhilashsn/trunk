class AddIndexBatchIdAndAckLatestCountToOutputActivityLogs < ActiveRecord::Migration
  def change
    add_index :output_activity_logs, [:batch_id, :ack_latest_count], :name => 'index_output_activity_logs_on_batch_id_ack_latest_count'
  end
end
