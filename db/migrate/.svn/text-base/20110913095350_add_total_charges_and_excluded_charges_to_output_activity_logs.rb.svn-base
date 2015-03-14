class AddTotalChargesAndExcludedChargesToOutputActivityLogs < ActiveRecord::Migration
  def up
    add_column :output_activity_logs, :total_charge, :decimal,:precision => 10, :scale => 2
    add_column :output_activity_logs, :total_excluded_charge, :decimal,:precision => 10, :scale => 2
  end

  def down
    remove_column :output_activity_logs, :total_charge
    remove_column :output_activity_logs, :total_excluded_charge
  end
end
