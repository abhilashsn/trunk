class CreateTableClientReportedErrors < ActiveRecord::Migration
  def up
    create_table :client_reported_errors do |t|
      t.string :error_type, :limit => 25
      t.string :error_description, :limit => 2000
      t.integer :error_count
      t.integer :eob_count
      t.string :status, :limit => 20
      t.string :source, :limit => 20
      t.string :comment, :limit => 20
      t.date :reported_date
      t.string :site_code, :limit => 15
      t.date :batch_date
      t.string :batchid, :limit => 15
      t.integer :batch_id
      t.string :check_number, :limit => 30
      t.integer :check_informtion_id
      t.string :payid, :limit => 10
      t.integer :payer_id
      t.string :patient_account_number, :limit => 30
      t.integer :insurance_payment_eob_id      
      
      t.timestamps
    end    
  end
  
  def down
    drop_table :client_reported_errors
  end
  
end
