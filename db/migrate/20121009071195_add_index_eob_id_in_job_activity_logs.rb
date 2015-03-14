class AddIndexEobIdInJobActivityLogs < ActiveRecord::Migration
  def change
    add_index :job_activity_logs, :eob_id, :name => "idx_job_activity_logs_eob_id"
  end
end

