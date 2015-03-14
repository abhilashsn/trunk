class AddBacSpecificFieldsToPayers < ActiveRecord::Migration
  def up
    add_column :payers, :status, :string, :limit => 25
    add_column :payers, :company_id, :string, :limit => 10
    add_column :payers, :gateway_temp, :string, :limit => 10
    add_column :payers, :remits_gateway, :string, :limit => 10
    add_column :payers, :parent_id, :integer, :limit => 11
    add_column :payers, :contact_information_id, :integer, :limit => 11
  end

  def down
    remove_column :payers, :status
    remove_column :payers, :company_id
    remove_column :payers, :gateway_temp
    remove_column :payers, :remits_gateway
    remove_column :payers, :parent_id
    remove_column :payers, :contact_information_id 
  end
end
