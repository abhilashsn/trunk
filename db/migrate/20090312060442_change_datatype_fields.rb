class ChangeDatatypeFields < ActiveRecord::Migration
  def up
    change_column :client_activity_logs, :activity, :string
    change_column :job_activity_logs, :activity, :string
    change_column :output_activity_logs, :activity, :string
    change_column :output_regenerated_logs, :activity, :string
  end

  def down
  end
end
