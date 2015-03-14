class AddIndexToReasonCodesClientsFacilitiesSetNames < ActiveRecord::Migration
  def up
     add_index :reason_codes_clients_facilities_set_names, :reason_code_id, :name => "by_reason_code_id"
     add_index :reason_codes_clients_facilities_set_names, :client_id, :name => "by_client_id"
     add_index :reason_codes_clients_facilities_set_names, :facility_id, :name => "by_facility_id"
     add_index :reason_codes_clients_facilities_set_names, :reason_code_set_name_id, :name => "by_reason_code_set_id"
  end

  def down
    remove_index :reason_codes_clients_facilities_set_names, :reason_code_id
    remove_index :reason_codes_clients_facilities_set_names, :client_id
    remove_index :reason_codes_clients_facilities_set_names, :facility_id
    remove_index :reason_codes_clients_facilities_set_names, :reason_code_set_name_id
  end
end
