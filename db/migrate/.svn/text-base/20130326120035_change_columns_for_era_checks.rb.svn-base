class ChangeColumnsForEraChecks < ActiveRecord::Migration
  def up
    change_table :era_checks do |t|
      t.change :transaction_set_control_number, :string, :limit => 9, :null => true
      t.change :transaction_handling_code, :string, :limit => 2, :null => true
      t.change :check_amount, :decimal, :precision => 18, :scale => 2, :null => true
      t.change :credit_debit_flag, :string, :limit => 1, :null => true
      t.change :payment_method, :string, :limit => 3, :null => true
      t.change :check_date, :date, :null => true
      t.change :check_number, :string, :limit => 50, :null => true
      t.change :trn_payer_company_identifier, :string, :limit => 10, :null => true
      t.change :site_receiver_identification, :string, :limit => 50, :null => true
      t.change :production_date, :date, :null => true
      t.change :payer_name, :string, :limit => 60, :null => true
      t.change :payer_address_1, :string, :limit => 55, :null => true
      t.change :payer_city, :string, :limit => 30, :null => true
      t.change :era_payid_qualifier, :string, :limit => 2, :null => true
      t.change :era_payid, :string, :limit => 50, :null => true
    end
  end

  def down
    change_table :era_checks do |t|
      t.change :transaction_set_control_number, :string, :limit => 9, :null => false
      t.change :transaction_handling_code, :string, :limit => 2, :null => false
      t.change :check_amount, :decimal, :precision => 18, :scale => 2, :null => false
      t.change :credit_debit_flag, :string, :limit => 1, :null => false
      t.change :payment_method, :string, :limit => 3, :null => false
      t.change :check_date, :date, :null => false
      t.change :check_number, :string, :limit => 50, :null => false
      t.change :trn_payer_company_identifier, :string, :limit => 10, :null => false
      t.change :site_receiver_identification, :string, :limit => 50, :null => false
      t.change :production_date, :date, :null => false
      t.change :payer_name, :string, :limit => 60, :null => false
      t.change :payer_address_1, :string, :limit => 55, :null => false
      t.change :payer_city, :string, :limit => 30, :null => false
      t.change :era_payid_qualifier, :string, :limit => 2, :null => false
      t.change :era_payid, :string, :limit => 50, :null => false
    end
  end
end