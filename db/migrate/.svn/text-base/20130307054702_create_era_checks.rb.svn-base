class CreateEraChecks < ActiveRecord::Migration
  def change
    create_table :era_checks do |t|
      t.string :transaction_hash
      t.integer :era_id
      t.string :tracking_number
      t.string "835_single_location"
      t.string :status
      t.string :transaction_set_control_number, :limit => 9, :null => false
      t.string :transaction_handling_code, :limit => 2, :null => false
      t.decimal :check_amount, :precision => 18, :scale => 2, :null => false
      t.string :credit_debit_flag, :limit => 1, :null => false
      t.string :payment_method, :limit => 3, :null => false
      t.string :payment_format_code, :limit => 10
      t.string :payer_routing_qualifier, :limit => 2
      t.string :aba_routing_number, :limit => 12
      t.string :payer_account_qualifier, :limit => 3
      t.string :payer_account_number, :limit => 35
      t.string :payer_company_identifier, :limit => 10
      t.string :payer_company_supplemental_code, :limit => 9
      t.string :site_routing_qualifier, :limit => 2
      t.string :site_routing_number, :limit => 12
      t.string :site_account_qualifier, :limit => 3
      t.string :site_account_number, :limit => 35
      t.date :check_date, :null => false
      t.string :check_number, :limit => 50, :null => false
      t.string :trn_payer_company_identifier, :limit => 10, :null => false
      t.string :trn_payer_company_supplemental_code, :limit => 50
      t.string :site_receiver_identification, :limit => 50, :null => false
      t.date :production_date, :null => false
      t.string :payer_name, :limit => 60, :null => false
      t.string :payer_npi, :limit => 80
      t.string :payer_address_1, :limit => 55, :null => false
      t.string :payer_address_2, :limit => 55
      t.string :payer_city, :limit => 30, :null => false
      t.string :payer_state, :limit => 2
      t.string :payer_zip, :limit => 15
      t.string :era_payid_qualifier, :limit => 2, :null => false
      t.string :era_payid, :limit => 50, :null => false
      t.string :era_misc_check_segments
      t.timestamps
    end
  end
end
