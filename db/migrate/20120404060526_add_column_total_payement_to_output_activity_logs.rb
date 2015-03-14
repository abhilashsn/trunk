class AddColumnTotalPayementToOutputActivityLogs < ActiveRecord::Migration
  def change
    add_column :output_activity_logs, :total_payment_charge, :decimal, :precision => 10, :scale => 2
  end
end
