class AddColumnsForOutputPostingToOutputActivityLogs < ActiveRecord::Migration
  def change
    #Migration on OAL , adding check-sum, upload_st_dt_time, upload_end_dt_time & status (GENERATING, GENERATED, UPLOADING, UPLOADED)
    add_column :output_activity_logs, :checksum, :string, :limit => 64
    add_column :output_activity_logs, :update_start_time, :datetime
    add_column :output_activity_logs, :update_end_time, :datetime
    add_column :output_activity_logs, :status, :string, :limit => 32
    remove_column :output_activity_logs, :outbound_file_information_id
  end
end
