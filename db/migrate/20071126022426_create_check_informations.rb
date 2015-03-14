class CreateCheckInformations < ActiveRecord::Migration
  def up
    create_table :check_informations do |t|
      t.column :job_id, :integer,:references=>:jobs
      t.column :payer_id, :integer,:references=>:payers
      t.column :check_date, :date
      t.column :check_number, :string ,:limit =>30
      t.column :check_amount,:decimal,:precision => 10, :scale => 2
      t.column :payer_name, :string ,:limit =>30
      t.column :payer_city, :string ,:limit =>30
      t.column :payer_state_code, :string ,:limit =>3
      t.column :payer_zip, :string ,:limit =>12
      t.column :payer_address_line1, :string ,:limit =>40
      t.column :payer_address_line2, :string ,:limit =>40
      t.column :payer_tin, :string ,:limit =>20
      t.column :payee_tin, :string ,:limit =>12
      t.column :payee_name, :string ,:limit =>35
      t.column :payee_city, :string ,:limit =>35
      t.column :payee_state_code, :string ,:limit =>3
      t.column :payee_zip, :string ,:limit =>11
      t.column :payee_address_line1, :string ,:limit =>40
      t.column :payee_address_line2, :string ,:limit =>40
      t.column :payee_reference_identification, :string ,:limit =>20
      t.column :payee_identification_number, :string ,:limit =>20
      t.column :payee_npi_number, :string ,:limit =>20
      t.column :created_at,:datetime
      t.column :updated_at,:datetime
      t.column :deleted_at,  :datetime
      t.column :details, :text
    end
    execute "ALTER TABLE check_informations ADD CONSTRAINT check_informations_idfk_1 FOREIGN KEY (job_id)
              REFERENCES jobs(id)"
    execute "ALTER TABLE check_informations ADD CONSTRAINT check_informations_idfk_2 FOREIGN KEY (payer_id)
              REFERENCES payers(id)"
  end

  def down
    execute "ALTER TABLE check_informations DROP FOREIGN KEY check_informations_idfk_1"
    execute "ALTER TABLE check_informations DROP FOREIGN KEY check_informations_idfk_1"
    drop_table :check_informations
  end
end
