class AddOnbaseNameToPayers < ActiveRecord::Migration
  def up
    add_column :payers, :onbase_name, :text
  end

  def down
    remove_column :payers, :onbase_name
  end
end
