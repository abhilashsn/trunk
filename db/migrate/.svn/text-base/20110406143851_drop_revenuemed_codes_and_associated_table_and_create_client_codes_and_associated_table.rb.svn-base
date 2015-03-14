class DropRevenuemedCodesAndAssociatedTableAndCreateClientCodesAndAssociatedTable < ActiveRecord::Migration
  def up
    drop_table :reason_codes_clients_facilities_payers_revenuemed_codes
    execute "ALTER TABLE reason_codes  DROP FOREIGN KEY reason_codes_idfk_1"
    drop_table :revenuemed_codes
    create_table :client_codes do |t|
      t.column "group_code", :string
      t.column "adjustment_code",  :string
      t.column "adjustment_code_description",  :string
      t.timestamps
    end
    create_table :reason_codes_clients_facilities_payers_client_codes do |t|
      t.column "reason_codes_clients_facilities_payer_id", :integer, :null => false
      t.column "client_code_id",  :integer, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :reason_codes_clients_facilities_payers_client_codes
    drop_table :client_codes
    create_table :reason_codes_clients_facilities_payers_revenuemed_codes do |t|
      t.column "reason_codes_clients_facilities_payer_id", :integer, :null => false
      t.column "revenuemed_code_id",  :integer, :null => false
      t.timestamps
    end
    create_table :revenuemed_codes do |t|
      t.column "revenuemed_group_code", :string
      t.column "revenuemed_adjustment_code",  :string
      t.column "revenuemed_code_description",  :string
      t.timestamps
    end
    execute "ALTER TABLE reason_codes ADD CONSTRAINT reason_codes_idfk_1 FOREIGN KEY (revenuemed_code_id)
              REFERENCES revenuemed_codes(id)"
  end
end
