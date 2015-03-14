class AddDescriptionToUserActivityLogs < ActiveRecord::Migration
  def change
     add_column :user_activity_logs, :description, :string
  end
end
