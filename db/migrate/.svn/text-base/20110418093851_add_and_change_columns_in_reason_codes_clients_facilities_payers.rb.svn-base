class AddAndChangeColumnsInReasonCodesClientsFacilitiesPayers < ActiveRecord::Migration
  def up
    add_column :reason_codes_clients_facilities_payers, :source, :string, :limit => 10
    change_column :reason_codes_clients_facilities_payers, :code_status, :string, :default => 'new'
  end

  def down
    remove_column :reason_codes_clients_facilities_payers, :source
    change_column :reason_codes_clients_facilities_payers, :code_status, :string, :default => nil
  end
end
