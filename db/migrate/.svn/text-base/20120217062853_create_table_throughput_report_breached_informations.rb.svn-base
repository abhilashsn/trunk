class CreateTableThroughputReportBreachedInformations < ActiveRecord::Migration
  def up
    create_table :throughput_report_breached_informations do |t|
      t.column :process_name, :string, :limit => 25
      t.column :breached_time, :datetime
      t.column :updated_at, :datetime
    end
  end

  def down
    drop_table :throughput_report_breached_informations
  end
  
end
