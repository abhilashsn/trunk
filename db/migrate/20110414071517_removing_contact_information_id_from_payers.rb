class RemovingContactInformationIdFromPayers < ActiveRecord::Migration
  def up
    remove_column :payers, :contact_information_id
  end

  def down
    add_column :payers, :contact_information_id, :integer, :limit => 11
  end
end
