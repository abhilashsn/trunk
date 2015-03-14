class CreateClientOutputConfigs < ActiveRecord::Migration
  def change
    create_table :client_output_configs do |t|
      t.column :client_id, :integer
      t.column :eob_type, :string
      t.column :report_type, :string, :limit => "50"
      t.column :operation_log_config, :text
      t.timestamps
    end
  end
end
