class RemoveColumnsFromReasonCodes < ActiveRecord::Migration
  def up
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_2"
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_3"
    execute "ALTER TABLE reason_codes DROP FOREIGN KEY reason_codes_idfk_4"
    remove_column :reason_codes, :hipaa_code_id
    remove_column :reason_codes, :payer_id
    remove_column :reason_codes, :facility_id
    remove_column :reason_codes, :ansi_remark_code_id
    remove_column :reason_codes, :revenuemed_code_id
    remove_column :reason_codes, :payer_name
  end

  def down
    add_column :reason_codes, :hipaa_code_id
    add_column :reason_codes, :payer_id
    add_column :reason_codes, :facility_id
    add_column :reason_codes, :ansi_remark_code_id
    add_column :reason_codes, :payer_name
    add_column :reason_codes, :revenuemed_code_id
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_1 FOREIGN KEY (revenuemed_code_id)
              REFERENCES revenuemed_codes(id)"
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_2 FOREIGN KEY (hipaa_code_id)
              REFERENCES hipaa_codes(id)"
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_3 FOREIGN KEY (payer_id)
              REFERENCES payers(id)"
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_4 FOREIGN KEY (facility_id)
              REFERENCES facilities(id)"
  end
end
