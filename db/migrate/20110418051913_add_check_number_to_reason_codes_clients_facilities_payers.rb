class AddCheckNumberToReasonCodesClientsFacilitiesPayers < ActiveRecord::Migration
  def up
    add_column :reason_codes_clients_facilities_payers, :check_number, :string, :limit => 30
  end

  def down
    remove_column :reason_codes_clients_facilities_payers, :check_number
  end
end
