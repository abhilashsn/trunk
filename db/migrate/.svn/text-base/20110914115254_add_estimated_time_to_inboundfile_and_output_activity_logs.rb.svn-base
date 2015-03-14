class AddEstimatedTimeToInboundfileAndOutputActivityLogs < ActiveRecord::Migration
  def up
    add_column :output_activity_logs, :estimated_time, :string, :limit=>64
    add_column :inbound_file_informations, :estimated_time, :string, :limit=>64
  end

  def down
    remove_column :output_activity_logs, :estimated_time
    remove_column :inbound_file_informations, :estimated_time
  end
end
