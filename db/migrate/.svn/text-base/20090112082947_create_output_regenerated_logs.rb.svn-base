class CreateOutputRegeneratedLogs < ActiveRecord::Migration
  def up
    create_table :output_regenerated_logs do |t|
      t.column :eob_id, :integer
      t.column :user_id, :integer
      t.column :activity, :text
      t.column :start_time, :datetime
      t.column :end_time, :datetime
    end
  end

  def down
    drop_table :output_regenerated_logs
  end
end
