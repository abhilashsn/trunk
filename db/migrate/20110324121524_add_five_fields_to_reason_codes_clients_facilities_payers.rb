class AddFiveFieldsToReasonCodesClientsFacilitiesPayers < ActiveRecord::Migration
  def up
    add_column :reason_codes_clients_facilities_payers, :claim_status_code, :string, :limit => 10
    add_column :reason_codes_clients_facilities_payers, :denied_claim_status_code, :string, :limit => 10
    add_column :reason_codes_clients_facilities_payers, :reporting_activity1, :string, :limit => 50
    add_column :reason_codes_clients_facilities_payers, :reporting_activity2, :string, :limit => 50 
    add_column :reason_codes_clients_facilities_payers, :active_indicator, :boolean
  end

  def down
    remove_column :reason_codes_clients_facilities_payers, :claim_status_code
    remove_column :reason_codes_clients_facilities_payers, :denied_claim_status_code
    remove_column :reason_codes_clients_facilities_payers, :reporting_activity1
    remove_column :reason_codes_clients_facilities_payers, :reporting_activity2
    remove_column :reason_codes_clients_facilities_payers, :active_indicator
  end
end
