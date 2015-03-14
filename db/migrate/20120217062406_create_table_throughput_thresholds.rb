class CreateTableThroughputThresholds < ActiveRecord::Migration
  def up
    create_table :throughput_thresholds do |t|
      t.column :process_name, :string, :limit => 25
      t.column :threshold_tolerance, :decimal
      t.column :threshold_duration, :time
      t.timestamps
    end
  end

  def down
    drop_table :throughput_thresholds
  end
  
end
