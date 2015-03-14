class AddFileLocationAndFileSizeToOutputActivityLogs < ActiveRecord::Migration
  def up
    add_column :output_activity_logs, :file_location, :string
    add_column :output_activity_logs, :file_size, :int
  end

  def down
    remove_column :output_activity_logs, :file_location
    remove_column :output_activity_logs, :file_size
  end
end
