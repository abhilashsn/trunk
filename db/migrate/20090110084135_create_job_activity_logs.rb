class CreateJobActivityLogs < ActiveRecord::Migration
  def up
    create_table :job_activity_logs do |t|
      t.column :job_id, :integer
      t.column :processor_id, :integer
      t.column :qa_id, :integer
      t.column :allocated_user_id, :integer
      t.column :activity, :text
      t.column :start_time, :datetime
      t.column :end_time, :datetime
    end
  end

  def down
    drop_table :job_activity_logs
  end
end
