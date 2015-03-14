class CreateEobsOutputActivityLogs < ActiveRecord::Migration
  def up
    create_table :eobs_output_activity_logs do |t|
      t.integer :output_activity_log_id
      t.integer :insurance_payment_eob_id
      t.integer :patient_pay_eob_id
    end
  end
  
  def down
    drop_table :eobs_output_activity_logs
  end
end
