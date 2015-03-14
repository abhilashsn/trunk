class CreateClientActivityLogs < ActiveRecord::Migration
  def up
    create_table :client_activity_logs do |t|
      t.column :user_id, :integer
      t.column :activity, :text
      t.column :start_time, :datetime
      t.column :end_time, :datetime
      t.column :job_id, :integer
      t.column :eob_id, :integer
      t.column :eob_type, :string
    end
  end

  def down
    drop_table :client_activity_logs
  end
end
