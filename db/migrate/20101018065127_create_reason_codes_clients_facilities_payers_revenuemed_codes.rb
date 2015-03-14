class CreateReasonCodesClientsFacilitiesPayersRevenuemedCodes < ActiveRecord::Migration
  def up
    create_table :reason_codes_clients_facilities_payers_revenuemed_codes do |t|
       t.column "reason_codes_clients_facilities_payer_id", :integer, :null => false
       t.column "revenuemed_code_id",  :integer, :null => false
       t.timestamps
    end
  end

  def down
    drop_table :reason_codes_clients_facilities_payers_revenuemed_codes
  end
end
