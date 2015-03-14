class RemoveDeprecatedColumnsFromReasonCodeClientsFacilitesSetNames < ActiveRecord::Migration
  def up
    remove_column :reason_codes_clients_facilities_set_names, :payer_id
    remove_column :reason_codes_clients_facilities_set_names, :code_status
    remove_column :reason_codes_clients_facilities_set_names, :check_number
    remove_column :reason_codes_clients_facilities_set_names, :source
  end

  def down
    add_column  :reason_codes_clients_facilities_set_names, :payer_id, :integer
    add_column  :reason_codes_clients_facilities_set_names, :code_status, :string, :limit => 255
    add_column  :reason_codes_clients_facilities_set_names, :check_nubmer, :string, :limit =>30
    add_column  :reason_codes_clients_facilities_set_names, :source, :string, :limit=>10
  end
end
