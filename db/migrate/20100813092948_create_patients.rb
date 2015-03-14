class CreatePatients < ActiveRecord::Migration
  def up
    create_table :patients do |t|
      t.integer :insurance_payment_eob_id
      t.string :last_name
      t.string :first_name
      t.string :middle_initial
      t.string :suffix
      t.string :patient_identification_code_qualifier
      t.string :patient_account_number
      t.string :patient_medistreams_id
      t.string :address_one
      t.string :address_two
      t.string :zip_code
      t.string :city
      t.string :state
      t.string :insurance_policy_number
      t.string :patient_type
      t.string :subscriber_identification_code
      t.timestamps
    end
  end

  def down
    drop_table :patients
  end
end
