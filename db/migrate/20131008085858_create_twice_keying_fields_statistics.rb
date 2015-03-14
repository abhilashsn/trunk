class CreateTwiceKeyingFieldsStatistics < ActiveRecord::Migration
  def change
    create_table :twice_keying_fields_statistics do |t|
      t.string :field_name, :limit => 30
      t.integer :processor_id
      t.boolean :first_attempt_status
      t.datetime :date_of_keying
      t.integer :client_id
      t.integer :facility_id
      t.date :batch_date
      t.string :batchid, :limit => 100
      t.string :payid, :limit => 20
      t.string :payer_name, :limit => 80
      t.string :check_number, :limit => 50
      t.string :patient_account_number, :limit => 50
      t.datetime :created_at
    end

    add_index :twice_keying_fields_statistics, :processor_id, :name => 'by_processor_id'
    add_index :twice_keying_fields_statistics, :client_id, :name => 'by_client_id'
    add_index :twice_keying_fields_statistics, :facility_id, :name => 'by_facility_id'
  end
end
