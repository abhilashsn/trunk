class AddFileNameAndFileFormatToOutputActivityLogs < ActiveRecord::Migration
  def up
    add_column :output_activity_logs, :file_name, :string
    add_column :output_activity_logs, :file_format, :string

  end

  def down
    remove_column :output_activity_logs, :file_name
    remove_column :output_activity_logs, :file_format
  end
end
