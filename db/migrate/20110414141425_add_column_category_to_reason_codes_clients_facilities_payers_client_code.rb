class AddColumnCategoryToReasonCodesClientsFacilitiesPayersClientCode < ActiveRecord::Migration
  def up
    add_column :reason_codes_clients_facilities_payers_client_codes, :category, :string, :limit => 20
  end

  def down
    remove_column :reason_codes_clients_facilities_payers_client_codes, :category
  end
end
