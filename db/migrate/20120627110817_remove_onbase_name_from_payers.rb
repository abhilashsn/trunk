class RemoveOnbaseNameFromPayers < ActiveRecord::Migration
  def up
    remove_column :payers, :onbase_name
  end

  def down
    add_column :payers, :onbase_name, :string
  end
end
