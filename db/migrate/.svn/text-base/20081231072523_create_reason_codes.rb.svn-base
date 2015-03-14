class CreateReasonCodes < ActiveRecord::Migration
  def up
    create_table :reason_codes do |t|
      t.column :reason_code, :string
      t.column :reason_code_description, :string
      t.column :check_number, :string
      t.column :revenuemed_code_id, :integer,:references=>:revenuemed_codes
      t.column :hipaa_code_id, :integer,:references=>:hipaa_codes
      t.column :payer_id, :integer,:references=>:payers
      t.column :facility_id, :integer,:references=>:facilities
      t.column :deleted_at,  :datetime
      t.timestamps
    end
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_1 FOREIGN KEY (revenuemed_code_id)
              REFERENCES revenuemed_codes(id)"
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_2 FOREIGN KEY (hipaa_code_id)
              REFERENCES hipaa_codes(id)"
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_3 FOREIGN KEY (payer_id)
              REFERENCES payers(id)"
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_4 FOREIGN KEY (facility_id)
              REFERENCES facilities(id)"
  end

  def down
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_1"
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_2"
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_3"
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_4"
    drop_table :reason_codes
  end
end
