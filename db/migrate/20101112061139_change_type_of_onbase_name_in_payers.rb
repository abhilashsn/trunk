class ChangeTypeOfOnbaseNameInPayers < ActiveRecord::Migration
  def up
    change_column :payers, :onbase_name ,:string
  end

  def down
    change_column :payers, :onbase_name ,:text
  end
end
