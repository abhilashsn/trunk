class CreateThroughputSummaryReport < ActiveRecord::Migration
  def up
    create_table :throughput_report do |t|
        t.column :category, :string, :limit => 10
        t.column :arrival_date, :date
        t.column :queued_vol,  :integer
        t.column :queued_size,  :integer
        t.column :inproc_vol,  :integer
        t.column :inproc_size,  :integer
        t.column :category_count,  :integer
        t.column :completed_vol, :integer
        t.column :estimated_completion, :datetime
        t.column :processing_status, :string
        t.column :tolerance_threshold, :decimal, :precision => 10, :scale => 2
        t.column :current_tolerance, :decimal, :precision => 10, :scale => 2
        t.column :duration_threshold, :time
        t.column :current_duration, :time
        t.timestamps
    end
  end
  def down
    drop_table :throughput_report
  end
end
