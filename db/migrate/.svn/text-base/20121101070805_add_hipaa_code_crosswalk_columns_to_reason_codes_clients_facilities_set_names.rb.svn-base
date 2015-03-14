class AddHipaaCodeCrosswalkColumnsToReasonCodesClientsFacilitiesSetNames < ActiveRecord::Migration
  def change
    add_column :reason_codes_clients_facilities_set_names, :hipaa_code_id, :integer
    add_column :reason_codes_clients_facilities_set_names, :denied_hipaa_code_id, :integer
    add_column :reason_codes_clients_facilities_set_names, :hipaa_group_code, :string, :limit => 10
    add_column :reason_codes_clients_facilities_set_names, :denied_hipaa_group_code, :string, :limit => 10

    add_index :reason_codes_clients_facilities_set_names, :hipaa_code_id, :name => "index_hipaa_code_id"
    add_index :reason_codes_clients_facilities_set_names, :denied_hipaa_code_id, :name => "index_denied_hipaa_code_id"
  end
end
