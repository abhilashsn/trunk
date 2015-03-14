class FacilitySpecificPayees < ActiveRecord::Migration
  def up
    create_table :facility_specific_payees do |t|
      t.column "facility_id", :integer, :null => false
      t.column "client_id", :integer, :null => false
      t.column "db_identifier",:string
      t.column "xpeditor_client_code",:string, :null => false
      t.column "payee_name",:string, :null => false
      t.column "payer_type",:string
      t.column "match_criteria",:string
      t.timestamps
    end
  end

  def down
    drop_table :facility_specific_payees
  end
end
