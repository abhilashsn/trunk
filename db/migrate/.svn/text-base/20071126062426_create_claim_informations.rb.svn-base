class CreateClaimInformations < ActiveRecord::Migration
  def up
    create_table :claim_informations do |t|
      t.column :patient_first_name, :string ,:limit =>35
      t.column :patient_last_name, :string ,:limit =>30
      t.column :patient_middle_initial, :string ,:limit =>20
      t.column :patient_suffix, :string ,:limit =>20
      t.column :patient_account_number, :string ,:limit =>40
      t.column :insured_id,:string
      t.column :total_charges,:decimal,:precision => 10, :scale => 2
      t.column :billing_provider_tin, :string, :limit => 14
      t.column :billing_provider_npi, :string, :limit => 14
      t.column :billing_provider_address_one, :string, :limit => 100
      t.column :billing_provider_city, :string, :limit => 30
      t.column :billing_provider_state, :string, :limit => 5
      t.column :billing_provider_zipcode, :string, :limit => 10
      t.column :claim_frequency_type_code, :string, :limit => 30
      t.column :payee_name, :string, :limit => 255
      t.column :payee_address_one, :string, :limit => 255
      t.column :payee_city, :string, :limit => 255
      t.column :payee_state, :string, :limit => 255
      t.column :payee_zipcode, :string, :limit => 255
    end
  end

  def down
    drop_table :claim_informations
  end
  def connection
    ClaimInformation.connection
  end
end
