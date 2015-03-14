class CreateEraJobs < ActiveRecord::Migration
  def change
    create_table :era_jobs do |t|
      t.string :tracking_number
      t.references :era
      t.string :transaction_hash
      t.references :era_check
      t.string :status
      t.references :client
      t.references :facility
      t.string :payee_name, :limit => 60, :null => false
      t.string :payee_qualifier, :limit => 2, :null => false
      t.string :payee_npi, :limit => 80 
      t.string :payee_tin, :limit => 80
      t.string :payee_planID, :limit => 80
      t.string :payee_address_1, :limit => 55, :null => false
      t.string :payee_address_2, :limit => 55
      t.string :payee_city, :limit => 30, :null => false
      t.string :payee_state, :limit => 2
      t.string :payee_zip, :limit => 15
      t.string :era_addl_payeeid_qualifier, :limit => 2, :null => false
      t.string :era_addl_payeeid, :limit => 50, :null => false

      t.timestamps
    end
    add_index :era_jobs, :era_id
    add_index :era_jobs, :era_check_id
    add_index :era_jobs, :client_id
    add_index :era_jobs, :facility_id
  end
end
