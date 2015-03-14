class CreateTableThroughputReports < ActiveRecord::Migration
  def up
    create_table :throughput_reports do |t|
      t.column :process_name, :string, :limit => 25
      t.column :queue_volume, :integer
      t.column :processing_volume, :integer
      t.column :completed_volume, :integer
      t.column :status, :string, :limit => 50
      t.column :threshold_tolerance, :decimal
      t.column :current_tolerance, :decimal
      t.column :threshold_duration, :time
      t.column :current_duration, :time
      t.column :partner_name, :string, :limit => 25
      t.column :client_name, :string, :limit => 50
      t.references :client
      t.column :facility_name, :string, :limit => 100
      t.references :facility
      t.column :lockbox_name, :string, :limit => 50
      t.references :facility_lockbox_mappings
      t.column :batch_type, :string, :limit => 20
      t.column :current, :boolean
      t.timestamps
    end
  end

  def down
    drop_table :throughput_reports
  end
  
end
