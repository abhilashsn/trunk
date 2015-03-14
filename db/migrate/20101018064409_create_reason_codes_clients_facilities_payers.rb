class CreateReasonCodesClientsFacilitiesPayers < ActiveRecord::Migration
  def up
    create_table :reason_codes_clients_facilities_payers do |t|
       t.column "reason_code_id", :integer
       t.column "client_id",  :integer
       t.column "facility_id",  :integer
       t.column "payer_id",  :integer
       t.timestamps
    end
  end

  def down
    drop_table :reason_codes_clients_facilities_payers
  end
end
