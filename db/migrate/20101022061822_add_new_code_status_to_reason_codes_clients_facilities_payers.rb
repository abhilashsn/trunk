class AddNewCodeStatusToReasonCodesClientsFacilitiesPayers < ActiveRecord::Migration
  def up
    add_column :reason_codes_clients_facilities_payers, :code_status, :string
  end

  def down
    remove_column :reason_codes_clients_facilities_payers, :code_status
  end
end
