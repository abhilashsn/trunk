class RenameCrosswalkTablesAndColumns < ActiveRecord::Migration
  def up
    rename_table :reason_codes_clients_facilities_payers, :reason_codes_clients_facilities_set_names
    rename_table :reason_codes_clients_facilities_payers_hipaa_codes, :reason_codes_clients_facilities_set_names_hipaa_codes
    rename_table :reason_codes_clients_facilities_payers_client_codes, :reason_codes_clients_facilities_set_names_client_codes
    
    rename_column :reason_codes_clients_facilities_set_names_hipaa_codes, :reason_codes_clients_facilities_payer_id, :reason_codes_clients_facilities_set_name_id
    rename_column :reason_codes_clients_facilities_set_names_client_codes, :reason_codes_clients_facilities_payer_id, :reason_codes_clients_facilities_set_name_id
  end

  def down
    rename_table :reason_codes_clients_facilities_payers, :reason_codes_clients_facilities_set_names
    rename_table :reason_codes_clients_facilities_payers_hipaa_codes, :reason_codes_clients_facilities_set_names_hipaa_codes
    rename_table :reason_codes_clients_facilities_payers_client_codes, :reason_codes_clients_facilities_set_names_client_codes
    
    rename_column :reason_codes_clients_facilities_set_names_hipaa_codes, :reason_codes_clients_facilities_payer_id, :reason_codes_clients_facilities_set_name_id
    rename_column :reason_codes_clients_facilities_set_names_client_codes, :reason_codes_clients_facilities_payer_id, :reason_codes_clients_facilities_set_name_id
  end
end
