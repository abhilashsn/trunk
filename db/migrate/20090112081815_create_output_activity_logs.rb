class CreateOutputActivityLogs < ActiveRecord::Migration
  def up
    create_table :output_activity_logs do |t|
      t.column :batch_id, :integer
      t.column :user_id, :integer
      t.column :activity, :text
      t.column :start_time, :datetime
      t.column :end_time, :datetime
    end
  end

  def down
    drop_table :output_activity_logs
  end
end
